import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';

import 'funcionario_home_screen.dart';
import 'mis_casos_screen.dart';
import 'nuevos_reportes_screen.dart';
import 'mapa_casos_screen.dart';
import 'mi_perfil_screen.dart';

class FuncionarioBottomNav extends StatelessWidget {
  final int currentIndex;

  const FuncionarioBottomNav({
    super.key,
    required this.currentIndex,
  });

  static Widget? maybe(
    BuildContext context, {
    required int currentIndex,
  }) {
    final isMobile = MediaQuery.of(context).size.width < 780;

    if (!isMobile) return null;

    return FuncionarioBottomNav(currentIndex: currentIndex);
  }

  Map<String, dynamic> _buildUserData(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return {
      'nombre': user?.userMetadata?['nombre'] ?? 'Funcionario',
      'correo': user?.email ?? '',
      'cargo': user?.userMetadata?['cargo'] ?? '',
      'departamento': user?.userMetadata?['departamento'] ?? '',
    };
  }

  Future<void> _logout(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);

    await authService.logout();

    if (context.mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _navigate(BuildContext context, int index) {
    if (index == 5) {
      _logout(context);
      return;
    }

    if (index == currentIndex) return;

    final userData = _buildUserData(context);

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

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _navigate(context, index),
      height: 74,
      backgroundColor: Colors.white,
      indicatorColor: AppConfig.azulClaro.withOpacity(0.14),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Inicio',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Casos',
        ),
        NavigationDestination(
          icon: Icon(Icons.flag_outlined),
          selectedIcon: Icon(Icons.flag_rounded),
          label: 'Reportes',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map_rounded),
          label: 'Mapa',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
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