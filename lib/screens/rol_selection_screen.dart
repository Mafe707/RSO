import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'ciudadano/ciudadano_home_screen.dart';
import 'funcionario/login_screen.dart';
import 'administrador/login_screen.dart';

class RolSelectionScreen extends StatelessWidget {
  const RolSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.abc, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ruta Sin Obstáculos',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sistema de Reporte de Invasión\n al Espacio Público',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 50),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5)),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Selecciona tu rol',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppConfig.azulOscuro,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildRolButton(
                          context: context,
                          icon: Icons.person,
                          title: 'Ciudadano',
                          subtitle: 'Reporta invasiones y consulta estados',
                          color: AppConfig.azulClaro,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CiudadanoHomeScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildRolButton(
                          context: context,
                          icon: Icons.badge,
                          title: 'Funcionario',
                          subtitle: 'Gestiona reportes asignados',
                          color: AppConfig.azulOscuro,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FuncionarioLoginScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildRolButton(
                          context: context,
                          icon: Icons.admin_panel_settings,
                          title: 'Administrador',
                          subtitle: 'Gestión completa del sistema',
                          color: AppConfig.rojo,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  '© 2025 - Todos los derechos reservados',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRolButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppConfig.grisMedio),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: AppConfig.grisOscuro),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: AppConfig.grisOscuro),
          ],
        ),
      ),
    );
  }
}