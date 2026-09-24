import 'package:flutter/material.dart';
import 'package:boviframe/services/local_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sesiones_screen.dart';

class ConsultaFincaScreen extends StatefulWidget {
  const ConsultaFincaScreen({Key? key}) : super(key: key);

  @override
  State<ConsultaFincaScreen> createState() => _ConsultaFincaScreenState();
}

class _ConsultaFincaScreenState extends State<ConsultaFincaScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _allFincas = [];
  List<Map<String, dynamic>> _filteredFincas = [];

  bool _loading = true;
  String? _error;

  String _filtroUnidad = '';
  String _filtroUbicacion = '';
  String _filtroMunicipio = '';

  @override
  void initState() {
    super.initState();
    _loadFincas();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFincas() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final querySnapshot =
          await LocalFirestore.instance.collection('sesiones').get();

      final temp = <Map<String, dynamic>>[];

      for (final sessionDoc in querySnapshot.docs) {
        final sessionId = sessionDoc.id;
        final datosSnapshot =
            await sessionDoc.reference
                .collection('datos_productor')
                .where('userId', isEqualTo: userId)
                .get();

        for (final doc in datosSnapshot.docs) {
          final d = doc.data();
          final numSes = (sessionDoc.data()['numero_sesion'] ?? '').toString();

          temp.add({
            'unidad_produccion': d['unidad_produccion'] ?? '',
            'ubicacion': d['ubicacion'] ?? '',
            'municipio': d['municipio'] ?? '',
            'session_id': sessionId,
            'numero_sesion': numSes,
          });
        }
      }

      final mapa = <String, Map<String, dynamic>>{};
      for (var item in temp) {
        final finca = item['unidad_produccion'] as String;
        mapa.putIfAbsent(
          finca,
          () => {
            'unidad_produccion': finca,
            'ubicacion': item['ubicacion'],
            'municipio': item['municipio'],
            'sesiones': <Map<String, dynamic>>[],
          },
        );
        (mapa[finca]!['sesiones'] as List).add({
          'session_id': item['session_id'],
          'numero_sesion': item['numero_sesion'],
        });
      }

      if (!mounted) return;

      setState(() {
        _allFincas = mapa.values.toList();
        _filteredFincas = List.from(_allFincas);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error cargando fincas: $e';
        _loading = false;
      });
    }
  }

  void _applyFilters() {
    final q = _searchController.text.trim().toLowerCase();
    setState(() {
      _filteredFincas =
          _allFincas.where((f) {
            final unidad = (f['unidad_produccion'] as String).toLowerCase();
            final ubicacion = (f['ubicacion'] as String).toLowerCase();
            final municipio = (f['municipio'] as String).toLowerCase();

            final matchSearch = unidad.contains(q);
            final matchUnidad =
                _filtroUnidad.isEmpty ||
                unidad.contains(_filtroUnidad.toLowerCase());
            final matchUbic =
                _filtroUbicacion.isEmpty ||
                ubicacion.contains(_filtroUbicacion.toLowerCase());
            final matchMun =
                _filtroMunicipio.isEmpty ||
                municipio.contains(_filtroMunicipio.toLowerCase());

            return matchSearch && matchUnidad && matchUbic && matchMun;
          }).toList();
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Filtros adicionales',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Unidad de producciÃ³n',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _filtroUnidad = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'UbicaciÃ³n',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _filtroUbicacion = v,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Municipio',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => _filtroMunicipio = v,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _applyFilters();
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('APLICAR FILTROS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('CERRAR FILTROS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue[800],
        iconTheme: const IconThemeData(color: Colors.white),

        centerTitle: true,
        title: const Text(
          'Consultar Fincas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 1,
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar Fincas',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showFilterSheet,
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'FILTROS',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _applyFilters,
                        icon: const Icon(Icons.search, color: Colors.white),
                        label: const Text(
                          'BUSCAR',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[500],
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredFincas.isEmpty
                    ? const Center(child: Text('No hay fincas.'))
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: _filteredFincas.length,
                      itemBuilder: (ctx, i) {
                        final finca = _filteredFincas[i];
                        final sessions = List<Map<String, dynamic>>.from(
                          finca['sesiones'] as List,
                        );
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.agriculture,
                                      color: Colors.blueAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        finca['unidad_produccion'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        finca['ubicacion'],
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.map,
                                      size: 18,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        finca['municipio'],
                                        style: const TextStyle(
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.list_alt,
                                          size: 20,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${sessions.length} sesiones',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => SesionesScreen(
                                                  finca:
                                                      finca['unidad_produccion'],
                                                  sesiones: sessions,
                                                ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blueAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Ver sesiones',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}



