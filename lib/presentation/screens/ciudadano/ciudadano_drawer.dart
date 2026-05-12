import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_login_screen.dart';

import '../../../config/app_config.dart';
import 'ciudadano_home_screen.dart';
import 'reportar_screen.dart';
import 'consultar_screen.dart';
import 'mapa_screen.dart';
import 'informacion_screen.dart';
import 'ciudadano_perfil_screen.dart';

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

      case 5:
        screen = const CiudadanoPerfilScreen();
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
    final svc = Provider.of<CiudadanoAuthService>(
      context,
      listen: false,
    );

    final nombre = svc.ciudadanoData?['nombre'] ?? '';
    final apellido = svc.ciudadanoData?['apellido'] ?? '';
    final correo = svc.ciudadanoData?['correo'] ?? '';

    final inicial =
        nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';

    return Drawer(
      child: Container(
        color: AppConfig.azulOscuro,
        child: Column(
          children: [
            // ───────────────── HEADER ─────────────────
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 20,
                right: 20,
                bottom: 22,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar + datos
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            Colors.white.withOpacity(0.18),
                        child: Text(
                          inicial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (nombre.isNotEmpty)
                              Text(
                                '$nombre $apellido',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            else
                              Text(
                                'Portal ciudadano',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.75),
                                  fontSize: 13,
                                ),
                              ),

                            const SizedBox(height: 2),

                            if (correo.isNotEmpty)
                              Text(
                                correo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      Colors.white.withOpacity(0.60),
                                  fontSize: 11.5,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    'Ruta Sin Obstáculos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(
              color: Colors.white12,
              height: 1,
            ),

            // ───────────────── MENÚ ─────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 10),
                children: [
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

                  // PERFIL AHORA ARRIBA DE LA RAYA
                  _DrawerItem(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Mi perfil',
                    selected: currentIndex == 5,
                    onTap: () => _navigate(context, 5),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Divider(color: Colors.white12),
                  ),

                  // CERRAR SESIÓN ROJO
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar sesión',
                    color: Colors.redAccent,
                    selected: false,
                    onTap: () async {
                      Navigator.pop(context);

                      await svc.logout();

                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const CiudadanoLoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
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
  final Color? color;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor =
        color ??
        (selected ? Colors.white : Colors.white70);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),
      child: ListTile(
        selected: selected,
        selectedTileColor:
            Colors.white.withOpacity(0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),

        leading: Icon(
          icon,
          color: itemColor,
          size: 22,
        ),

        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontWeight:
                selected
                    ? FontWeight.w800
                    : FontWeight.w600,
            fontSize: 14,
          ),
        ),

        onTap: onTap,
      ),
    );
  }
}