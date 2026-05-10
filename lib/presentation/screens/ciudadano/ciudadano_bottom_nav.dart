import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import 'ciudadano_home_screen.dart';
import 'reportar_screen.dart';
import 'consultar_screen.dart';
import 'mapa_screen.dart';
import 'informacion_screen.dart';

class CiudadanoBottomNav extends StatelessWidget {
  final int currentIndex;

  const CiudadanoBottomNav({
    super.key,
    required this.currentIndex,
  });

  static Widget? maybe(
    BuildContext context, {
    required int currentIndex,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    if (!isMobile) return null;
    return CiudadanoBottomNav(currentIndex: currentIndex);
  }

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget screen;
    switch (index) {
      case 0:
        screen = const CiudadanoHomeScreen();
        break;
      case 1:
        screen = const ReportarScreen();
        break;
      case 2:
        screen = const ConsultarScreen();
        break;
      case 3:
        screen = const MapaScreen();
        break;
      case 4:
        screen = const InformacionScreen();
        break;
      default:
        screen = const CiudadanoHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Solo mostramos 5 ítems en el bottom nav.
    // El perfil va en el AppBar (actions) en todas las pantallas.
    final displayIndex = currentIndex > 4 ? 0 : currentIndex;

    return NavigationBar(
      selectedIndex: displayIndex,
      onDestinationSelected: (index) => _navigate(context, index),
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppConfig.azulClaro.withOpacity(0.14),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.add_location_alt_outlined),
          selectedIcon: Icon(Icons.add_location_alt_rounded),
          label: 'Reportar',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search_rounded),
          label: 'Consultar',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map_rounded),
          label: 'Mapa',
        ),
        NavigationDestination(
          icon: Icon(Icons.info_outline_rounded),
          selectedIcon: Icon(Icons.info_rounded),
          label: 'Info',
        ),
      ],
    );
  }
}