import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/local_firestore.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'providers/settings_provider.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({Key? key}) : super(key: key);

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int _currentTab = 0;
  int _bannerIndex = 0;
  late PageController _bannerPageController;
  List<Map<String, dynamic>> _topEvaluations = [];
  String _selectedFarm = "Sin Finca Asignada";
  String _selectedLot = "Sin Lote";
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _farms = [];


  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
    _loadTopEvaluations();
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTopEvaluations() async {
    try {
      List<Map<String, dynamic>> evals = [];
      Map<String, String> farmsFound = {};
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final sesionesSnap = await LocalFirestore.instance.collection('sesiones').get();

      for (var sesionDoc in sesionesSnap.docs) {
        final sData = sesionDoc.data();
        final farmName = sData['unidad_produccion'] ??
            sData['nombre_finca'] ??
            sData['hacienda'] ??
            (sData['datos_productor'] is Map ? sData['datos_productor']['unidad_produccion'] : null);
        final lotName = sData['numero_sesion'] ?? sData['lote'] ?? 'Sesión activa';

        if (farmName != null && farmName.toString().trim().isNotEmpty) {
          farmsFound[farmName.toString()] = lotName.toString();
        }

        final ownerName = sData['propietario'] ??
            sData['nombre_propietario'] ??
            (sData['datos_productor'] is Map ? sData['datos_productor']['nombre'] : null) ??
            '';

        final evalRef = sesionDoc.reference.collection('evaluaciones_animales');
        final evalSnap = (userId != null && userId.isNotEmpty)
            ? await evalRef.where('usuarioId', isEqualTo: userId).get()
            : await evalRef.get();

        for (var evalDoc in evalSnap.docs) {
          final data = Map<String, dynamic>.from(evalDoc.data());
          data['evalId'] = evalDoc.id;
          data['sessionId'] = sesionDoc.id;
          data['hacienda'] = farmName ?? 'Finca sin asignar';
          data['propietario'] = ownerName;
          evals.add(data);
        }
      }

      evals.sort((a, b) {
        final tA = a['fecha_evaluacion'] ?? a['createdAt'] ?? '';
        final tB = b['fecha_evaluacion'] ?? b['createdAt'] ?? '';
        return tB.toString().compareTo(tA.toString());
      });

      if (mounted) {
        setState(() {
          _topEvaluations = evals.take(5).toList();
          if (farmsFound.isNotEmpty) {
            _farms.clear();
            _farms.addAll(farmsFound.entries.map((e) => {'name': e.key, 'lot': e.value}));
            if (_selectedFarm == "Sin Finca Asignada" && _farms.isNotEmpty) {
              _selectedFarm = _farms.first['name']!;
              _selectedLot = _farms.first['lot']!;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _topEvaluations = [];
        });
      }
    }
  }

  void _showFarmSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Seleccionar Finca / Lote",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF192A20),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_farms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "No hay fincas registradas.",
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ),
                )
              else
                ..._farms.map((f) => ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE2EFE7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF235C3F),
                    ),
                  ),
                  title: Text(
                    f['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF192A20),
                    ),
                  ),
                  subtitle: Text(f['lot']!),
                  trailing: _selectedFarm == f['name']
                      ? const Icon(Icons.check_circle, color: Color(0xFF235C3F))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedFarm = f['name']!;
                      _selectedLot = f['lot']!;
                    });
                    Navigator.pop(context);
                  },
                )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/consulta_finca');
                  },
                  icon: const Icon(Icons.add, color: Color(0xFF235C3F)),
                  label: const Text(
                    "Gestionar Fincas",
                    style: TextStyle(
                      color: Color(0xFF235C3F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF235C3F)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Filtros de búsqueda",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF192A20),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text("Todos los lotes"),
                    selected: true,
                    onSelected: (_) {},
                    selectedColor: const Color(0xFFE2EFE7),
                    checkmarkColor: const Color(0xFF235C3F),
                  ),
                  FilterChip(
                    label: const Text("Excelentes (>90 pts)"),
                    selected: false,
                    onSelected: (_) {},
                  ),
                  FilterChip(
                    label: const Text("Pendientes de calificar"),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF235C3F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Aplicar Filtros",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProv = Provider.of<SettingsProvider>(context, listen: false);
    final companyName = settingsProv.userCompany.isNotEmpty
        ? settingsProv.userCompany
        : _selectedFarm;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F4),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- TOP HEADER ---
                    _buildTopHeader(companyName),
                    const SizedBox(height: 16),

                    // --- SEARCH BAR ---
                    _buildSearchBar(),
                    const SizedBox(height: 18),

                    // --- HERO BANNER & ULTIMAS 5 EVALUACIONES (SCROLL DE FICHAS) ---
                    _buildTopBannerCarousel(),
                    const SizedBox(height: 12),
                    _buildCarouselDots(),
                    const SizedBox(height: 22),

                    // --- MÓDULOS DE GESTIÓN ---
                    _buildSectionHeader(
                      title: "Módulos de Gestión",
                      actionText: "Ver todos >",
                      onActionTap: () => Navigator.pushNamed(context, '/consulta'),
                    ),
                    const SizedBox(height: 14),
                    _buildModulosGrid(),
                    const SizedBox(height: 24),

                    // --- ÚLTIMAS EVALUACIONES EPMURAS ---
                    _buildSectionHeader(
                      title: "Últimas Evaluaciones EPMURAS",
                      subtitle: "Manga 2 • Criterios morfológicos 1 a 6",
                      actionText: "Ver todas >",
                      onActionTap: () => Navigator.pushNamed(context, '/consulta'),
                    ),
                    const SizedBox(height: 14),
                    _buildEvaluacionesCarousel(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // --- BOTTOM NAVIGATION BAR ---
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  // Header Widget
  Widget _buildTopHeader(String companyName) {
    return Row(
      children: [
        GestureDetector(
          onTap: _showFarmSelector,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE2EFE7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFC8E2D2), width: 1),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFF235C3F),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _showFarmSelector,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF192A20),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFF192A20),
                      size: 20,
                    ),
                  ],
                ),
                Text(
                  _selectedLot,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Sync button
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Sincronizando datos con el servidor..."),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF235C3F),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.sync_rounded,
              color: Color(0xFF475569),
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Notifications button
        InkWell(
          onTap: () => Navigator.pushNamed(context, '/news_public'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF475569),
                  size: 20,
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF97316),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Search Bar Widget
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 22,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  Navigator.pushNamed(context, '/consulta');
                }
              },
              decoration: const InputDecoration(
                hintText: "Buscar arete, ejemplar, lote o evaluación...",
                hintStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          InkWell(
            onTap: _showFilterSheet,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Icon(
                Icons.tune_rounded,
                color: Color(0xFF475569),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hero Card Banner Widget
  Widget _buildHeroBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF235C3F),
            Color(0xFF1B4931),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF235C3F).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark Graphic Decoration
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: HeroWatermarkPainter(),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // MANGA ACTIVA BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "MANGA ACTIVA",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Title
                  const Text(
                    "¿Lote listo para calificar?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.5,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Inicia evaluación EPMURAS en manga",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Checklist Items
                  Row(
                    children: const [
                      Icon(Icons.check, color: Color(0xFF4ADE80), size: 15),
                      SizedBox(width: 6),
                      Text(
                        "Calificación lineal rápida (1 al 6)",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.check, color: Color(0xFF4ADE80), size: 15),
                      SizedBox(width: 6),
                      Text(
                        "Captura offline & RFID simultáneo",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/epmuras'),
                        icon: const Icon(
                          Icons.add_rounded,
                          color: Color(0xFF235C3F),
                          size: 16,
                        ),
                        label: const Text(
                          "Iniciar Manga",
                          style: TextStyle(
                            color: Color(0xFF235C3F),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/epmuras'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.6),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "Programar Lote",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12.5,
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
    );
  }

  // Top Banner Carousel Widget
  Widget _buildTopBannerCarousel() {
    final totalPages = 1 + _topEvaluations.length;
    return SizedBox(
      height: 250,
      child: PageView.builder(
        controller: _bannerPageController,
        onPageChanged: (index) {
          setState(() {
            _bannerIndex = index;
          });
        },
        itemCount: totalPages,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeroBanner();
          } else {
            final evalData = _topEvaluations[index - 1];
            return _buildEvaluationBannerCard(evalData, index);
          }
        },
      ),
    );
  }

  // Evaluation Card for Top Scroll Banner
  Widget _buildEvaluationBannerCard(Map<String, dynamic> data, int cardIndex) {
    final animalNum = data['numero'] ?? data['arete'] ?? 'S/N';
    final hacienda = data['hacienda'] ?? data['unidad_produccion'] ?? 'Finca sin asignar';
    final propietario = data['propietario'] ?? data['nombre_propietario'] ?? '';
    final raza = data['raza'] ?? data['sexo'] ?? 'Ejemplar Evaluado';
    final imageBase64 = data['image_base64'];
    final imageAsset = data['image'];
    final badgeText = data['badge'] ?? data['estado_animal'] ?? 'Evaluación #$cardIndex';

    String locationOwnerText = hacienda.toString();
    if (propietario.toString().trim().isNotEmpty && propietario.toString() != hacienda.toString()) {
      locationOwnerText = "$hacienda • $propietario";
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF235C3F).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Image or Gradient
            Positioned.fill(
              child: _buildCardBackground(imageBase64, imageAsset),
            ),

            // Gradient Overlay for Text Readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.82),
                      Colors.black.withOpacity(0.40),
                      Colors.black.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Graphic Decoration Watermark
            Positioned.fill(
              child: CustomPaint(
                painter: HeroWatermarkPainter(),
              ),
            ),

            // Superimposed Text & Details
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Header Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF235C3F).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4ADE80),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "ÚLTIMA EVALUACIÓN $cardIndex",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          badgeText.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Center Superimposed Text: Animal # & Farm / Owner
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4ADE80).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Color(0xFF4ADE80),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Animal N° $animalNum",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFF93C5FD),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              locationOwnerText,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Bottom Bar: Breed/Sex + Ver Ficha Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        raza.toString(),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/consulta_animal'),
                        icon: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF235C3F),
                          size: 14,
                        ),
                        label: const Text(
                          "Ver Ficha",
                          style: TextStyle(
                            color: Color(0xFF235C3F),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBackground(dynamic imageBase64, dynamic imageAsset) {
    if (imageBase64 != null && imageBase64.toString().isNotEmpty) {
      try {
        final bytes = base64Decode(imageBase64.toString());
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    if (imageAsset != null && imageAsset.toString().isNotEmpty) {
      return Image.asset(
        imageAsset.toString(),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultCardGradient(),
      );
    }
    return _defaultCardGradient();
  }

  Widget _defaultCardGradient() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF235C3F),
            Color(0xFF132A1F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  // Carousel Dots Widget
  Widget _buildCarouselDots() {
    final totalPages = 1 + _topEvaluations.length;
    if (totalPages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == _bannerIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF235C3F) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // Section Header Widget
  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    required String actionText,
    required VoidCallback onActionTap,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF192A20),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ],
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF235C3F),
            ),
          ),
        ),
      ],
    );
  }

  // Módulos Grid Widget
  Widget _buildModulosGrid() {
    final List<Map<String, dynamic>> modulos = [
      {
        'title': 'EPMURAS',
        'icon': Icons.verified_user_outlined,
        'route': '/epmuras',
      },
      {
        'title': 'Consulta',
        'icon': Icons.local_offer_outlined,
        'route': '/consulta',
      },
      {
        'title': 'Índices',
        'icon': Icons.assignment_turned_in_outlined,
        'route': '/index',
      },
      {
        'title': 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'route': '/stats',
      },
      {
        'title': 'Bases Teóricas',
        'icon': Icons.menu_book_outlined,
        'route': '/theory',
      },
      {
        'title': 'Análisis',
        'icon': Icons.analytics_outlined,
        'route': '/consulta_finca',
      },
      {
        'title': 'Más Servicios',
        'icon': Icons.grid_view_rounded,
        'route': '/settings',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: modulos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final item = modulos[index];
        return _buildModuloCard(
          title: item['title'],
          icon: item['icon'],
          onTap: () => Navigator.pushNamed(context, item['route']),
        );
      },
    );
  }

  Widget _buildModuloCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF235C3F),
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF192A20),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Evaluaciones Carousel Widget
  Widget _buildEvaluacionesCarousel() {
    if (_topEvaluations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Image.asset(
              'assets/icons/logo1.png',
              width: 56,
              height: 56,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 10),
            const Text(
              "No hay evaluaciones registradas.",
              style: TextStyle(
                color: Color(0xFF192A20),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Inicia una sesión en el módulo EPMURAS para calificar animales.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 385,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _topEvaluations.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final data = _topEvaluations[index];
          return _buildEvaluationCard(data);
        },
      ),
    );
  }

  Widget _buildEvaluationCard(Map<String, dynamic> data) {
    final rawScores = data['epmuras'] ?? data['scores'];
    final Map<String, int> scores = {};
    if (rawScores is Map) {
      rawScores.forEach((k, v) {
        scores[k.toString()] = int.tryParse(v.toString()) ?? (double.tryParse(v.toString())?.toInt() ?? 5);
      });
    }
    if (scores.isEmpty) {
      scores.addAll({'E': 5, 'P': 5, 'M': 5, 'U': 5, 'R': 5, 'A': 5, 'S': 5});
    }

    final animalNum = data['numero'] ?? data['arete'] ?? 'S/N';
    final title = "Ejemplar #$animalNum";
    final raza = data['raza'] ?? data['sexo'] ?? 'Bovino';
    final subtitle = "$raza • ${data['hacienda'] ?? ''}";
    final badgeText = data['badge'] ?? data['estado_animal'] ?? 'Evaluado';
    final badgeColor = data['badgeColor'] ?? const Color(0xFF0D9488);
    final rfid = data['rfid'] ?? 'S/R';
    final status = data['status'] ?? data['estado_animal'] ?? 'Registrado';
    final image = data['image'];

    return Container(
      width: 275,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Overlays
            Stack(
              children: [
                image != null
                    ? Image.asset(
                        image.toString(),
                        height: 135,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 135,
                          color: const Color(0xFFE2E8F0),
                          child: Center(
                            child: Image.asset('assets/icons/logo1.png', width: 44, height: 44),
                          ),
                        ),
                      )
                    : Container(
                        height: 135,
                        width: double.infinity,
                        color: const Color(0xFFE2EFE7),
                        child: Center(
                          child: Image.asset('assets/icons/logo1.png', width: 44, height: 44),
                        ),
                      ),
                // Badge Top Left
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Badge Bottom Right (RFID)
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "RFID: $rfid",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF192A20),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          status.toString(),
                          style: const TextStyle(
                            color: Color(0xFF15803D),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Subtitle
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // PUNTAJE LINEAL Header
                  const Text(
                    "PUNTAJE LINEAL (1-6)",
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // EPMURAS score grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: scores.entries.map((e) {
                      return Container(
                        width: 31,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${e.value}",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Ver Ficha Button
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/consulta_animal',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF235C3F),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Ver Ficha",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bottom Navigation Bar Widget
  Widget _buildBottomNavBar() {
    return const CustomBottomNavBar(currentIndex: 0);
  }
}

// Custom Painter for Watermark on Hero Banner
class HeroWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    final center = Offset(size.width * 0.9, size.height * 0.45);

    // Draw concentric ring graphics
    canvas.drawCircle(center, 45, paint);
    canvas.drawCircle(center, 75, paint);
    canvas.drawCircle(center, 105, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
