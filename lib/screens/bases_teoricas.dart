import 'package:flutter/material.dart';
import '../widgets/custom_bottom_nav_bar.dart';

typedef BasesTeoricasScreen = EpmurasInfographic;

class EpmurasInfographic extends StatefulWidget {
  const EpmurasInfographic({super.key});

  @override
  State<EpmurasInfographic> createState() => _EpmurasInfographicState();
}

class _EpmurasInfographicState extends State<EpmurasInfographic> {
  int _selectedFilterIndex = 0;

  // Estado de acordeones de criterios EPMURAS (primer criterio expandido por defecto)
  final Map<String, bool> _expandedCriteria = {
    'E': true,
    'P': false,
    'M': false,
    'U': false,
    'R': false,
    'A': false,
    'S': false,
  };

  final List<String> _filterTabs = const [
    'Todos (7)',
    'E • Estructura',
    'P • Precocidad',
    'M • Musculatura',
    'U • Ombligo',
    'R • Raza',
    'A • Aplomos',
    'S • Sexualidad',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FCF4),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOfficialBadge(),
              const SizedBox(height: 14),
              _buildFundamentacionCard(),
              const SizedBox(height: 16),
              _buildBiometricMappingCard(),
              const SizedBox(height: 16),
              _buildFilterChips(),
              const SizedBox(height: 16),
              _buildCriteriaAccordions(),
              const SizedBox(height: 20),
              _buildMatrizZootecnicaCard(),
              const SizedBox(height: 20),
              _buildConclusionesCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF2FCF4),
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF1B4332)),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bases Teóricas EPMURAS',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
              letterSpacing: -0.2,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'Selección Fenotípica Lineal • Zootecnia',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF40916C),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Audio Guía',
          icon: const Icon(Icons.volume_up_outlined, color: Color(0xFF1B4332), size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Reproduciendo resumen auditivo de criterios EPMURAS'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          tooltip: 'Buscar Criterio',
          icon: const Icon(Icons.search, color: Color(0xFF1B4332), size: 22),
          onPressed: () {},
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildOfficialBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2D6A4F),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Guía Zootécnica Oficial Boviframe',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2D6A4F),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD8E7DC)),
          ),
          child: const Text(
            'Escala Lineal 1 al 6',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1B4332),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFundamentacionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFE7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B4332),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.auto_stories_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'FUNDAMENTACIÓN CIENTÍFICA',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF2D6A4F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '¿Qué es la Metodología EPMURAS?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF4B5563),
                fontFamily: 'Plus Jakarta Sans',
              ),
              children: [
                TextSpan(
                  text: 'Es una técnica sistemática de ',
                ),
                TextSpan(
                  text: 'clasificación lineal visual',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                  ),
                ),
                TextSpan(
                  text:
                      ' diseñada para estimar la composición corporal y funcionalidad biológica en bovinos para carne. Correlaciona matemáticamente la conformación física con ',
                ),
                TextSpan(
                  text: 'fertilidad, precocidad sexual y rendimiento de carcasa',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B4332),
                  ),
                ),
                TextSpan(
                  text: ' en pastoreo extensivo.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.track_changes,
                  title: 'Objetiva',
                  subtitle: 'Repetibilidad en manga',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.show_chart_rounded,
                  title: 'Alta Hered.',
                  subtitle: 'Correlación con DEPs',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.timer_outlined,
                  title: 'Velocidad',
                  subtitle: '60s por ejemplar',
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FCF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E7DC)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2D6A4F), size: 20),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricMappingCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF153326),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.architecture_rounded, color: Color(0xFF74C69D), size: 20),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MAPEO BIOMÉTRICO EN MANGA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Vectores de evaluación en toro Nelore / Cebuino',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Color(0xFFB7E4C7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ref. 3D',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD8F3DC),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Stack(
            children: [
              ClipRRect(
                child: Image.asset(
                  'assets/img/Fondo_inicio.jpg',
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, st) => Container(
                    height: 220,
                    color: const Color(0xFF2D6A4F),
                    child: Center(
                      child: Image.asset(
                        'assets/icons/logo1.png',
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.22),
                  child: CustomPaint(
                    painter: _BiometricVectorPainter(),
                  ),
                ),
              ),

              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    children: [
                      Text('• E : Estructura', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Text('• P : Precocidad', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                      SizedBox(width: 8),
                      Text('• M : Masa', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4332).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF52B788)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fullscreen, color: Colors.white, size: 15),
                      SizedBox(width: 4),
                      Text(
                        'Ver',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF10271D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFieldCondition(Icons.timer_outlined, '45–90 seg/animal'),
                _buildFieldCondition(Icons.sync_alt, 'Distancia: 3 a 5 m'),
                _buildFieldCondition(Icons.wb_sunny_outlined, 'Luz natural lateral'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCondition(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF74C69D), size: 14),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFD8F3DC),
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filterTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == _selectedFilterIndex;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1B4332) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF1B4332) : const Color(0xFFD8E7DC),
                ),
              ),
              child: Text(
                _filterTabs[index],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF2D6A4F),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCriteriaAccordions() {
    return Column(
      children: [
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1)
          _buildAccordionItem(
            code: 'E',
            name: 'Estructura Corporal',
            weight: '17.5% Ponderación',
            summary: 'Longitud, alzada, perímetro torácico y arqueo de costillas.',
            avatarColor: const Color(0xFF2563EB),
            weightBg: const Color(0xFFEFF6FF),
            weightColor: const Color(0xFF1D4ED8),
            content: _buildEstructuraContent(),
          ),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1)
          const SizedBox(height: 12),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2)
          _buildAccordionItem(
            code: 'P',
            name: 'Precocidad de Terminación',
            weight: '20% Ponderación',
            summary: 'Relación profundidad de costilla / longitud de miembros.',
            avatarColor: const Color(0xFF10B981),
            weightBg: const Color(0xFFECFDF5),
            weightColor: const Color(0xFF047857),
            content: _buildPrecocidadContent(),
          ),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 2)
          const SizedBox(height: 12),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3)
          _buildAccordionItem(
            code: 'M',
            name: 'Musculatura y Espesor',
            weight: '20% Ponderación',
            summary: 'Volumen, convexidad de cuarto trasero y lomo (AOB).',
            avatarColor: const Color(0xFFD97706),
            weightBg: const Color(0xFFFFFBEB),
            weightColor: const Color(0xFFB45309),
            content: _buildSimpleCriterionDetail(
              'Evalúa la masa cárnica observable a golpe de vista. Se observa el ancho entre isquiones, la curvatura exterior de la pierna y el relleno del lomo sobre la espina dorsal.',
              'Buscamos cuartos convexos con inserciones musculares bajas y firmes que maximicen el rendimiento de cortes nobles.',
            ),
          ),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 3)
          const SizedBox(height: 12),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 4)
          _buildAccordionItem(
            code: 'U',
            name: 'Ombligo y Prepucio',
            weight: '12.5% Ponderación',
            summary: 'Tamaño, ángulo de inserción (45°) y riesgo de acropostitis.',
            avatarColor: const Color(0xFF7C3AED),
            weightBg: const Color(0xFFF5F3FF),
            weightColor: const Color(0xFF6D28D9),
            content: _buildSimpleCriterionDetail(
              'Conformación y dirección del orificio prepucial. Fundamental en pastizales toscos y monte espinoso.',
              'Prepucio pegado a la línea ventral, ángulo cercano a 45 grados. Prohibido prepucios péndulos por debajo de los tarsos.',
            ),
          ),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 4)
          const SizedBox(height: 12),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 5)
          _buildAccordionItem(
            code: 'R',
            name: 'Raza (Pureza Estándar)',
            weight: '10% Ponderación',
            summary: 'Cabeza, orejas, giba, pelaje y pigmentación según patrón.',
            avatarColor: const Color(0xFF0D9488),
            weightBg: const Color(0xFFF0FDFA),
            weightColor: const Color(0xFF0F766E),
            content: _buildSimpleCriterionDetail(
              'Expresión morfológica racial del ejemplar (Cebuino/Brahman/Nelore). Armonía general, colocación y fijación de giba.',
              'Mucosas pigmentadas, cabeza simétrica, aplomo y características sexuales secundarias marcadas.',
            ),
          ),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 5)
          const SizedBox(height: 12),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 6)
          _buildAccordionItem(
            code: 'A',
            name: 'Aplomos y Sustentación',
            weight: '10% Ponderación',
            summary: 'Articulaciones, cuartillas, talones y pezuñas funcionales.',
            avatarColor: const Color(0xFF0284C7),
            weightBg: const Color(0xFFF0F9FF),
            weightColor: const Color(0xFF0369A1),
            content: _buildSimpleCriterionDetail(
              'Capacidad de locomoción y desplazamiento en pastoreo extensivo. Ángulos de corvejón y cuartilla.',
              'Pezuñas cerradas y simétricas, talones altos. Cero tolerancia a pezuñas en tijera o sobrepaletas desviadas.',
            ),
          ),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 6)
          const SizedBox(height: 12),
        if (_selectedFilterIndex == 0 || _selectedFilterIndex == 7)
          _buildAccordionItem(
            code: 'S',
            name: 'Sexualidad y Vigor Reproductivo',
            weight: '10% Ponderación',
            summary: 'Simetría testicular en toros, feminidad y ubre en hembras.',
            avatarColor: const Color(0xFFE11D48),
            weightBg: const Color(0xFFFFF1F2),
            weightColor: const Color(0xFFBE123C),
            content: _buildSimpleCriterionDetail(
              'En machos: circunferencia escrotal, forma de cuello escrotal y simetría testicular. En hembras: finura en cabeza y cuello, ubre bien implantada.',
              'Alta correlación con la edad al primer parto en las hijas y la concentración espermática en toros.',
            ),
          ),
      ],
    );
  }

  Widget _buildAccordionItem({
    required String code,
    required String name,
    required String weight,
    required String summary,
    required Color avatarColor,
    required Color weightBg,
    required Color weightColor,
    required Widget content,
  }) {
    final isExpanded = _expandedCriteria[code] ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? const Color(0xFF52B788) : const Color(0xFFE5E7EB),
          width: isExpanded ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _expandedCriteria[code] = !isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1B4332),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: weightBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                weight,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: weightColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: const Color(0xFF9CA3AF),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 12),
                  content,
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEstructuraContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 60,
                height: 60,
                color: const Color(0xFFE2F3E7),
                child: const Icon(Icons.fitness_center_outlined, color: Color(0xFF1B4332), size: 28),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capacidad Ruminal y Biotipo:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1B4332),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Evalúa el volumen total de la caja torácica. Animales con mayor arqueo de costillas metabolizan forrajes toscos con mayor eficiencia.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF4B5563),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildScoreScaleBox(
                range: 'Nota 1 – 2',
                description: 'Costilla plana, pecho angosto, poca capacidad.',
                bgColor: const Color(0xFFFFF1F2),
                borderColor: const Color(0xFFFECDD3),
                textColor: const Color(0xFFBE123C),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildScoreScaleBox(
                range: 'Nota 3 – 4',
                description: 'Mediano porte, arqueo intermedio funcional.',
                bgColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
                textColor: const Color(0xFFB45309),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _buildScoreScaleBox(
                range: 'Nota 5 – 6',
                description: 'Excelente profundidad y arco costal amplio.',
                bgColor: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
                textColor: const Color(0xFF047857),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildGoldenRule(
          'Regla de oro: Se busca un tórax profundo en forma de barril, sin exagerar la altura a la cruz (evitar animales zancudos desproporcionados).',
        ),
      ],
    );
  }

  Widget _buildPrecocidadContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profundidad de costilla en relación a la longitud de miembros anteriores y posteriores.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildScoreScaleBox(
                range: 'Nota 1–2 (Tardío)',
                description: 'Miembros muy largos, costilla corta. Requiere más tiempo en ceba.',
                bgColor: const Color(0xFFFFF1F2),
                borderColor: const Color(0xFFFECDD3),
                textColor: const Color(0xFFBE123C),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildScoreScaleBox(
                range: 'Nota 5–6 (Precoz)',
                description: 'Tórax desciende por debajo del codo. Engrasamiento a pasto rápido.',
                bgColor: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
                textColor: const Color(0xFF047857),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildGoldenRule(
          'La precocidad reduce los días para el sacrificio y anticipa la pubertad en novillas.',
        ),
      ],
    );
  }

  Widget _buildSimpleCriterionDetail(String explanation, String idealStandard) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          explanation,
          style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), height: 1.4),
        ),
        const SizedBox(height: 8),
        _buildGoldenRule(idealStandard),
      ],
    );
  }

  Widget _buildScoreScaleBox({
    required String range,
    required String description,
    required Color bgColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            range,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 9.5,
              color: textColor.withValues(alpha: 0.9),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldenRule(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB7E4C7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: Color(0xFF2D6A4F), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4332),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatrizZootecnicaCard() {
    final List<Map<String, String>> matrixData = const [
      {'crit': '(E) Estructura', 'rej': '0', 'scale': '1  2  3  4  5  6'},
      {'crit': '(P) Precocidad', 'rej': '0', 'scale': '1  2  3  4  5  6'},
      {'crit': '(M) Musculatura', 'rej': '0', 'scale': '1  2  3  4  5  6'},
      {'crit': '(U) Ombligo', 'rej': '0', 'scale': '1  2  3  4  5  6'},
      {'crit': '(R) Carácter Racial', 'rej': '0', 'scale': '1  2  3  4  5  6'},
      {'crit': '(A) Aplomos', 'rej': '0', 'scale': '1  2  3  4  5  6'},
      {'crit': '(S) Sexualidad', 'rej': '0', 'scale': '1  2  3  4'},
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
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
                  Icon(Icons.table_chart_outlined, color: Color(0xFF1B4332), size: 20),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matriz Zootécnica y Descalificación',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1B4332),
                        ),
                      ),
                      Text(
                        'Criterio estandarizado de calificación lineal',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Oficial ANC',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1: Subóptimo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                    Text('3–4: Promedio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                    Text('6: Élite Superior', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFF59E0B),
                          Color(0xFF10B981),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Toda calificación se efectúa de forma relativa dentro del mismo grupo contemporáneo (mismo manejo y edad).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B7280),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFF1B4332),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            'CARACTERÍSTICA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'RECHAZO (0)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'ESCALA VÁLIDA',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: matrixData.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    itemBuilder: (context, idx) {
                      final item = matrixData[idx];
                      return Container(
                        color: idx.isEven ? Colors.white : const Color(0xFFFBFDFB),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                item['crit']!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item['rej']!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                item['scale']!,
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B4332),
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Motivos de Calificación Cero (0) / Descarte Inmediato:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('Prognatismo / Braquignatismo:', 'Desvío maxilar grave que impide pastoreo.'),
                _buildBulletPoint('Anomalías genitales:', 'Monorquidia, criptorquidia, hipoplasia testicular severa.'),
                _buildBulletPoint('Pezuñas en tirabuzón o tijera:', 'Con aplomos no funcionales.'),
                _buildBulletPoint('Prepucio exageradamente péndulo (U = 0):', 'Vaina por debajo de la línea del tarso.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String boldPrefix, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFDC2626), fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF7F1D1D),
                  fontFamily: 'Plus Jakarta Sans',
                  height: 1.3,
                ),
                children: [
                  TextSpan(
                    text: '$boldPrefix ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConclusionesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFE7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D6A4F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.workspace_premium_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Conclusiones Zootécnicas Boviframe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B4332),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/icons/conclusiones2.png',
              height: 130,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(
                height: 130,
                color: const Color(0xFFE2F3E7),
                child: Center(
                  child: Image.asset(
                    'assets/icons/logo1.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4B5563),
                height: 1.5,
                fontFamily: 'Plus Jakarta Sans',
              ),
              children: [
                TextSpan(
                  text: 'La técnica ',
                ),
                TextSpan(
                  text: 'EPMURAS',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                ),
                TextSpan(
                  text:
                      ' optimiza la selección en el campo sin requerir pesajes continuos, reduciendo hasta un ',
                ),
                TextSpan(
                  text: '15% la edad al primer parto',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                ),
                TextSpan(
                  text: ' en novillas y aumentando la ganancia media diaria (',
                ),
                TextSpan(
                  text: 'GMD',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1B4332)),
                ),
                TextSpan(
                  text:
                      ') en novillos de engorde gracias al equilibrio funcional entre capacidad biológica y precocidad.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botón Primario: Comenzar Evaluación
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/epmuras');
              },
              icon: const Icon(Icons.fact_check_outlined, color: Colors.white, size: 20),
              label: const Text(
                'Comenzar Evaluación en Manga',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Botón Secundario: Descargar PDF
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Descargando Manual Zootécnico Oficial Boviframe (PDF)'),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF1B4332), size: 18),
              label: const Text(
                'Descargar Manual Zootécnico (PDF)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B4332),
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD8E7DC), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter para dibujar los vectores morfométricos (E, P, M) sobre el ejemplar
class _BiometricVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dashedPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vector E - Estructura (Longitudinal y Profundidad)
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.60),
      Offset(size.width * 0.80, size.height * 0.60),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.40),
      Offset(size.width * 0.52, size.height * 0.75),
      linePaint,
    );

    // Vector P - Precocidad (Altura cruz a codo y despeje de suelo)
    canvas.drawLine(
      Offset(size.width * 0.64, size.height * 0.35),
      Offset(size.width * 0.64, size.height * 0.88),
      linePaint,
    );

    // Rectángulo guía de caja torácica
    final rect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.38,
      size.width * 0.64,
      size.height * 0.45,
    );
    canvas.drawRect(rect, dashedPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
