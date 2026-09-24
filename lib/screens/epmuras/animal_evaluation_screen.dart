import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart'; // Para rootBundle.load()
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

// â€”â€”â€” IMPORTS PDF â€”â€”â€”
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // pw.Document, pw.Table, pw.Text, etc.
import 'package:printing/printing.dart';

import '../providers/session_provider.dart';
import '../../widgets/custom_app_scaffold.dart';
import '../../services/offline_session_service.dart';
import '../../services/connectivity_service.dart';

class AnimalEvaluationScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? initialData;
  final bool isEditing;

  const AnimalEvaluationScreen({Key? key})
    : docId = null,
      initialData = null,
      isEditing = false,
      super(key: key);

  const AnimalEvaluationScreen.edit({
    Key? key,
    required this.docId,
    required this.initialData,
  }) : isEditing = true,
       super(key: key);

  @override
  State<AnimalEvaluationScreen> createState() => _AnimalEvaluationScreenState();
}

class _AnimalEvaluationScreenState extends State<AnimalEvaluationScreen> {
  // â”€â”€â”€ Controllers para cada campo:
  final _numeroController = TextEditingController();
  final _registroController = TextEditingController();
  final _pesoNacController = TextEditingController();
  final _pesoDestController = TextEditingController();
  final _pesoAjusController = TextEditingController();
  final _edadDiasController = TextEditingController();
  final _fechaNacController = TextEditingController();
  final _fechaDestController = TextEditingController();
  final _comentarioController = TextEditingController();

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
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade800, // Color del header y botÃ³n OK
              onPrimary: Colors.white, // Texto en header
              onSurface: Colors.black, // Texto general
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue.shade800, // BotÃ³n CANCELAR
              ),
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

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  // Dropdowns:
  String? _selectedSexo;
  String? _selectedEstadoAnimal;

  // Mapa de EPMURAS para esta evaluaciÃ³n:
  Map<String, String?> _epmuras = {
    'E': null,
    'P': null,
    'M': null,
    'U': null,
    'R': null,
    'A': null,
    'S': null,
  };

  Uint8List? _imageBytes; // Foto del animal
  String? _sessionId; // Viene de SessionProvider
  bool _hasChanged = false;
  bool _loading = true;

  Map<String, dynamic>? _sessionData;
  Map<String, dynamic>? _producerData;

  @override
  void initState() {
    super.initState();

    // Si es ediciÃ³n, precargamos datos en los controllers:
    if (widget.isEditing && widget.initialData != null) {
      final data = widget.initialData!;
      _numeroController.text = data['numero']?.toString() ?? '';
      _registroController.text = data['registro']?.toString() ?? '';
      _selectedSexo = data['sexo']?.toString();
      _selectedEstadoAnimal = data['estado']?.toString();
      _fechaNacController.text = data['fecha_nac']?.toString() ?? '';
      _fechaDestController.text = data['fecha_dest']?.toString() ?? '';
      _pesoNacController.text = data['peso_nac']?.toString() ?? '';
      _pesoDestController.text = data['peso_dest']?.toString() ?? '';
      _pesoAjusController.text = data['peso_ajus']?.toString() ?? '';
      _edadDiasController.text = data['edad_dias']?.toString() ?? '';

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
    }

    // Detectar cambios para habilitar â€œActualizarâ€:
    _numeroController.addListener(_markChanged);
    _registroController.addListener(_markChanged);
    _pesoNacController.addListener(_markChanged);
    _pesoDestController.addListener(_markChanged);
    _pesoAjusController.addListener(_markChanged);
    _edadDiasController.addListener(_markChanged);
    _fechaNacController.addListener(_markChanged);
    _fechaDestController.addListener(_markChanged);

    // AÃ±ade los listeners de peso ajustado justo despuÃ©s:
    _pesoNacController.addListener(_calcularPesoAjustado);
    _pesoDestController.addListener(_calcularPesoAjustado);
    _fechaNacController.addListener(_calcularPesoAjustado);
    _fechaDestController.addListener(_calcularPesoAjustado);

    // Registrar el callback de reset para el provider (si lo usas):
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SessionProvider>(
        context,
        listen: false,
      ).registerResetEvaluationForm(_resetForm);
    });

    // Cargar datos de sesiÃ³n/productor/usuario desde Firestore:
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
      _selectedSexo = null;
      _selectedEstadoAnimal = null;
      _epmuras.updateAll((k, _) => null);
      _imageBytes = null;
      _hasChanged = false;
    });
    Provider.of<SessionProvider>(context, listen: false).clearAll();
  }

  void _calcularPesoAjustado() {
    final nac = double.tryParse(_pesoNacController.text);
    final dest = double.tryParse(_pesoDestController.text);
    if (nac == null || dest == null) return;

    // Usa DateFormat:
    final df = DateFormat('d/M/y');
    DateTime fn, fd;
    try {
      fn = df.parse(_fechaNacController.text);
      fd = df.parse(_fechaDestController.text);
    } catch (_) {
      return; // formato invÃ¡lido
    }

    final dias = fd.difference(fn).inDays;
    if (dias <= 0) return;

    final ajus = (((dest - nac) / dias) * 205) + nac;
    // Actualiza los controllers dentro de setState para que todo se redibuje:
    setState(() {
      _pesoAjusController.text = ajus.toStringAsFixed(0);
      _edadDiasController.text = dias.toString();
      _hasChanged = true;
    });
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _handleImagePick(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de galerÃ­a'),
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

      // Umbral de 1 MB = 1 048 576 bytes
      const maxSize = 1048576;
      if (compressed.length > maxSize) {
        await showDialog(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Imagen demasiado grande'),
                content: const Text(
                  'La imagen comprimida sigue ocupando mÃ¡s de 1 MB.\n\n'
                  'Recomendaciones:\n'
                  'â€¢ RecÃ³rtala antes de subirla para centrar solo el animal.\n'
                  'â€¢ Reduce su resoluciÃ³n o calidad.\n'
                  'â€¢ Utiliza una herramienta de ediciÃ³n o app mÃ³vil para ajustar el tamaÃ±o.',
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
      await showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
              title: const Text('Error al procesar la imagen'),
              content: const Text(
                'Ha ocurrido un error al comprimir la imagen.\n'
                'Intenta recortar la foto o usar otra imagen mÃ¡s pequeÃ±a.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
      );
    }
  }

  /// Carga datos de sesiÃ³n, productor y usuario desde Firestore
  Future<void> _loadAllData() async {
    if (_sessionId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      // 1) Cargar datos de la sesiÃ³n
      final sessionSnap =
          await LocalFirestore.instance
              .collection('sesiones')
              .doc(_sessionId)
              .get();
      _sessionData = sessionSnap.data();

      // 2) Leer â€œdatos_productorâ€ como SUBCOLECCIÃ“N dentro de esta sesiÃ³n
      final prodQuery =
          await LocalFirestore.instance
              .collection('sesiones')
              .doc(_sessionId)
              .collection('datos_productor')
              .limit(1)
              .get();

      if (prodQuery.docs.isNotEmpty) {
        _producerData = prodQuery.docs.first.data();
      } else {
        _producerData = null;
      }

      // 3) Cargar datos del usuario: **usar "userId" en lugar de "usuarioId"**
      final userId = _sessionData?['userId'] as String?;
      if (userId != null) {
        // Los datos del usuario se cargarÃ¡n cuando se necesiten en el PDF
        // final userSnap =
        //     await LocalFirestore.instance
        //         .collection('usuarios')
        //         .doc(userId)
        //         .get();
        // _userData = userSnap.data();
      }
    } catch (e) {
      debugPrint('Error cargando datos de sesiÃ³n/productor/usuario: $e');
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  /// Guarda o actualiza la evaluaciÃ³n en Firestore
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
      'image_base64':
          sessionProv.imageBytes != null
              ? base64Encode(sessionProv.imageBytes!)
              : null,
      'datos_productor': sessionProv.datosProductor,
      'timestamp': Timestamp.now(),
      'session_id': _sessionId,
    };

    try {
      // Verificar conexiÃ³n a internet
      final hasInternet = await ConnectivityService.hasRealInternetConnection();
      
      if (!hasInternet) {
        // Sin internet: guardar offline
        try {
          final offlineId = await OfflineSessionService.saveEvaluationOffline(
            evaluationData: data,
            sessionId: _sessionId ?? '',
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ðŸ“± Guardado offline. Se sincronizarÃ¡ cuando haya internet.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          _hasChanged = false;
          return offlineId;
        } catch (offlineError) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('âŒ Error al guardar offline: $offlineError'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }
      }

      // Hay internet: intentar guardar en Firestore
      if (widget.isEditing && widget.docId != null) {
        // MODO EDICIÃ“N
        await LocalFirestore.instance
            .collection('sesiones')
            .doc(_sessionId)
            .collection('evaluaciones_animales')
            .doc(widget.docId)
            .update(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('âœ… EvaluaciÃ³n actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return widget.docId;
      } else {
        // MODO NUEVO
        try {
          final docRef = await LocalFirestore.instance
              .collection('sesiones')
              .doc(_sessionId)
              .collection('evaluaciones_animales')
              .add(data);

          _hasChanged = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('âœ… EvaluaciÃ³n guardada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return docRef.id;
        } on FirebaseException catch (e) {
          // Si Firestore falla, guardar offline como respaldo
          debugPrint('âš ï¸ Error de Firestore, guardando offline: ${e.code}');
          try {
            final offlineId = await OfflineSessionService.saveEvaluationOffline(
              evaluationData: data,
              sessionId: _sessionId ?? '',
            );
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ðŸ“± Guardado offline. Se sincronizarÃ¡ cuando sea posible.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            _hasChanged = false;
            return offlineId;
          } catch (offlineError) {
            rethrow;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âŒ Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      // Como Ãºltimo recurso, intentar guardar offline
      try {
        await OfflineSessionService.saveEvaluationOffline(
          evaluationData: data,
          sessionId: _sessionId ?? '',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ðŸ“± Guardado offline como respaldo.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return DateTime.now().millisecondsSinceEpoch.toString();
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _guardarYVolver() async {
    final docId = await _guardarEvaluacionEnFirestore();
    if (docId == null) return;
    _resetForm();
    // Al guardar, navegamos a la pestaÃ±a de "Nueva SesiÃ³n"
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AnimalEvaluationScreen(),
        settings: RouteSettings(arguments: {'sessionId': _sessionId}),
      ),
    );
  }

  Future<void> _actualizarEvaluacionExistente() async {
    if (!_hasChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay cambios para actualizar.'),
          backgroundColor: Colors.grey,
        ),
      );
      return;
    }
    if (_sessionId == null || _sessionId!.isEmpty || widget.docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: no se puede actualizar (falta sessionId o docId).',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final docId = await _guardarEvaluacionEnFirestore();
    if (docId != null) {
      _resetForm();
      Navigator.pushReplacementNamed(context, '/epmuras');
    }
  }

  Future<void> _cancelarEvaluacion() async {
    // No borra nada en la base de datos. Solo redirige sin modificar registros.
    Navigator.pushReplacementNamed(
      context,
      '/new_session',
      arguments: {'sessionId': _sessionId!},
    );
  }

  /// Construye un resumen de los cambios que estamos a punto de guardar.
  /// Si es ediciÃ³n, solo muestra los campos que difieren de initialData.
  /// Si es nuevo, muestra todos los valores ingresados.
  String _buildResumenCambios() {
    final buffer = StringBuffer();

    // Helper para comparar un campo (edit) vs valor original:
    void compareField(String key, String label, String actualValue) {
      if (widget.isEditing && widget.initialData != null) {
        final original = (widget.initialData![key]?.toString() ?? '');
        if (original != actualValue) {
          buffer.writeln(
            '$label:\n  â€¢ Antes: $original\n  â€¢ Ahora: $actualValue\n',
          );
        }
      } else {
        // modo â€œnuevoâ€
        buffer.writeln('$label: $actualValue\n');
      }
    }

    // Campos texto bÃ¡sicos:
    compareField('numero', 'NÃºmero', _numeroController.text);
    compareField('registro', 'Registro (RGN)', _registroController.text);
    compareField('sexo', 'Sexo', _selectedSexo ?? '-');
    compareField('estado', 'Estado Animal', _selectedEstadoAnimal ?? '-');
    compareField('fecha_nac', 'Fecha Nacimiento', _fechaNacController.text);
    compareField('fecha_dest', 'Fecha Destete', _fechaDestController.text);
    compareField('peso_nac', 'Peso Nacimiento', _pesoNacController.text);
    compareField('peso_dest', 'Peso Destete', _pesoDestController.text);
    compareField('peso_ajus', 'Peso Ajustado', _pesoAjusController.text);
    compareField('edad_dias', 'Edad (dÃ­as)', _edadDiasController.text);

    // EPMURAS:
    if (widget.isEditing && widget.initialData != null) {
      final origEpm =
          (widget.initialData!['epmuras'] as Map<String, dynamic>? ?? {});
      _epmuras.forEach((letra, valorActual) {
        final origVal = (origEpm[letra]?.toString() ?? '');
        final actVal = valorActual ?? '-';
        if (origVal != actVal) {
          buffer.writeln(
            'EPMURAS $letra:\n  â€¢ Antes: $origVal\n  â€¢ Ahora: $actVal\n',
          );
        }
      });
    } else {
      // Nuevo => mostrar todos los EPMURAS que tengan algo distinto de null:
      _epmuras.forEach((letra, valorActual) {
        final actVal = valorActual ?? '-';
        buffer.writeln('EPMURAS $letra: $actVal\n');
      });
    }

    // Imagen:
    if (widget.isEditing && widget.initialData != null) {
      final origBase64 = widget.initialData!['image_base64'] as String?;
      final tieneOriginal = origBase64 != null && origBase64.isNotEmpty;
      final tieneActual = _imageBytes != null;
      if (tieneOriginal != tieneActual) {
        buffer.writeln(
          'Foto del animal:\n  â€¢ Antes: ${tieneOriginal ? 'existÃ­a' : 'no existÃ­a'}\n  â€¢ Ahora: ${tieneActual ? 'ha sido cargada' : 'ha sido removida'}\n',
        );
      }
    } else {
      // Modo nuevo:
      if (_imageBytes != null) {
        buffer.writeln('Foto del animal: Se cargÃ³ una imagen\n');
      } else {
        buffer.writeln('Foto del animal: (sin imagen)\n');
      }
    }

    final resultado = buffer.toString().trim();
    return resultado.isEmpty ? '[No hay cambios detectados]' : resultado;
  }

  Future<void> _confirmGuardar() async {
    final resumen = _buildResumenCambios();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Icon(
                widget.isEditing ? Icons.edit_note : Icons.save_alt,
                color: widget.isEditing ? Colors.orange : Colors.blue,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.isEditing
                      ? 'Confirmar actualizaciÃ³n'
                      : 'Confirmar guardado',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            // âœ… Agregado para scroll completo
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing
                      ? 'EstÃ¡s a punto de actualizar esta evaluaciÃ³n con los siguientes cambios:'
                      : 'EstÃ¡s a punto de guardar la siguiente informaciÃ³n.\n\nðŸ“Œ Al confirmar, serÃ¡s redirigido a la pestaÃ±a "Nueva SesiÃ³n".',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 250,
                  ), // âœ… LÃ­mite de altura
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      resumen,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              icon: Icon(widget.isEditing ? Icons.check : Icons.save),
              label: Text(widget.isEditing ? 'Actualizar' : 'Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.isEditing ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (widget.isEditing) {
        _actualizarEvaluacionExistente();
      } else {
        _guardarYVolver();
      }
    }
  }

  /// Muestra un diÃ¡logo de confirmaciÃ³n antes de cancelar la ediciÃ³n/creaciÃ³n.
  /// Solo advierte que se perderÃ¡n los cambios en la pantalla actual, sin tocar la base de datos.
  Future<void> _confirmCancelar() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar Salida'),
          content: const Text(
            'Â¿Deseas salir sin guardar? No se eliminarÃ¡ ningÃºn registro en la base de datos.',
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
        );
      },
    );

    if (confirm == true) {
      _cancelarEvaluacion();
    }
  }

  /// -----------------------------------------------------------------------
  /// Carga todas las evaluaciones dentro de cada sesiÃ³n (colecciÃ³n raÃ­z)
  Future<List<Map<String, dynamic>>> _cargarTodasLasEvaluaciones() async {
    final firestore = LocalFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    final sesionesSnapshot =
        await firestore
            .collection('sesiones')
            .orderBy('fecha_creacion', descending: true)
            .get();

    final List<Map<String, dynamic>> acumulado = [];

    for (final sesionDoc in sesionesSnapshot.docs) {
      final sessionId = sesionDoc.id;

      // ðŸ” Leer solo evaluaciones de este usuario
      final evalsSnapshot =
          await firestore
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

  /// -----------------------------------------------------------------------
  /// DIALOG PARA â€œVer sesiones y evaluacionesâ€
  ///
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
            final totalEval = todasLasEval.length;

            // Contar cuÃ¡ntas sesiones distintas hay:
            final sesionesDistintas = <String>{};
            for (var m in todasLasEval) {
              if (m['sessionId'] != null) {
                sesionesDistintas.add(m['sessionId'] as String);
              }
            }
            final totalSesiones = sesionesDistintas.length;

            return StatefulBuilder(
              builder: (context, setStateSB) {
                // Filtrar segÃºn nÃºmero o registro:

                final filtered =
                    todasLasEval.where((m) {
                      final numero =
                          (m['numero'] ?? '').toString().toLowerCase();
                      final registro =
                          (m['registro'] ?? '').toString().toLowerCase();
                      final q = searchQuery.toLowerCase();
                      return numero.contains(q) || registro.contains(q);
                    }).toList();
                filtered.sort((a, b) {
                  final na = int.tryParse(a['numero']?.toString() ?? '0') ?? 0;
                  final nb = int.tryParse(b['numero']?.toString() ?? '0') ?? 0;
                  return na.compareTo(nb);
                });

                return AlertDialog(
                  title: const Text('Sesiones y Evaluaciones'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 400, // Ajusta la altura segÃºn convenga
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total evaluaciones: $totalEval'),
                        const SizedBox(height: 4),
                        Text('Sesiones distintas: $totalSesiones'),
                        const SizedBox(height: 12),
                        TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Buscar por nÃºmero o registro',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (val) {
                            setStateSB(() {
                              searchQuery = val;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child:
                              filtered.isEmpty
                                  ? const Center(
                                    child: Text('No se encontraron resultados'),
                                  )
                                  : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, idx) {
                                      final m = filtered[idx];
                                      final numero = m['numero'] ?? 'â€”';
                                      final registro = m['registro'] ?? 'â€”';
                                      final fechaNac = m['fecha_nac'] ?? 'â€”';
                                      final pesoNac = m['peso_nac'] ?? 'â€”';
                                      final imageBase64 =
                                          m['image_base64'] as String?;

                                      Widget leadingImage = const SizedBox(
                                        width: 48,
                                      );
                                      if (imageBase64 != null) {
                                        try {
                                          final bytes = base64Decode(
                                            imageBase64,
                                          );
                                          leadingImage = ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: Image.memory(
                                              bytes,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                            ),
                                          );
                                        } catch (_) {
                                          leadingImage = const SizedBox(
                                            width: 48,
                                          );
                                        }
                                      }

                                      return ListTile(
                                        leading: leadingImage,
                                        title: Text(
                                          'NÂ° $numero  Â·  RGN $registro',
                                        ),
                                        subtitle: Text(
                                          'Nac.: $fechaNac  Â·  Peso: $pesoNac',
                                        ),
                                        onTap: () async {
                                          final currentUserId =
                                              FirebaseAuth
                                                  .instance
                                                  .currentUser
                                                  ?.uid;
                                          final evalUserId =
                                              m['usuarioId'] as String?;

                                          if (currentUserId == null ||
                                              evalUserId != currentUserId) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'â›” No puedes acceder a esta evaluaciÃ³n.',
                                                ),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                            return;
                                          }

                                          Navigator.of(context).pop();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
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

  /// Calcula el promedio de EPMURAS para una lista de evaluaciones
  Map<String, double> _calcularPromedioSesion(
    List<Map<String, dynamic>> evaluaciones,
  ) {
    Map<String, double> sumMap = {
      'E': 0,
      'P': 0,
      'M': 0,
      'U': 0,
      'R': 0,
      'A': 0,
      'S': 0,
    };
    int count = 0;

    for (var evalData in evaluaciones) {
      final epm = (evalData['epmuras'] as Map<String, dynamic>? ?? {});
      if (epm.isNotEmpty) {
        count++;
        sumMap.forEach((key, _) {
          final val = double.tryParse(epm[key]?.toString() ?? '') ?? 0.0;
          sumMap[key] = (sumMap[key] ?? 0) + val;
        });
      }
    }
    if (count > 0) {
      sumMap.updateAll((key, val) => val / count);
    }
    return sumMap;
  }

  /// -----------------------------------------------------------------------
  /// Genera (o comparte) el PDF con todos los datos (animal, usuario, lista EPMURAS, etc.)
  // ignore: unused_element
  Future<void> _printOrSharePDF(Map<String, dynamic> m) async {
    try {
      // â”€â”€â”€ 1) EXTRAER DATOS DE 'm' â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

      // Construimos el mapa epmurasForPDF a partir de m['epmuras']
      final rawEpm = (m['epmuras'] as Map<String, dynamic>? ?? {});
      final epmurasForPDF = <String, String>{};
      rawEpm.forEach((k, v) {
        epmurasForPDF[k] = v?.toString() ?? '0';
      });

      // Foto base64 si existe
      final imageBase64 = m['image_base64'] as String?;

      // â”€â”€â”€ 2) LEER DATOS DEL USUARIO DESDE FIRESTORE â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      String userName = 'Nombre no disponible';
      String userEmail = 'E-mail no disponible';
      String userProf = 'ProfesiÃ³n no disponible';
      String userLoc = 'UbicaciÃ³n no disponible';

      try {
        final currentSessionId = (m['sessionId'] ?? '') as String;
        if (currentSessionId.isNotEmpty) {
          final sessionSnap =
              await LocalFirestore.instance
                  .collection('sesiones')
                  .doc(currentSessionId)
                  .get();
          final sessionData = sessionSnap.data();
          final usuarioId = sessionData?['userId'] as String?;
          if (usuarioId != null && usuarioId.isNotEmpty) {
            final userSnap =
                await LocalFirestore.instance
                    .collection('usuarios')
                    .doc(usuarioId)
                    .get();
            final udata = userSnap.data();
            userName = udata?['nombre'] as String? ?? userName;
            userEmail = udata?['email'] as String? ?? userEmail;
            userProf = udata?['profesion'] as String? ?? userProf;
            userLoc = udata?['ubicacion'] as String? ?? userLoc;
          }
        }
      } catch (e) {
        debugPrint('[PDF] Error cargando datos de usuario: $e');
      }

      // â”€â”€â”€ 3) LEER DATOS DEL PRODUCTOR (subcolecciÃ³n) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      String prodTexto = 'No hay datos del productor';
      final datosProductorWidgets = <pw.Widget>[];
      {
        final prodQuery =
            await LocalFirestore.instance
                .collection('sesiones')
                .doc(_sessionId)
                .collection('datos_productor')
                .limit(1)
                .get();
        if (prodQuery.docs.isNotEmpty) {
          _producerData = prodQuery.docs.first.data();
        }
      }
      if (_producerData != null && _producerData!.isNotEmpty) {
        // Definimos exclusivamente los cuatro campos deseados:
        final camposDeseados = <String>[
          'unidad_produccion',
          'ubicacion',
          'estado',
          'municipio',
        ];
        for (final key in camposDeseados) {
          final valor = _producerData![key];
          if (valor != null && valor.toString().trim().isNotEmpty) {
            datosProductorWidgets.add(
              pw.Text(
                'â€¢ $key: ${valor.toString()}',
                style: pw.TextStyle(fontSize: 11),
              ),
            );
          }
        }
        prodTexto = 'Datos del productor:';
      }

      // â”€â”€â”€ 4) CARGAR LOGO DE ASSETS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final Uint8List logoBytes =
          (await rootBundle.load(
            'assets/icons/logoapp2.png',
          )).buffer.asUint8List();

      // â”€â”€â”€ 5) DECODIFICAR FOTO DEL ANIMAL (SI HAY) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      Uint8List? fotoBytes;
      if (imageBase64 != null) {
        try {
          fotoBytes = base64Decode(imageBase64);
        } catch (_) {
          fotoBytes = null;
        }
      }

      // â”€â”€â”€ 6) CALCULAR PROMEDIO DE EPMURAS PARA LA SESIÃ“N â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      List<Map<String, dynamic>> todasEvalMap = [];
      try {
        todasEvalMap = await _cargarTodasLasEvaluaciones();
      } catch (_) {}
      final currentSessionId = _sessionId ?? '';
      final evalsActualSession =
          todasEvalMap
              .where(
                (e) => (e['sessionId']?.toString() ?? '') == currentSessionId,
              )
              .toList();
      final promedioSesionMap = _calcularPromedioSesion(evalsActualSession);

      // â”€â”€â”€ 7) CREAR EL DOCUMENTO PDF â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            // 7.1) Encabezado con logo e lÃ­nea azul
            final header = <pw.Widget>[
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: 120,
                  height: 40,
                ),
              ),
              pw.Divider(color: PdfColors.blue, thickness: 2),
              pw.SizedBox(height: 8),
            ];

            // 7.2) Datos del usuario (ya cargados correctamente)
            final datosUsuario = <pw.Widget>[
              pw.Text('Usuario: $userName', style: pw.TextStyle(fontSize: 12)),
              pw.Text('Correo: $userEmail', style: pw.TextStyle(fontSize: 12)),
              pw.Text(
                'ProfesiÃ³n: $userProf',
                style: pw.TextStyle(fontSize: 12),
              ),
              pw.Text('UbicaciÃ³n: $userLoc', style: pw.TextStyle(fontSize: 12)),
              pw.Divider(color: PdfColors.grey),
            ];

            // 7.3) Encabezado del productor (sÃ³lo si hay algo para mostrar)
            final encabezadoProductor = <pw.Widget>[];
            if (datosProductorWidgets.isNotEmpty) {
              encabezadoProductor.add(
                pw.Text(prodTexto, style: pw.TextStyle(fontSize: 12)),
              );
              encabezadoProductor.add(pw.SizedBox(height: 4));
              encabezadoProductor.addAll(datosProductorWidgets);
              encabezadoProductor.add(pw.Divider(color: PdfColors.grey));
              encabezadoProductor.add(pw.SizedBox(height: 8));
            }

            // 7.4) FOTO DEL ANIMAL + DATOS DEL ANIMAL COMO TABLA
            final detallesAnimal = <String>[
              'NÃºmero: $numero',
              'Registro (RGN): $registro',
              'Sexo: $sexo',
              'Estado: $estado',
              'Fecha Nacimiento: $fechaNac',
              'Fecha Destete: $fechaDest',
              'Peso Nacimiento: $pesoNac',
              'Peso Destete: $pesoDest',
              'Peso Ajustado: $pesoAjus',
              'Edad (dÃ­as): $edadDias',
            ];

            final datosAnimalTable = pw.Table(
              columnWidths: {
                0: pw.FixedColumnWidth(200), // ancho fijo para la foto
                1: pw.FlexColumnWidth(), // el resto para los bullets
              },
              children: [
                pw.TableRow(
                  children: [
                    // Celda 0: imagen o â€œSin fotoâ€
                    if (fotoBytes != null)
                      pw.Image(
                        pw.MemoryImage(fotoBytes),
                        width: 200,
                        height: 200,
                        fit: pw.BoxFit.cover,
                      )
                    else
                      pw.Container(
                        width: 200,
                        height: 200,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey),
                        ),
                        child: pw.Center(child: pw.Text('Sin foto')),
                      ),

                    // Celda 1: lista de viÃ±etas
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 10),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children:
                            detallesAnimal
                                .map((texto) => pw.Bullet(text: texto))
                                .toList(),
                      ),
                    ),
                  ],
                ),
              ],
            );

            // 7.5) RESULTADOS EPMURAS (tabla sencilla)
            final tablaEpm = <pw.Widget>[
              pw.SizedBox(height: 16),
              pw.Header(level: 1, text: 'Resultados EPMURAS'),
              pw.Table.fromTextArray(
                headers: ['Letra', 'Valor', 'Promedio SesiÃ³n'],
                data:
                    epmurasForPDF.keys.map((letra) {
                      final val = epmurasForPDF[letra] ?? '-';
                      final promDouble = promedioSesionMap[letra] ?? 0.0;
                      final prom = promDouble.toStringAsFixed(2);
                      return [letra, val, prom];
                    }).toList(),
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              ),
            ];

            // 7.6) Pie de pÃ¡gina
            final footer = <pw.Widget>[
              pw.Divider(color: PdfColors.blue, thickness: 2),
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  width: 100,
                  height: 30,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generado: ${DateTime.now().toString().substring(0, 19)}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey),
                ),
              ),
            ];

            return [
              ...header,
              ...datosUsuario,
              ...encabezadoProductor,
              datosAnimalTable,
              ...tablaEpm,
              ...footer,
            ];
          },
        ),
      );

      // â”€â”€â”€ 8) COMPARTIR / GUARDAR EL PDF â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'evaluacion_animal_$numero.pdf',
      );
    } catch (e) {
      debugPrint('[PDF] Error generando PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('âŒ Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('Ver imagen actual'),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          content: Image.memory(_imageBytes!),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Reemplazar imagen'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Quitar imagen'),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _imageBytes = null;
                    _hasChanged = true;
                  });
                },
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si aÃºn estoy cargando datos de Firestore:
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return CustomAppScaffold(
      currentIndex: 2,
      title: widget.isEditing ? 'Editar EvaluaciÃ³n' : 'EvaluaciÃ³n',
      showBackButton: true,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // â”€â”€â”€ BotÃ³n para ver sesiones y evaluaciones â”€â”€â”€
              Center(
                child: ElevatedButton.icon(
                  onPressed: _mostrarConteosDialog,
                  icon: const Icon(Icons.list, color: Colors.white),
                  label: const Text(
                    'Ver sesiones y evaluaciones',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // â”€â”€â”€â”€ Campo: NÃºmero â”€â”€â”€â”€
              _buildLabeledTextField('NÃºmero', controller: _numeroController),

              // â”€â”€â”€ Campo: Registro Animal (RGN) â”€â”€â”€
              _buildLabeledTextField(
                'Registro (RGN)',
                controller: _registroController,
              ),

              // â”€ Dropdowns: Estado del Animal y Sexo â”€
              Row(
                children: [
                  Expanded(
                    child: _buildLabeledDropdown(
                      'Estado del Animal',
                      _animalStates,
                      value: _selectedEstadoAnimal,
                      onChanged: (val) {
                        setState(() {
                          _selectedEstadoAnimal = val;
                          _markChanged();
                          if (!_animalStates.contains(_selectedEstadoAnimal)) {
                            _selectedEstadoAnimal = null;
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLabeledDropdown(
                      'Sexo',
                      ['Macho', 'Hembra'],
                      value: _selectedSexo,
                      onChanged: (val) {
                        setState(() {
                          _selectedSexo = val;
                          _markChanged();
                          if (!_animalStates.contains(_selectedEstadoAnimal)) {
                            _selectedEstadoAnimal = null;
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),

              // â”€â”€â”€ Fecha Nacimiento / Fecha Destete â”€â”€â”€
              // â”€â”€ Fechas: Nacimiento y Destete â”€â”€
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fechaNacController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fecha Nacimiento',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _fechaNacController),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _fechaDestController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Fecha Destete',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.calendar_today),
                      ),
                      onTap: () => _selectDate(context, _fechaDestController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // â”€â”€ Pesos: Nacimiento y Destete â”€â”€
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pesoNacController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso al nacer (kg)',
                        prefixIcon: const Icon(
                          Icons.monitor_weight,
                          color: Colors.orange,
                        ),
                        filled: true,
                        fillColor: Colors.orange[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => _markChanged(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _pesoDestController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Peso al destete (kg)',
                        prefixIcon: const Icon(
                          Icons.scale,
                          color: Colors.deepPurple,
                        ),
                        filled: true,
                        fillColor: Colors.purple[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => _markChanged(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pesoAjusController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Peso Ajustado (kg)',
                        prefixIcon: const Icon(Icons.fitness_center),
                        filled: true,
                        fillColor: Colors.green[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _edadDiasController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Edad (dÃ­as)',
                        prefixIcon: const Icon(Icons.calendar_today),
                        filled: true,
                        fillColor: Colors.blue[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // â”€â”€â”€â”€â”€ Foto del animal â”€â”€â”€â”€â”€
              const Text('Foto del animal:'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  if (_imageBytes != null) {
                    _mostrarOpcionesImagen();
                  } else {
                    _pickImage();
                  }
                },
                child: Container(
                  height: 180,

                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black54),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      _imageBytes != null
                          ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _imageBytes!,
                              fit: BoxFit.cover,
                            ),
                          )
                          : const Center(
                            child: Text('Toca para cargar o tomar foto'),
                          ),
                ),
              ),

              const SizedBox(height: 20),

              // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ EPMURAS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              const Text(
                'EPMURAS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildEpmurasInputs(),

              const SizedBox(height: 20),

              // â”€â”€â”€â”€â”€ Campo: Comentario â”€â”€â”€â”€â”€
              _buildLabeledTextField(
                'Comentario del evaluador (PDF)',
                controller: _comentarioController,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // â”€â”€â”€â”€â”€ Botones Guardar / Actualizar / Nuevo / Cancelar â”€â”€â”€â”€â”€
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // â”€ BotÃ³n Guardar o Actualizar â”€ ahora llama a _confirmGuardar()
                    ElevatedButton(
                      onPressed: () {
                        _confirmGuardar();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            widget.isEditing
                                ? (_hasChanged
                                    ? Colors.orange[700]
                                    : Colors.grey)
                                : Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        widget.isEditing ? 'Actualizar' : 'Guardar',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // â”€ BotÃ³n â€œNuevoâ€ (solo si no estamos editando) â”€ (sin cambios)
                    if (!widget.isEditing)
                      ElevatedButton.icon(
                        onPressed: _guardarYNuevo,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Nuevo',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),

                    const SizedBox(width: 12),

                    // â”€ BotÃ³n â€œCancelarâ€ â”€ ahora llama a _confirmCancelar()
                    ElevatedButton(
                      onPressed: () {
                        _confirmCancelar();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Construye inputs de EPMURAS
  Widget _buildEpmurasInputs() {
    final letrasIzquierda = ['E', 'P', 'M', 'U'];
    final letrasDerecha = ['R', 'A', 'S'];

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Columna izquierda
          Column(
            mainAxisSize: MainAxisSize.min,
            children:
                letrasIzquierda
                    .map(
                      (letra) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: _buildLetraInput(letra),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(width: 40),
          // Columna derecha
          Column(
            mainAxisSize: MainAxisSize.min,
            children:
                letrasDerecha
                    .map(
                      (letra) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: _buildLetraInput(letra),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLetraInput(String letra) {
    final maxItems = (letra == 'E' || letra == 'P' || letra == 'M') ? 6 : 4;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            letra,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          height: 44,
          child: DropdownButtonFormField<String>(
            value: _epmuras[letra],
            isExpanded: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 16, color: Colors.black),
            iconSize: 24,
            items: List.generate(
              maxItems,
              (i) => DropdownMenuItem(
                value: '${i + 1}',
                child: Center(child: Text('${i + 1}')),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _epmuras[letra] = val!;
                _markChanged();
              });
            },
          ),
        ),
      ],
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildLabeledTextField(
    String label, {
    required TextEditingController controller,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType:
                inputFormatters != null
                    ? TextInputType.number
                    : TextInputType.text,
            inputFormatters: inputFormatters,
            onChanged: (_) => _markChanged(),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildLabeledDropdown(
    String label,
    List<String> items, {
    String? value,
    ValueChanged<String?>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            value: value,
            items:
                items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  List<String> get _animalStates {
    if (_selectedSexo == 'Macho') {
      return ['Mautes', 'Toretes', 'Toros'];
    } else if (_selectedSexo == 'Hembra') {
      return ['Mautas', 'Novillas', 'Vacas'];
    }
    return [];
  }
}




