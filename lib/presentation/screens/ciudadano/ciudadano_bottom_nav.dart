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
import 'ciudadano_perfil_screen.dart';

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
    // índice 5 = menú más
    if (index == 5) {
      _mostrarMas(context);
      return;
    }

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

  void _goPerfil(BuildContext context) {
    Navigator.pop(context);

    if (currentIndex == 5) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CiudadanoPerfilScreen()),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const CiudadanoPerfilScreen()),
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

  void _mostrarMas(BuildContext context) {
    final svc = Provider.of<CiudadanoAuthService>(context, listen: false);

    final nombre = svc.ciudadanoData?['nombre']?.toString() ?? '';
    final apellido = svc.ciudadanoData?['apellido']?.toString() ?? '';
    final correo = svc.ciudadanoData?['correo']?.toString() ?? '';
    final fotoUrl = svc.ciudadanoData?['foto_url']?.toString();

    final inicial = nombre.trim().isNotEmpty ? nombre.trim()[0].toUpperCase() : 'C';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppConfig.grisMedio,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Row(
                    children: [
                      if (fotoUrl != null && fotoUrl.isNotEmpty)
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(fotoUrl),
                          onBackgroundImageError: (_, __) {},
                        )
                      else
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppConfig.azulOscuro.withOpacity(0.10),
                          child: Text(
                            inicial,
                            style: const TextStyle(
                              color: AppConfig.azulOscuro,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre.isNotEmpty ? '$nombre $apellido' : 'Ciudadano',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (correo.isNotEmpty)
                              Text(
                                correo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConfig.grisOscuro.withOpacity(0.85),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _MoreItem(
                    icon: Icons.person_rounded,
                    title: 'Mi perfil',
                    subtitle: 'Ver y editar tus datos',
                    color: AppConfig.azulClaro,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CiudadanoPerfilScreen(),
                        ),
                      );
                    },
                  ),
                  _MoreItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar sesión',
                    subtitle: 'Salir de tu cuenta actual',
                    color: AppConfig.rojo,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _logout(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayIndex = currentIndex >= 0 && currentIndex <= 5 ? currentIndex : 0;

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
          icon: Icon(Icons.more_horiz_rounded),
          selectedIcon: Icon(Icons.more_horiz_rounded),
          label: 'Más',
        ),
      ],
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppConfig.azulOscuro,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: AppConfig.grisOscuro.withOpacity(0.85),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppConfig.azulOscuro,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}