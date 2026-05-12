import 'package:flutter/material.dart';
import '../../../config/app_config.dart';

class AdminDrawer extends StatelessWidget {
  final int currentIndex;
  final Map<String, dynamic> adminData;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const AdminDrawer({
    super.key,
    required this.currentIndex,
    required this.adminData,
    required this.onSelect,
    required this.onLogout,
  });

  static Widget? maybe(
    BuildContext context, {
    required int currentIndex,
    required Map<String, dynamic> adminData,
    required ValueChanged<int> onSelect,
    required VoidCallback onLogout,
  }) {
    final isMobile =
        MediaQuery.of(context).size.width < 780;

    if (isMobile) return null;

    return AdminDrawer(
      currentIndex: currentIndex,
      adminData: adminData,
      onSelect: onSelect,
      onLogout: onLogout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminName =
        adminData['nombre']?.toString() ??
        'Supervisor';

    final adminEmail =
        adminData['correo']?.toString() ?? '';

    final adminRole =
        adminData['rol']?.toString() ?? 'admin';

    return Drawer(
      child: Container(
        color: AppConfig.azulOscuro,
        child: SafeArea(
          child: Column(
            children: [
              _AdminHeader(
                adminName: adminName,
                adminEmail: adminEmail,
                adminRole: adminRole,
              ),

              const Divider(
                color: Colors.white12,
                height: 1,
              ),

              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(
                        vertical: 10,
                      ),
                  children: [
                    _DrawerItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Supervisión',
                      selected: currentIndex == 0,
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(0);
                      },
                    ),

                    _DrawerItem(
                      icon: Icons.fact_check_rounded,
                      title:
                          'Validación de Reportes',
                      selected: currentIndex == 1,
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(1);
                      },
                    ),

                    _DrawerItem(
                      icon:
                          Icons.manage_accounts_rounded,
                      title:
                          'Gestión de Funcionarios',
                      selected: currentIndex == 2,
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(2);
                      },
                    ),

                    _DrawerItem(
                      icon: Icons.bar_chart_rounded,
                      title: 'Estadísticas',
                      selected: currentIndex == 3,
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(3);
                      },
                    ),

                    _DrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'Configuración',
                      selected: currentIndex == 4,
                      onTap: () {
                        Navigator.pop(context);
                        onSelect(4);
                      },
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                      child: Divider(
                        color: Colors.white12,
                      ),
                    ),

                    _DrawerItem(
                      icon: Icons.logout_rounded,
                      title: 'Cerrar sesión',
                      selected: false,
                      color: Colors.redAccent,
                      onTap: () {
                        Navigator.pop(context);
                        onLogout();
                      },
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
}

class _AdminHeader extends StatelessWidget {
  final String adminName;
  final String adminEmail;
  final String adminRole;

  const _AdminHeader({
    required this.adminName,
    required this.adminEmail,
    required this.adminRole,
  });

  String _capitalize(String s) {
    if (s.isEmpty) return s;

    return s[0].toUpperCase() +
        s.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final initial =
        adminName.trim().isNotEmpty
            ? adminName.trim()[0].toUpperCase()
            : 'S';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top:
            MediaQuery.of(context).padding.top +
            24,
        left: 20,
        right: 20,
        bottom: 22,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    Colors.white.withOpacity(0.18),
                child: Text(
                  initial,
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
                    Text(
                      adminName,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      adminEmail,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white
                            .withOpacity(0.60),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            children: [
              const Text(
                'Panel administrativo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),

              const SizedBox(width: 10),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                decoration: BoxDecoration(
                  color:
                      AppConfig.rojo.withOpacity(
                        0.25,
                      ),
                  borderRadius:
                      BorderRadius.circular(999),
                ),
                child: Text(
                  _capitalize(adminRole),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
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
        contentPadding:
            const EdgeInsets.symmetric(
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