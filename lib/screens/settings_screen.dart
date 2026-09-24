import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import './providers/settings_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:boviframe/widgets/custom_bottom_nav_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedProfession = '';
  final List<String> _professions = [
    'Veterinario',
    'Zootecnista',
    'AgrÃ³nomo',
    'Otro',
  ];

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final doc =
          await LocalFirestore.instance
              .collection('usuarios')
              .doc(currentUser.uid)
              .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        final nombre = data['nombre'] ?? '';
        final colegio = data['colegio'] ?? '';
        final ubicacion = data['ubicacion'] ?? '';
        final profesion = data['profesion'];
        if (profesion != null && _professions.contains(profesion)) {
          _selectedProfession = profesion;
        } else {
          _selectedProfession = _professions.first;
        }
        final email = _user?.email ?? '';

        setState(() {
          _nameController.text = nombre;
          _collegeController.text = colegio;
          _locationController.text = ubicacion;
          _selectedProfession = profesion;
        });

        context.read<SettingsProvider>().setUserData(
          name: nombre,
          email: email,
          company: ubicacion,
        );
      }
    } catch (e) {
      debugPrint('âŒ Error al cargar datos: $e');
    }
  }

  Future<void> _saveSettings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final newName = _nameController.text.trim();
    final newCole = _collegeController.text.trim();
    final newUbic = _locationController.text.trim();

    if (newName.isEmpty || newCole.isEmpty || newUbic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, completa todos los campos antes de guardar.',
          ),
        ),
      );
      return;
    }

    try {
      final newProf = _selectedProfession;
      final newEmail = _user?.email ?? '';

      await LocalFirestore.instance
          .collection('usuarios')
          .doc(currentUser.uid)
          .set({
            'nombre': newName,
            'colegio': newCole,
            'ubicacion': newUbic,
            'profesion': newProf,
          }, SetOptions(merge: true));

      context.read<SettingsProvider>().setUserData(
        name: newName,
        email: newEmail,
        company: newUbic,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ConfiguraciÃ³n guardada exitosamente')),
        );
      }
    } catch (e, st) {
      debugPrint('âŒ Error al guardar configuraciÃ³n: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar configuraciÃ³n:\n$e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 24,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Â¿Eliminar cuenta?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Esta acciÃ³n eliminarÃ¡ tu cuenta y todos tus datos de forma permanente.\n\nÂ¿EstÃ¡s completamente seguro?',
                    style: TextStyle(fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Eliminar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirm != true) return;

    try {
      await LocalFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .delete();

      try {
        await user.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuenta eliminada exitosamente')),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          if (user.providerData.any((p) => p.providerId == 'google.com')) {
            await _reauthenticateWithGoogleAndDelete(user);
          } else {
            _showReauthDialog(); // solo si fue creado con email/contraseÃ±a
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar cuenta: ${e.message}')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar datos del usuario: $e')),
      );
    }
  }

  void _showReauthDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('ReautenticaciÃ³n requerida'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Por seguridad, ingresa tu contraseÃ±a nuevamente.'),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'ContraseÃ±a'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final user = FirebaseAuth.instance.currentUser;
                  final email = user?.email;
                  final password = passwordController.text.trim();

                  if (email != null && password.isNotEmpty) {
                    try {
                      final cred = EmailAuthProvider.credential(
                        email: email,
                        password: password,
                      );
                      await user!.reauthenticateWithCredential(cred);
                      await user.delete();

                      if (mounted) {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (_) => false,
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Error al reautenticar o eliminar la cuenta.',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Confirmar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _reauthenticateWithGoogleAndDelete(User user) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await user.reauthenticateWithCredential(credential);
      await user.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta eliminada exitosamente')),
        );
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reautenticar con Google: $e')),
      );
    }
  }

  Future<void> _showAboutDialog() async {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/logo1.png',
                      width: 60,
                      height: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'TÃ©cnica EPMURAS',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 28),
                    _buildBenefitTile(
                      Icons.timer_outlined,
                      'OptimizaciÃ³n del tiempo',
                      'Reduce la duraciÃ³n de las consultas manteniendo la calidad.',
                    ),
                    _buildBenefitTile(
                      Icons.track_changes_outlined,
                      'DiagnÃ³sticos precisos',
                      'Aumenta la certeza en la identificaciÃ³n de patologÃ­as.',
                    ),
                    _buildBenefitTile(
                      Icons.groups_outlined,
                      'Mejora la comunicaciÃ³n',
                      'Facilita la explicaciÃ³n de casos complejos al cliente.',
                    ),
                    _buildBenefitTile(
                      Icons.checklist_rtl_outlined,
                      'Protocolos estandarizados',
                      'Ofrece una guÃ­a clara para un abordaje consistente.',
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text(
                      'Creado por Medico Veterinario GualdrÃ³n Williams',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Text(
                      'VersiÃ³n: 1.0.1',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text(
                        'Cerrar',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildBenefitTile(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _styledInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        title: const Text(
          'ConfiguraciÃ³n',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: _styledInputDecoration('Nombre y Apellido'),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value:
                            _professions.contains(_selectedProfession)
                                ? _selectedProfession
                                : null,
                        items:
                            _professions.map((p) {
                              return DropdownMenuItem(value: p, child: Text(p));
                            }).toList(),
                        onChanged: (v) {
                          if (v != null)
                            setState(() => _selectedProfession = v);
                        },
                        decoration: _styledInputDecoration('ProfesiÃ³n'),
                      ),

                      const SizedBox(height: 12),
                      TextField(
                        controller: _collegeController,
                        decoration: _styledInputDecoration('NÃºmero de Colegio'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationController,
                        decoration: _styledInputDecoration(
                          'UbicaciÃ³n, Estado, PaÃ­s',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _user?.email ?? '',
                        readOnly: true,
                        decoration: _styledInputDecoration('Email'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Cambios'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: const TextStyle(fontSize: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                          ),
                          title: const Text('Acerca de BOVIFrame'),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                          onTap: _showAboutDialog,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.logout, color: Colors.red),
                          title: const Text('Cerrar sesiÃ³n'),
                          onTap: () async {
                            if (!mounted) return;
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              '/login',
                              (_) => false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        child: ListTile(
                          leading: Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          title: Text('Eliminar cuenta'),
                          onTap: _deleteAccount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 4),
    );
  }
}



