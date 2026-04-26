import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import 'ciudadano_home_screen.dart';
import 'reportar_screen.dart';
import 'consultar_screen.dart';
import 'mapa_screen.dart';
import 'informacion_screen.dart';

class CiudadanoDrawer extends StatelessWidget {
  final int currentIndex;

  const CiudadanoDrawer({
    super.key,
    required this.currentIndex,
  });

  static Widget? maybe(
    BuildContext context, {
    required int currentIndex,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile) return null;

    return CiudadanoDrawer(currentIndex: currentIndex);
  }

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);

    if (index == currentIndex) return;

    late final Widget screen;

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
    return Drawer(
      child: Container(
        color: AppConfig.azulOscuro,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppConfig.azulOscuro,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.route_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ruta Sin Obstáculos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Portal ciudadano',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.home_rounded,
              title: 'Inicio',
              selected: currentIndex == 0,
              onTap: () => _navigate(context, 0),
            ),
            _DrawerItem(
              icon: Icons.add_location_alt_rounded,
              title: 'Reportar invasión',
              selected: currentIndex == 1,
              onTap: () => _navigate(context, 1),
            ),
            _DrawerItem(
              icon: Icons.search_rounded,
              title: 'Consultar estado',
              selected: currentIndex == 2,
              onTap: () => _navigate(context, 2),
            ),
            _DrawerItem(
              icon: Icons.map_rounded,
              title: 'Mapa de reportes',
              selected: currentIndex == 3,
              onTap: () => _navigate(context, 3),
            ),
            _DrawerItem(
              icon: Icons.info_rounded,
              title: 'Información',
              selected: currentIndex == 4,
              onTap: () => _navigate(context, 4),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppConfig.azulClaro),
            ),
            _DrawerItem(
              icon: Icons.arrow_back_rounded,
              title: 'Volver a selección de roles',
              selected: false,
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedTileColor: Colors.white.withOpacity(0.08),
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}