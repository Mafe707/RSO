import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_home_screen.dart';
import 'ciudadano_login_screen.dart';
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
    // índice 5 = cerrar sesión
    if (index == 5) {
      _logout(context);
      return;
    }
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

  Future<void> _logout(BuildContext context) async {
    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
    await svc.logout();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const CiudadanoLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        NavigationDestination(
          icon: Icon(Icons.logout_rounded, color: AppConfig.rojo),
          selectedIcon: Icon(Icons.logout_rounded, color: AppConfig.rojo),
          label: 'Salir',
        ),
      ],
    );
  }
}