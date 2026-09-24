import 'package:flutter/material.dart';

class MainMenu extends StatelessWidget {
  Widget buildDashboardButton({
    required BuildContext context,
    required String label,
    required String subtext,
    required String imagePath,
    required String route,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalMargin = screenWidth * 0.08; // 8% a cada lado
    final buttonHeight = screenWidth * 0.35; // 35% del ancho

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(
          vertical: 15,
          horizontal: horizontalMargin,
        ),
        height: buttonHeight,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(imagePath),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 10,
              spreadRadius: 1,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtext,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final headerHeight = screenWidth * 0.16;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/icons/fondo6.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: headerHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF009FE3),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: headerHeight * 0.15),
                  child: Image.asset(
                    'assets/icons/logoapp5.png',
                    fit: BoxFit.contain,
                    height: headerHeight * 0.7,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    buildDashboardButton(
                      context: context,
                      label: 'Epmuras',
                      subtext: 'AquÃ­ puedes iniciar sesiÃ³n en las Epmuras',
                      imagePath: 'assets/img/boton_epmuras.jpg',
                      route: '/epmuras',
                    ),
                    buildDashboardButton(
                      context: context,
                      label: 'Consulta',
                      subtext: 'Consulta todo sobre las Epmuras',
                      imagePath: 'assets/img/boton_consulta.jpg',
                      route: '/consulta',
                    ),
                    buildDashboardButton(
                      context: context,
                      label: 'Ãndice',
                      subtext: 'Consulta los Ã­ndices disponibles',
                      imagePath: 'assets/img/boton_indice.jpg',
                      route: '/index',
                    ),
                    buildDashboardButton(
                      context: context,
                      label: 'EstadÃ­sticas',
                      subtext: 'Visualiza el desempeÃ±o de las evaluaciones',
                      imagePath: 'assets/img/boton_estadisticas.jpg',
                      route: '/stats',
                    ),
                    buildDashboardButton(
                      context: context,
                      label: 'Bases TeÃ³ricas',
                      subtext: 'Lee las bases cientÃ­ficas',
                      imagePath: 'assets/img/boton_basesteoricas.jpg',
                      route: '/theory',
                    ),
                    buildDashboardButton(
                      context: context,
                      label: 'Noticias',
                      subtext: 'Ãšltimos eventos e informaciÃ³n',
                      imagePath: 'assets/img/boton_noticias.jpg',
                      route: '/news_public',
                    ),
                    buildDashboardButton(
                      context: context,
                      label: 'ConfiguraciÃ³n',
                      subtext: 'Ajustes y preferencias de la aplicaciÃ³n',
                      imagePath: 'assets/img/boton_publicar.png',
                      route: '/settings',
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



