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
        MaterialPageRoute(
          builder: (_) => const FuncionarioLoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = userData['nombre']?.toString() ?? 'Funcionario';
    final userEmail = userData['correo']?.toString() ?? '';
    final inicial = userName.isNotEmpty ? userName[0].toUpperCase() : 'F';

    return Drawer(
      child: Container(
        color: AppConfig.azulOscuro,
        child: Column(
          children: [
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
                  Row(
                    children: [
                      userData['foto_url'] != null &&
                              (userData['foto_url'] as String).isNotEmpty
                          ? CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(
                                userData['foto_url'] as String,
                              ),
                              onBackgroundImageError: (_, __) {},
                            )
                          : CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white.withOpacity(0.18),
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.60),
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
                    'Panel del funcionario',
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
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
                    icon: Icons.manage_accounts_rounded,
                    title: 'Mi perfil',
                    selected: currentIndex == 4,
                    onTap: () => _navigate(context, 4),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: Divider(color: Colors.white12),
                  ),
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar sesión',
                    selected: false,
                    color: Colors.redAccent,
                    onTap: () => _logout(context),
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
    final itemColor = color ?? (selected ? Colors.white : Colors.white70);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 2,
      ),
      child: ListTile(
        selected: selected,
        selectedTileColor: Colors.white.withOpacity(0.10),
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
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}