import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

// IMPORTS PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../providers/session_provider.dart';
import '../../widgets/custom_bottom_nav_bar.dart';
import '../../services/offline_session_service.dart';
import '../../services/connectivity_service.dart';

class AnimalEvaluationScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;
  final bool isEditing;

  const AnimalEvaluationScreen({super.key})
      : docId = null,
        initialData = null,
        isEditing = false;

  const AnimalEvaluationScreen.edit({
    super.key,
    required this.docId,
    required this.initialData,
  })  : isEditing = true;

  @override
  State<AnimalEvaluationScreen> createState() => _AnimalEvaluationScreenState();
}

class _AnimalEvaluationScreenState extends State<AnimalEvaluationScreen> {
  // Controllers
  final _numeroController = TextEditingController();
  final _registroController = TextEditingController();
  final _pesoNacController = TextEditingController();
  final _pesoDestController = TextEditingController();
  final _pesoAjusController = TextEditingController();
  final _edadDiasController = TextEditingController();
  final _fechaNacController = TextEditingController();
  final _fechaDestController = TextEditingController();
  final _comentarioController = TextEditingController();

  // Dropdowns / Toggles
  String? _selectedSexo;
  String? _selectedEstadoAnimal;

  // Vector overlays flag for Guía Visual Morfométrica
  bool _showVectores = true;

  // Trait Details metadata
  final Map<String, Map<String, dynamic>> _traitDetails = const {
    'E': {'name': 'Estructura', 'max': 6},
    'P': {'name': 'Precocidad', 'max': 6},
    'M': {'name': 'Musculatura', 'max': 6},
    'U': {'name': 'Umbigo', 'max': 6},
    'R': {'name': 'Racial', 'max': 6},
    'A': {'name': 'Aplomos', 'max': 6},
    'S': {'name': 'Sexualidad', 'max': 6},
  };

  // EPMURAS Map
  final Map<String, String?> _epmuras = {
    'E': null,
    'P': null,
    'M': null,
    'U': null,
    'R': null,
    'A': null,
    'S': null,
  };

  Uint8List? _imageBytes;
  String? _sessionId;
  bool _hasChanged = false;
  bool _loading = true;

  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _producerData;
  List<Map<String, dynamic>> _sessionEvaluations = [];

