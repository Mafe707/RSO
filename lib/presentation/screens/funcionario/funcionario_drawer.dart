import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';

import 'funcionario_home_screen.dart';
import 'mis_casos_screen.dart';
import 'nuevos_reportes_screen.dart';
import 'mapa_casos_screen.dart';
import 'mi_perfil_screen.dart';
import 'login_screen.dart';

class FuncionarioDrawer extends StatelessWidget {
  final int currentIndex;
  final Map<String, dynamic> userData;

  const FuncionarioDrawer({
    super.key,
    required this.currentIndex,
    required this.userData,
  });

  static Widget? maybe(
    BuildContext context, {
    required int currentIndex,
    required Map<String, dynamic> userData,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 780;

    if (isMobile) return null;

    return FuncionarioDrawer(
      currentIndex: currentIndex,
      userData: userData,
    );
  }

  void _navigate(BuildContext context, int index) {
    Navigator.pop(context);

    if (index == currentIndex) return;

    late final Widget screen;

    switch (index) {
      case 0:
        screen = const FuncionarioHomeScreen();
        break;
      case 1:
        screen = MisCasosScreen(userData: userData);
        break;
      case 2:
        screen = NuevosReportesScreen(userData: userData);
        break;
      case 3:
        screen = const MapaCasosScreen();
        break;
      case 4:
        screen = MiPerfilScreen(userData: userData);
        break;
      default:
        screen = const FuncionarioHomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Future<void> _logout(BuildContext context) async {
  final authService = Provider.of<AuthService>(context, listen: false);
  await authService.logout();
  if (context.mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const FuncionarioLoginScreen()),
      (route) => false,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final userName = userData['nombre']?.toString() ?? 'Funcionario';
    final userEmail = userData['correo']?.toString() ?? '';

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
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppConfig.azulClaro,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'F',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.74),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _DrawerItem(
              icon: Icons.dashboard_rounded,
              title: 'Inicio',
              selected: currentIndex == 0,
              onTap: () => _navigate(context, 0),
            ),
            _DrawerItem(
              icon: Icons.assignment_rounded,
              title: 'Mis casos',
              selected: currentIndex == 1,
              onTap: () => _navigate(context, 1),
            ),
            _DrawerItem(
              icon: Icons.flag_rounded,
              title: 'Nuevos reportes',
              selected: currentIndex == 2,
              onTap: () => _navigate(context, 2),
            ),
            _DrawerItem(
              icon: Icons.map_rounded,
              title: 'Mapa de casos',
              selected: currentIndex == 3,
              onTap: () => _navigate(context, 3),
            ),
            _DrawerItem(
              icon: Icons.person_rounded,
              title: 'Mi perfil',
              selected: currentIndex == 4,
              onTap: () => _navigate(context, 4),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: AppConfig.azulClaro),
            ),
            _DrawerItem(
              icon: Icons.logout_rounded,
              title: 'Cerrar sesión',
              selected: false,
              color: AppConfig.rojo,
              onTap: () => _logout(context),
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
    final itemColor = color ?? Colors.white;

    return ListTile(
      selected: selected,
      selectedTileColor: Colors.white.withOpacity(0.08),
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(
          color: itemColor,
          fontWeight: FontWeight.w700,
        ),
      ),
      onTap: onTap,
    );
  }
}