import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';

class FuncionarioHomeScreen extends StatefulWidget {
  const FuncionarioHomeScreen({super.key});

  @override
  State<FuncionarioHomeScreen> createState() => _FuncionarioHomeScreenState();
}

class _FuncionarioHomeScreenState extends State<FuncionarioHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Funcionario'),
        backgroundColor: AppConfig.azulOscuro,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (mounted) {  // ← AHORA mounted SÍ funciona porque es StatefulWidget
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      drawer: _buildDrawer(context, authService),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hola, ${user?['nombre'] ?? 'Funcionario'}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?['cargo'] ?? 'Inspector de Espacio Público',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?['email'] ?? '',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                'Bienvenido al panel de control',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawer(BuildContext context, AuthService authService) {
    final isLoggedIn = authService.isLoggedIn;
    
    return Drawer(
      child: Container(
        color: AppConfig.azulOscuro,
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppConfig.azulOscuro),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.badge, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text('Ruta Sin Obstáculos', style: TextStyle(color: Colors.white)),
                  Text('Panel Funcionario', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _buildDrawerItem(Icons.home, 'Inicio', () {
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.assignment, 'Mis Casos', () {
              Navigator.pop(context);
              // TODO: Navegar a mis casos
            }),
            
            if (!isLoggedIn) ...[
              const Divider(color: AppConfig.azulClaro),
              _buildDrawerItem(Icons.login, 'Iniciar Sesión', () {
                Navigator.pop(context);
                // TODO: Navegar a login
              }),
              _buildDrawerItem(Icons.person_add, 'Registrarse', () {
                Navigator.pop(context);
                // TODO: Navegar a registro
              }),
            ] else ...[
              const Divider(color: AppConfig.azulClaro),
              _buildDrawerItem(Icons.person, 'Mi Perfil', () {
                Navigator.pop(context);
                // TODO: Navegar a perfil
              }),
              _buildDrawerItem(Icons.logout, 'Cerrar Sesión', () async {
                await authService.logout();
                if (mounted) {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              }, isLogout: true),
            ],
            
            const Divider(color: AppConfig.azulClaro),
            _buildDrawerItem(Icons.arrow_back, 'Volver a Selección de Roles', () {
              Navigator.popUntil(context, (route) => route.isFirst);
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? AppConfig.rojo : Colors.white),
      title: Text(title, style: TextStyle(color: isLogout ? AppConfig.rojo : Colors.white)),
      onTap: onTap,
    );
  }
}