  @override
  void initState() {
    super.initState();

    // Default values if creating new (all fields empty)
    _numeroController.text = '';
    _registroController.text = '';
    _fechaNacController.text = '';
    _fechaDestController.text = '';
    _pesoNacController.text = '';
    _pesoDestController.text = '';
    _pesoAjusController.text = '';
    _edadDiasController.text = '';
    _comentarioController.text = '';

    // Populate data if editing
    if (widget.isEditing && widget.initialData != null) {
      final data = widget.initialData!;
      _numeroController.text = data['numero']?.toString() ?? '';
      _registroController.text = data['registro']?.toString() ?? '';
      _selectedSexo = data['sexo']?.toString() ?? 'Macho';
      _selectedEstadoAnimal = data['estado']?.toString() ?? 'Desarrollo';
      _fechaNacController.text = data['fecha_nac']?.toString() ?? '';
      _fechaDestController.text = data['fecha_dest']?.toString() ?? '';
      _pesoNacController.text = data['peso_nac']?.toString() ?? '';
      _pesoDestController.text = data['peso_dest']?.toString() ?? '';
      _pesoAjusController.text = data['peso_ajus']?.toString() ?? '';
      _edadDiasController.text = data['edad_dias']?.toString() ?? '';
      _comentarioController.text = data['comentario']?.toString() ?? '';

      final epm = (data['epmuras'] as Map<String, dynamic>? ?? {});
      epm.forEach((key, value) {
        if (_epmuras.containsKey(key)) {
          _epmuras[key] = value?.toString();
        }
      });

      if (data['image_base64'] != null) {
        try {
          _imageBytes = base64Decode(data['image_base64'] as String);
        } catch (_) {
          _imageBytes = null;
        }
      }
      _calcularEdadYPesoAjustado();
    }

    // Change listeners
    _numeroController.addListener(_markChanged);
    _registroController.addListener(_markChanged);
    _pesoNacController.addListener(_markChanged);
    _pesoDestController.addListener(_markChanged);
    _pesoAjusController.addListener(_markChanged);
    _edadDiasController.addListener(_markChanged);
    _fechaNacController.addListener(_markChanged);
    _fechaDestController.addListener(_markChanged);

    _pesoNacController.addListener(_calcularEdadYPesoAjustado);
    _pesoDestController.addListener(_calcularEdadYPesoAjustado);
    _fechaNacController.addListener(_calcularEdadYPesoAjustado);
    _fechaDestController.addListener(_calcularEdadYPesoAjustado);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<SessionProvider>(
        context,
        listen: false,
      ).registerResetEvaluationForm(_resetForm);
    });

    _loadAllData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args['sessionId'] != null) {
      _sessionId = args['sessionId'] as String;
      Provider.of<SessionProvider>(context, listen: false).sessionId =
          _sessionId!;
    } else {
      _sessionId =
          Provider.of<SessionProvider>(context, listen: false).sessionId;
    }

    if (widget.isEditing &&
        widget.initialData != null &&
        widget.initialData!['session_id'] != null) {
      _sessionId = widget.initialData!['session_id'].toString();
      Provider.of<SessionProvider>(context, listen: false).sessionId =
          _sessionId!;
    }
  }

  @override
  void dispose() {
    _numeroController.dispose();
    _registroController.dispose();
    _pesoNacController.dispose();
    _pesoDestController.dispose();
    _pesoAjusController.dispose();
    _comentarioController.dispose();
    _edadDiasController.dispose();
    _fechaNacController.dispose();
    _fechaDestController.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanged) setState(() => _hasChanged = true);
  }

  void _resetForm() {
    _comentarioController.clear();
    _numeroController.clear();
    _registroController.clear();
    _pesoNacController.clear();
    _pesoDestController.clear();
    _pesoAjusController.clear();
    _edadDiasController.clear();
    _fechaNacController.clear();
    _fechaDestController.clear();
    setState(() {
      _selectedSexo = 'Macho';
      _selectedEstadoAnimal = 'Desarrollo';
      _epmuras.updateAll((k, _) => null);
      _imageBytes = null;
      _hasChanged = false;
    });
    Provider.of<SessionProvider>(context, listen: false).clearAll();
  }

  DateTime? _parseFecha(String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return null;
    final parts = cleaned.split('/');
    if (parts.length == 3) {
      final d = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(parts[2]);
      if (d != null && m != null && y != null) {
        return DateTime(y, m, d);
      }
    }
    try {
      return DateFormat('d/M/y').parseStrict(cleaned);
    } catch (_) {
      try {
        return DateFormat('dd/MM/yyyy').parseStrict(cleaned);
      } catch (_) {
        try {
          return DateTime.parse(cleaned);
        } catch (_) {
          return null;
        }
      }
    }
  }

  void _calcularEdadYPesoAjustado() {
    final fn = _parseFecha(_fechaNacController.text);
    final fd = _parseFecha(_fechaDestController.text);

    // 1. Calcular Edad Actual en días según Fecha de Nacimiento
    if (fn != null) {
      final hoy = DateTime.now();
      final edadActualDias = hoy.difference(fn).inDays;
      if (edadActualDias >= 0) {
        _edadDiasController.text = '$edadActualDias';
      }
    } else {
      _edadDiasController.text = '';
    }

    // 2. Calcular Peso Ajustado según la fórmula:
    // Pajustado = (((Peso destete - Peso nacer) / (Fecha Destete - Fecha Nacer)) * 205) + Peso al nacer
    final pesoNac = double.tryParse(_pesoNacController.text.replaceAll(',', '.'));
    final pesoDest = double.tryParse(_pesoDestController.text.replaceAll(',', '.'));

    if (pesoNac != null && pesoDest != null && fn != null && fd != null) {
      final diasDestete = fd.difference(fn).inDays;
      if (diasDestete > 0) {
        final pAjus = (((pesoDest - pesoNac) / diasDestete) * 205) + pesoNac;
        _pesoAjusController.text = pAjus.toStringAsFixed(1);
      } else {
        _pesoAjusController.text = '';
      }
    } else {
      _pesoAjusController.text = '';
    }
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', ''),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0F3B27),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.text = '${picked.day}/${picked.month}/${picked.year}';
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF0F3B27)),
            title: const Text('Tomar foto'),
            onTap: () async {
              Navigator.pop(ctx);
              await _handleImagePick(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF0F3B27)),
            title: const Text('Seleccionar de galería'),
            onTap: () async {
              Navigator.pop(ctx);
              await _handleImagePick(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleImagePick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked == null) return;

      final original = await picked.readAsBytes();
      final compressed = await FlutterImageCompress.compressWithList(
        original,
        minWidth: 600,
        quality: 70,
      );

      const maxSize = 1048576;
      if (compressed.length > maxSize) {
        if (!mounted) return;
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Imagen demasiado grande'),
            content: const Text(
              'La imagen comprimida ocupa más de 1 MB. Por favor recórtala o reduce su tamaño.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _imageBytes = compressed;
        _hasChanged = true;
      });
    } catch (e) {
      debugPrint('Error al procesar imagen: $e');
    }
  }

  Future<void> _loadAllData() async {
    if (_sessionId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final sessionSnap = await LocalFirestore.instance
          .collection('sesiones')
          .doc(_sessionId)
          .get();
      _sessionData = sessionSnap.data();

      final prodQuery = await LocalFirestore.instance
          .collection('sesiones')
          .doc(_sessionId)
          .collection('datos_productor')
          .limit(1)
          .get();

      if (prodQuery.docs.isNotEmpty) {
        _producerData = prodQuery.docs.first.data();
      }

      final evalsSnap = await LocalFirestore.instance
          .collection('sesiones')
          .doc(_sessionId)
          .collection('evaluaciones_animales')
          .orderBy('timestamp', descending: false)
          .get();

      _sessionEvaluations = evalsSnap.docs.map((d) {
        final m = d.data();
        m['evalId'] = d.id;
        return m;
      }).toList();
    } catch (e) {
      debugPrint('Error cargando datos de sesión: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<String?> _guardarEvaluacionEnFirestore() async {
    if (_sessionId == null || _sessionId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: sessionId no disponible.'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }

    final sessionProv = Provider.of<SessionProvider>(context, listen: false);
    sessionProv.setDatosAnimal(
      numero: _numeroController.text,
      registro: _registroController.text,
      sexo: _selectedSexo,
      estadoAnimal: _selectedEstadoAnimal,
      fechaNac: _fechaNacController.text,
      fechaDest: _fechaDestController.text,
      pesoNac: _pesoNacController.text,
      pesoDest: _pesoDestController.text,
      pesoAjus: _pesoAjusController.text,
      edadDias: _edadDiasController.text,
    );
    sessionProv.setEpmuras(_epmuras);
    sessionProv.setImage(_imageBytes);

    final data = <String, dynamic>{
      'usuarioId': FirebaseAuth.instance.currentUser!.uid,
      'numero': _numeroController.text,
      'registro': _registroController.text,
      'sexo': _selectedSexo,
      'estado': _selectedEstadoAnimal,
      'fecha_nac': _fechaNacController.text,
      'fecha_dest': _fechaDestController.text,
      'peso_nac': _pesoNacController.text,
      'peso_dest': _pesoDestController.text,
      'peso_ajus': _pesoAjusController.text,
      'edad_dias': _edadDiasController.text,
      'comentario': _comentarioController.text,
      'epmuras': sessionProv.epmuras,
      'image_base64': sessionProv.imageBytes != null
          ? base64Encode(sessionProv.imageBytes!)
          : null,
      'datos_productor': sessionProv.datosProductor,
      'timestamp': Timestamp.now(),
      'session_id': _sessionId,
    };

    try {
      final hasInternet =
          await ConnectivityService.hasRealInternetConnection();

      if (!hasInternet) {
        final offlineId = await OfflineSessionService.saveEvaluationOffline(
          evaluationData: data,
          sessionId: _sessionId ?? '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '📱 Guardado offline. Se sincronizará cuando haya internet.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        _hasChanged = false;
        return offlineId;
      }

      if (widget.isEditing && widget.docId != null) {
        await LocalFirestore.instance
            .collection('sesiones')
            .doc(_sessionId)
            .collection('evaluaciones_animales')
            .doc(widget.docId)
            .update(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Evaluación actualizada correctamente'),
              backgroundColor: Color(0xFF0F3B27),
            ),
          );
        }
        return widget.docId;
      } else {
        final docRef = await LocalFirestore.instance
            .collection('sesiones')
            .doc(_sessionId)
            .collection('evaluaciones_animales')
            .add(data);

        _hasChanged = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Evaluación guardada correctamente'),
              backgroundColor: Color(0xFF0F3B27),
            ),
          );
        }
        return docRef.id;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _guardarYVolver() async {
    final docId = await _guardarEvaluacionEnFirestore();
    if (docId == null) return;
    _resetForm();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/new_session',
      arguments: {'sessionId': _sessionId!},
    );
  }

  Future<void> _guardarYNuevo() async {
    final docId = await _guardarEvaluacionEnFirestore();
    if (docId == null) return;
    _resetForm();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AnimalEvaluationScreen(),
        settings: RouteSettings(arguments: {'sessionId': _sessionId}),
      ),
    );
  }

  Future<void> _actualizarEvaluacionExistente() async {
    final docId = await _guardarEvaluacionEnFirestore();
    if (docId != null) {
      _resetForm();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/epmuras');
    }
  }

  Future<void> _cancelarEvaluacion() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      '/new_session',
      arguments: {'sessionId': _sessionId!},
    );
  }

  Future<void> _confirmCancelar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Salida'),
        content: const Text(
          '¿Deseas salir sin guardar? No se eliminará ningún registro en la base de datos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir Editando'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _cancelarEvaluacion();
    }
  }

  Future<List<Map<String, dynamic>>> _cargarTodasLasEvaluaciones() async {
    final firestore = LocalFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final sesionesSnapshot = await firestore
        .collection('sesiones')
        .orderBy('fecha_creacion', descending: true)
        .get();

    final List<Map<String, dynamic>> acumulado = [];

    for (final sesionDoc in sesionesSnapshot.docs) {
      final sessionId = sesionDoc.id;
      final evalsSnapshot = await firestore
          .collection('sesiones')
          .doc(sessionId)
          .collection('evaluaciones_animales')
          .where('usuarioId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      for (final evalDoc in evalsSnapshot.docs) {
        final mapaEval = evalDoc.data();
        mapaEval['evalId'] = evalDoc.id;
        mapaEval['sessionId'] = sessionId;
        acumulado.add(mapaEval);
      }
    }

    return acumulado;
  }

  void _mostrarConteosDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String searchQuery = '';
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _cargarTodasLasEvaluaciones(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error al leer Firestore'),
                content: Text('${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              );
            }

            final todasLasEval = snapshot.data!;
            return StatefulBuilder(
              builder: (context, setStateSB) {
                final filtered = todasLasEval.where((m) {
                  final numero = (m['numero'] ?? '').toString().toLowerCase();
                  final registro =
                      (m['registro'] ?? '').toString().toLowerCase();
                  final q = searchQuery.toLowerCase();
                  return numero.contains(q) || registro.contains(q);
                }).toList();

                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Sesiones y Evaluaciones'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total evaluaciones: ${todasLasEval.length}'),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Buscar por número o registro',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setStateSB(() => searchQuery = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: filtered.isEmpty
                              ? const Center(
                                  child: Text('No se encontraron resultados'),
                                )
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, idx) {
                                    final m = filtered[idx];
                                    return ListTile(
                                      title: Text(
                                        'N° ${m['numero'] ?? '—'} · RGN ${m['registro'] ?? '—'}',
                                      ),
                                      subtitle: Text(
                                        'Nac.: ${m['fecha_nac'] ?? '—'} · Peso: ${m['peso_nac'] ?? '—'}',
                                      ),
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                AnimalEvaluationScreen.edit(
                                              docId: m['evalId'],
                                              initialData: m,
                                            ),
                                            settings: RouteSettings(
                                              arguments: {
                                                'sessionId': m['sessionId'],
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  double get _promedioEpmuras {
    int count = 0;
    double sum = 0;
    _epmuras.forEach((key, val) {
      if (val != null) {
        final d = double.tryParse(val);
        if (d != null) {
          sum += d;
          count++;
        }
      }
    });
    if (count == 0) return 0.0;
    return sum / count;
  }

  int get _criteriosCalificadosCount {
    return _epmuras.values.where((v) => v != null && v.isNotEmpty).length;
  }

  void _openEpmurasSelector(String letra) {
    final details = _traitDetails[letra] ?? {'name': letra, 'max': 6};
    final maxScore = details['max'] as int;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0F3B27),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letra,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Calificar ${details['name']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3B27),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Seleccione un valor entre 1 (Mínimo) y $maxScore (Óptimo)',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(maxScore, (i) {
                  final scoreStr = '${i + 1}';
                  final isSelected = _epmuras[letra] == scoreStr;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _epmuras[letra] = scoreStr;
                        _markChanged();
                      });
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF0F3B27)
                            : const Color(0xFFE8F3EC),
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF0F3B27).withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        scoreStr,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF0F3B27),
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _printOrSharePDF(Map<String, dynamic> m) async {
    try {
      final numero = (m['numero'] ?? '').toString();
      final registro = (m['registro'] ?? '').toString();
      final sexo = (m['sexo'] ?? '').toString();
      final estado = (m['estado'] ?? '').toString();
      final fechaNac = (m['fecha_nac'] ?? '').toString();
      final fechaDest = (m['fecha_dest'] ?? '').toString();
      final pesoNac = (m['peso_nac'] ?? '').toString();
      final pesoDest = (m['peso_dest'] ?? '').toString();
      final pesoAjus = (m['peso_ajus'] ?? '').toString();
      final edadDias = (m['edad_dias'] ?? '').toString();

      final rawEpm = (m['epmuras'] as Map<String, dynamic>? ?? {});
      final epmurasForPDF = <String, String>{};
      rawEpm.forEach((k, v) {
        epmurasForPDF[k] = v?.toString() ?? '0';
      });

      final imageBase64 = m['image_base64'] as String?;

      String userName = 'Nombre no disponible';
      String userEmail = 'E-mail no disponible';
      String userProf = 'Profesión no disponible';
      String userLoc = 'Ubicación no disponible';

      try {
        final currentSessionId = (m['sessionId'] ?? '') as String;
        if (currentSessionId.isNotEmpty) {
          final sessionSnap = await LocalFirestore.instance
              .collection('sesiones')
              .doc(currentSessionId)
              .get();
          final sessionData = sessionSnap.data();
          final usuarioId = sessionData['userId'] as String?;
          if (usuarioId != null && usuarioId.isNotEmpty) {
            final userSnap = await LocalFirestore.instance
                .collection('usuarios')
                .doc(usuarioId)
                .get();
            final udata = userSnap.data();
            userName = udata['nombre'] as String? ?? userName;
            userEmail = udata['email'] as String? ?? userEmail;
            userProf = udata['profesion'] as String? ?? userProf;
            userLoc = udata['ubicacion'] as String? ?? userLoc;
          }
        }
      } catch (e) {
        debugPrint('[PDF] Error cargando usuario: $e');
      }

      final Uint8List logoBytes = (await rootBundle.load(
        'assets/icons/logoapp2.png',
      )).buffer.asUint8List();

      Uint8List? fotoBytes;
      if (imageBase64 != null) {
        try {
          fotoBytes = base64Decode(imageBase64);
        } catch (_) {
          fotoBytes = null;
        }
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: 120,
                  height: 40,
                ),
              ),
              pw.Divider(color: PdfColors.green900, thickness: 2),
              pw.SizedBox(height: 8),
              pw.Text('Evaluador: $userName', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Email: $userEmail', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Profesión: $userProf', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Ubicación: $userLoc', style: const pw.TextStyle(fontSize: 12)),
              if (_producerData != null && _producerData!.isNotEmpty) ...[
                pw.Divider(color: PdfColors.grey),
                pw.Text('Productor: ${_producerData!['unidad_produccion'] ?? ''}', style: const pw.TextStyle(fontSize: 11)),
              ],
              pw.Divider(color: PdfColors.grey),
              pw.SizedBox(height: 8),
              pw.Text(
                'Datos del Animal: N° $numero | RGN $registro | Sexo: $sexo | Estado: $estado',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'F. Nac: $fechaNac | F. Dest: $fechaDest | P. Nac: $pesoNac kg | P. Dest: $pesoDest kg | P. Ajus: $pesoAjus kg | Edad: $edadDias días',
                style: const pw.TextStyle(fontSize: 11),
              ),
              pw.SizedBox(height: 12),
              if (fotoBytes != null)
                pw.Center(
                  child: pw.Image(
                    pw.MemoryImage(fotoBytes),
                    width: 250,
                    height: 180,
                    fit: pw.BoxFit.cover,
                  ),
                ),
              pw.SizedBox(height: 16),
              pw.Header(level: 1, text: 'Evaluación EPMURAS'),
              pw.Table.fromTextArray(
                headers: ['Característica', 'Calificación (1-6)'],
                data: epmurasForPDF.entries
                    .map((e) => [e.key, e.value])
                    .toList(),
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
              ),
              pw.SizedBox(height: 16),
              if (_comentarioController.text.isNotEmpty)
                pw.Text(
                  'Observación Técnica: ${_comentarioController.text}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
            ];
          },
        ),
      );

      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'evaluacion_animal_$numero.pdf',
      );
    } catch (e) {
      debugPrint('[PDF] Error generando PDF: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF3F8F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F3B27)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLoteHeader(),
                    const SizedBox(height: 16),
                    _buildIdentificationSection(),
                    const SizedBox(height: 16),
                    _buildGuiaVisualSection(),
                    const SizedBox(height: 16),
                    _buildEpmurasSection(),
                    const SizedBox(height: 16),
                    _buildEliteSummaryCard(),
                    const SizedBox(height: 16),
                    _buildObservacionTecnicaSection(),
                    const SizedBox(height: 20),
                    _buildBottomActions(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  // 1. Top Bar Navigation
  Widget _buildTopHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F3B27)),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                const Text(
                  'Eval...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F3B27),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3EAD5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'En Brete • Manga 02',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F3B27),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu_book_outlined,
                    size: 20, color: Color(0xFF0F3B27)),
                onPressed: _mostrarConteosDialog,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                icon: const Icon(Icons.bolt, size: 20, color: Color(0xFF0F3B27)),
                onPressed: () {},
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              IconButton(
                icon: const Icon(Icons.cloud_outlined,
                    size: 20, color: Color(0xFF0F3B27)),
                onPressed: () {},
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(6),
              ),
              const SizedBox(width: 4),
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF0F3B27),
                child: Icon(Icons.person_outline, size: 16, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Lote Banner & Animal Carousel Selector
  Widget _buildLoteHeader() {
    final sessionTitle = _producerData?['nombre_lote'] as String? ??
        _sessionData?['nombre_lote'] as String? ??
        _sessionData?['nombre_sesion'] as String? ??
        'Lote Toros Reproductores 2024';

    final totalReg = _sessionEvaluations.length;
    int currentIdx = widget.isEditing ? 1 : totalReg + 1;
    if (widget.isEditing && widget.docId != null) {
      final found = _sessionEvaluations.indexWhere((e) => e['evalId'] == widget.docId);
      if (found != -1) {
        currentIdx = found + 1;
      }
    }
    final totalDisplay = widget.isEditing ? (totalReg == 0 ? 1 : totalReg) : totalReg + 1;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F3B27),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sessionTitle,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3B27),
                      ),
                    ),
                    const SizedBox(height: 2),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        children: [
                          TextSpan(
                            text: 'Animal $currentIdx de $totalDisplay ',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F3B27),
                            ),
                          ),
                          const TextSpan(text: 'en Brete • Manga 02'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.article_outlined,
                    color: Colors.grey, size: 20),
                onPressed: _mostrarConteosDialog,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalDisplay > 0 ? (currentIdx / totalDisplay).clamp(0.0, 1.0) : 1.0,
              backgroundColor: const Color(0xFFE8F3EC),
              color: const Color(0xFF0F3B27),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_left,
                    size: 20, color: Color(0xFF0F3B27)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._sessionEvaluations.map((item) {
                        final numStr = item['numero']?.toString() ?? '—';
                        final isEditingThis = widget.isEditing && item['evalId'] == widget.docId;
                        return _buildAnimalChip(
                          isEditingThis ? '• #$numStr' : '✔ #$numStr',
                          isActive: isEditingThis,
                          isChecked: !isEditingThis,
                          onTap: () {
                            if (!isEditingThis) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnimalEvaluationScreen.edit(
                                    docId: item['evalId'],
                                    initialData: item,
                                  ),
                                  settings: RouteSettings(
                                    arguments: {'sessionId': item['sessionId'] ?? _sessionId},
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      }),
                      if (!widget.isEditing)
                        _buildAnimalChip(
                          '• #${_numeroController.text.trim().isEmpty ? 'nuevo' : _numeroController.text.trim()}',
                          isActive: true,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chevron_right,
                    size: 20, color: Color(0xFF0F3B27)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalChip(String label,
      {bool isActive = false, bool isChecked = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0F3B27)
              : isChecked
                  ? const Color(0xFFE8F3EC)
                  : const Color(0xFFF3F8F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF0F3B27)
                : isChecked
                    ? const Color(0xFFC3EAD5)
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isActive
                ? Colors.white
                : isChecked
                    ? const Color(0xFF0F3B27)
                    : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  // 3. Identification & Basic Info Section
  Widget _buildIdentificationSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5EFE9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sell_outlined,
                              size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            'Arete Visual / RFID',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _numeroController,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F3B27),
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                prefixText: '#',
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.volume_up_outlined,
                                size: 16, color: Color(0xFF0F3B27)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5EFE9)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_outlined,
                              size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Registro Genealógico (RGN)',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _registroController,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F3B27),
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFC3EAD5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'PO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F3B27),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sex & Stage Toggles
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSexo = 'Macho'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedSexo == 'Macho'
                                  ? const Color(0xFF0F3B27)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Macho',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedSexo == 'Macho'
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedSexo = 'Hembra'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedSexo == 'Hembra'
                                  ? const Color(0xFF0F3B27)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Hembra',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedSexo == 'Hembra'
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F3EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedEstadoAnimal = 'Desarrollo'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedEstadoAnimal == 'Desarrollo'
                                  ? const Color(0xFF0F3B27)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Desarrollo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedEstadoAnimal == 'Desarrollo'
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedEstadoAnimal = 'Adulto'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedEstadoAnimal == 'Adulto'
                                  ? const Color(0xFF0F3B27)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Adulto',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedEstadoAnimal == 'Adulto'
                                    ? Colors.white
                                    : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 6 Date & Weight Grid Cards
          Row(
            children: [
              Expanded(
                child: _buildGridInfoCard(
                  icon: Icons.calendar_today_outlined,
                  label: 'F. NAC.',
                  controller: _fechaNacController,
                  onTap: () => _selectDate(context, _fechaNacController),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGridInfoCard(
                  icon: Icons.calendar_month_outlined,
                  label: 'F. DESTETE',
                  controller: _fechaDestController,
                  onTap: () => _selectDate(context, _fechaDestController),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGridInfoCard(
                  icon: Icons.hourglass_empty_outlined,
                  label: 'EDAD',
                  controller: _edadDiasController,
                  unit: 'días',
                  highlight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGridInfoCard(
                  icon: Icons.scale_outlined,
                  label: 'P. NACER',
                  controller: _pesoNacController,
                  unit: 'kg',
                  isEditable: true,
                  bgColor: const Color(0xFFFDF4EE),
                  iconColor: Colors.orange[800],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGridInfoCard(
                  icon: Icons.monitor_weight_outlined,
                  label: 'P. DESTETE',
                  controller: _pesoDestController,
                  unit: 'kg',
                  isEditable: true,
                  bgColor: const Color(0xFFE8F3EC),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGridInfoCard(
                  icon: Icons.fitness_center_outlined,
                  label: 'P. AJUSTADO',
                  controller: _pesoAjusController,
                  unit: 'kg',
                  bgColor: const Color(0xFFE8F3EC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridInfoCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    String? unit,
    Color? bgColor,
    Color? iconColor,
    bool highlight = false,
    bool isEditable = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor ?? const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: highlight ? const Color(0xFFC3EAD5) : const Color(0xFFE5EFE9),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 12, color: iconColor ?? Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: iconColor ?? Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: isEditable
                      ? TextField(
                          controller: controller,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                          ],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: iconColor ?? const Color(0xFF1C4331),
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            hintText: '—',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : Text(
                          controller.text.isEmpty ? '—' : controller.text,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: highlight
                                ? const Color(0xFF0F3B27)
                                : const Color(0xFF1C4331),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 2),
                  Text(
                    unit,
                    style: TextStyle(fontSize: 10, color: iconColor ?? Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Guía Visual Morfométrica Section
  Widget _buildGuiaVisualSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.aspect_ratio,
                        size: 16, color: Color(0xFF0F3B27)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Guía Visual\nMorfométrica',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3B27),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _showVectores = !_showVectores),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC3EAD5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _showVectores
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 14,
                        color: const Color(0xFF0F3B27),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showVectores ? 'Ocultar Vectores' : 'Mostrar Vectores',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F3B27),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Interactive Image Area
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: const Color(0xFFE5EFE9),
              border: Border.all(color: const Color(0xFFC3EAD5)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _imageBytes != null
                        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
                        : Container(
                            color: const Color(0xFFE5EFE9),
                            child: Center(
                              child: Image.asset(
                                'assets/icons/logo1.png',
                                height: 90,
                                fit: BoxFit.contain,
                                errorBuilder: (ctx, err, stack) {
                                  return const Icon(
                                    Icons.pets,
                                    size: 50,
                                    color: Color(0xFF0F3B27),
                                  );
                                },
                              ),
                            ),
                          ),
                  ),
                  // Top Recomended Badge Overlay
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F3B27).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.camera_alt,
                              size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'Toma lateral 90° recomendada',
                            style: TextStyle(fontSize: 10, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Vector Overlay graphic representation
                  if (_showVectores) ...[
                    Positioned(
                      top: 75,
                      left: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3B27).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'E - Estructura',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 95,
                      right: 70,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F3B27).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'M - Musculatura ↗',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                  // Bottom Right Overlay Action Buttons
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in,
                              size: 18, color: Color(0xFF0F3B27)),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F3B27),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.camera_alt,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Capturar',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Evaluación EPMURAS Section
  Widget _buildEpmurasSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F3EC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.tune,
                        size: 16, color: Color(0xFF0F3B27)),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Evaluación\nEPMURAS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3B27),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Toque para calificar (1–6)',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        size: 16, color: Colors.grey),
                    onPressed: () {
                      setState(() {
                        _epmuras.updateAll((k, v) => '5');
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Grid 4 traits top row
          Row(
            children: [
              Expanded(child: _buildEpmurasCard('E', 'Estructura')),
              const SizedBox(width: 8),
              Expanded(child: _buildEpmurasCard('P', 'Precocidad')),
              const SizedBox(width: 8),
              Expanded(child: _buildEpmurasCard('M', 'Musculatura')),
              const SizedBox(width: 8),
              Expanded(child: _buildEpmurasCard('U', 'Umbigo')),
            ],
          ),
          const SizedBox(height: 10),
          // Grid 3 traits bottom row
          Row(
            children: [
              Expanded(child: _buildEpmurasCard('R', 'Racial')),
              const SizedBox(width: 8),
              Expanded(child: _buildEpmurasCard('A', 'Aplomos')),
              const SizedBox(width: 8),
              Expanded(child: _buildEpmurasCard('S', 'Sexualidad')),
              const SizedBox(width: 8),
              const Expanded(child: SizedBox()), // spacer for 4-column alignment
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFF0F3B27)),
                  SizedBox(width: 4),
                  Text(
                    'Puntaje lineal 1 (Mínimo) a 6 (Óptimo)',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _openEpmurasSelector('E'),
                child: const Row(
                  children: [
                    Text(
                      'Abrir selector',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3B27),
                      ),
                    ),
                    Icon(Icons.open_in_new,
                        size: 12, color: Color(0xFF0F3B27)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEpmurasCard(String letra, String label) {
    final val = _epmuras[letra] ?? '-';
    return GestureDetector(
      onTap: () => _openEpmurasSelector(letra),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EFE9)),
        ),
        child: Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFF0F3B27),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                letra,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C4331),
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF0F3B27),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$val /6',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Calificación Élite Summary Card
  Widget _buildEliteSummaryCard() {
    final prom = _promedioEpmuras;
    final ratedCount = _criteriosCalificadosCount;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2B1C),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text(
                  prom.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  '/ 6.0',
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'Calificación Élite ',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Icon(Icons.stars, size: 16, color: Color(0xFFC3EAD5)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$ratedCount de 7 criterios calificados con precocidad superior',
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF006837),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TOP',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '5%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. Observación Técnica Section
  Widget _buildObservacionTecnicaSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.subject, color: Color(0xFF0F3B27), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Observación Técnica',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3B27),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC3EAD5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.mic, size: 12, color: Color(0xFF0F3B27)),
                    SizedBox(width: 4),
                    Text(
                      'Dictar en Manga',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F3B27),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Quick tags row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTagChip('+ Lomo amplio'),
                _buildTagChip('+ Pigmentación'),
                _buildTagChip('+ Dócil en brete'),
                _buildTagChip('+ Aplomos correctos'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Comment box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5EFE9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _comentarioController,
                  maxLines: 3,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF1C4331)),
                  decoration: const InputDecoration(
                    hintText: 'Escriba las observaciones del animal...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Incluye en dictamen PDF',
                    style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return GestureDetector(
      onTap: () {
        setState(() {
          final cleanTag = tag.replaceAll('+ ', '');
          if (_comentarioController.text.isEmpty) {
            _comentarioController.text = cleanTag;
          } else {
            _comentarioController.text += '. $cleanTag';
          }
          _markChanged();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F8F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5EFE9)),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[800],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // 8. Bottom Action Buttons & Links
  Widget _buildBottomActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  if (widget.isEditing) {
                    _actualizarEvaluacionExistente();
                  } else {
                    _guardarYVolver();
                  }
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  widget.isEditing
                      ? 'Actualizar y Volver ➔'
                      : 'Guardar y Siguiente ➔',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F3B27),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0F3B27),
                borderRadius: BorderRadius.circular(14),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white, size: 24),
                onPressed: _guardarYNuevo,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                _printOrSharePDF({
                  'numero': _numeroController.text,
                  'registro': _registroController.text,
                  'sexo': _selectedSexo,
                  'estado': _selectedEstadoAnimal,
                  'fecha_nac': _fechaNacController.text,
                  'fecha_dest': _fechaDestController.text,
                  'peso_nac': _pesoNacController.text,
                  'peso_dest': _pesoDestController.text,
                  'peso_ajus': _pesoAjusController.text,
                  'edad_dias': _edadDiasController.text,
                  'epmuras': _epmuras,
                  'image_base64': _imageBytes != null ? base64Encode(_imageBytes!) : null,
                  'sessionId': _sessionId,
                });
              },
              child: const Row(
                children: [
                  Icon(Icons.picture_as_pdf_outlined,
                      size: 14, color: Color(0xFF0F3B27)),
                  SizedBox(width: 4),
                  Text(
                    'Generar Certificado PDF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F3B27),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _confirmCancelar,
              child: Text(
                'Cancelar sesión',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
