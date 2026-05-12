import 'package:flutter/material.dart';
import '../../../config/app_config.dart';

class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
    required this.onLogout,
  });

  static Widget? maybe(
    BuildContext context, {
    required int currentIndex,
    required ValueChanged<int> onSelect,
    required VoidCallback onLogout,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 780;
    if (!isMobile) return null;
    return AdminBottomNav(
      currentIndex: currentIndex,
      onSelect: onSelect,
      onLogout: onLogout,
    );
  }

  void _openMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
              bottom: Radius.circular(18),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppConfig.grisMedio,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded, color: AppConfig.azulOscuro),
                    SizedBox(width: 10),
                    Text(
                      'Más opciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppConfig.azulOscuro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _MoreItem(
                  icon: Icons.bar_chart_rounded,
                  title: 'Estadísticas',
                  selected: currentIndex == 3,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(3);
                  },
                ),
                _MoreItem(
                  icon: Icons.settings_rounded,
                  title: 'Configuración',
                  selected: currentIndex == 4,
                  onTap: () {
                    Navigator.pop(context);
                    onSelect(4);
                  },
                ),
                const Divider(height: 20),
                _MoreItem(
                  icon: Icons.logout_rounded,
                  title: 'Cerrar sesión',
                  color: AppConfig.rojo,
                  onTap: () {
                    Navigator.pop(context);
                    onLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  int get _safeSelectedIndex {
    if (currentIndex >= 0 && currentIndex <= 2) return currentIndex;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _safeSelectedIndex,
      onDestinationSelected: (index) {
        if (index == 3) {
          _openMoreMenu(context);
          return;
        }
        onSelect(index);
      },
      height: 74,
      backgroundColor: Colors.white,
      indicatorColor: AppConfig.rojo.withOpacity(0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.fact_check_outlined),
          selectedIcon: Icon(Icons.fact_check_rounded),
          label: 'Validación',
        ),
        NavigationDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts_rounded),
          label: 'Funcionarios',
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
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? AppConfig.azulOscuro;
    return ListTile(
      selected: selected,
      selectedTileColor: itemColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      leading: Icon(icon, color: itemColor),
      title: Text(
        title,
        style: TextStyle(color: itemColor, fontWeight: FontWeight.w800),
      ),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: itemColor)
          : const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}