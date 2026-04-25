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
    final userEmail = user?.email ?? '';
    final userName = user?.userMetadata?['nombre']?.split(' ')[0] ?? 'Funcionario';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Funcionario'),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              if (mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      drawer: _buildDrawer(context, authService),
      body: Container(
        color: AppConfig.grisClaro,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== TARJETA DE BIENVENIDA ==========
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Bienvenido, $userName!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userEmail,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppConfig.verde.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppConfig.verde),
                          SizedBox(width: 6),
                          Text(
                            'Funcionario Activo',
                            style: TextStyle(fontSize: 12, color: AppConfig.verde),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // ========== ESTADÍSTICAS ==========
              const Text(
                'Resumen de gestión',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildStatCard('Casos Asignados', '12', Icons.assignment, AppConfig.azulClaro)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('En Proceso', '5', Icons.pending, AppConfig.naranja)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildStatCard('Resueltos', '7', Icons.check_circle, AppConfig.verde)),
                ],
              ),
              const SizedBox(height: 24),
              
              // ========== ACCIONES RÁPIDAS ==========
              const Text(
                'Acciones rápidas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.assignment,
                      title: 'Mis Casos',
                      subtitle: 'Ver mis casos asignados',
                      color: AppConfig.azulClaro,
                      onTap: () {
                        // TODO: Navegar a Mis Casos
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.person,
                      title: 'Mi Perfil',
                      subtitle: 'Actualizar mi información',
                      color: AppConfig.azulOscuro,
                      onTap: () {
                        // TODO: Navegar a Mi Perfil
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.map,
                      title: 'Mapa de Casos',
                      subtitle: 'Ver ubicación de casos',
                      color: AppConfig.azulClaro,
                      onTap: () {
                        // TODO: Navegar a Mapa
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.flag,
                      title: 'Nuevos Reportes',
                      subtitle: 'Reportes sin asignar',
                      color: AppConfig.rojo,
                      onTap: () {
                        // TODO: Navegar a Nuevos Reportes
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Próximamente')),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // ========== ACTIVIDAD RECIENTE ==========
              const Text(
                'Actividad reciente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    _buildActivityItem(
                      'Reporte PSJ-8A4B2C9D actualizado',
                      'Hace 2 horas',
                      Icons.update,
                      AppConfig.azulClaro,
                    ),
                    const Divider(height: 0),
                    _buildActivityItem(
                      'Nuevo caso asignado',
                      'Hace 5 horas',
                      Icons.assignment_add,
                      AppConfig.verde,
                    ),
                    const Divider(height: 0),
                    _buildActivityItem(
                      'Reporte PSJ-123ABC resuelto',
                      'Ayer',
                      Icons.check_circle,
                      AppConfig.verde,
                    ),
                    const Divider(height: 0),
                    _buildActivityItem(
                      'Caso en revisión',
                      'Ayer',
                      Icons.pending,
                      AppConfig.naranja,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard({
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActivityItem(String activity, String time, IconData icon, Color color) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        activity,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        time,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }
  
  Widget _buildDrawer(BuildContext context, AuthService authService) {
    final user = authService.currentUser;
    final userName = user?.userMetadata?['nombre'] ?? 'Funcionario';
    final userEmail = user?.email ?? '';
    
    return Drawer(
      child: Container(
        color: AppConfig.azulOscuro,
        child: ListView(
          children: [
            // Header del drawer
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: AppConfig.azulOscuro,
              ),
              accountName: Text(
                userName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: AppConfig.azulClaro,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            _buildDrawerItem(Icons.home, 'Inicio', () {
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.assignment, 'Mis Casos', () {
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.person, 'Mi Perfil', () {
              Navigator.pop(context);
            }),
            _buildDrawerItem(Icons.map, 'Mapa de Casos', () {
              Navigator.pop(context);
            }),
            const Divider(color: AppConfig.azulClaro),
            _buildDrawerItem(Icons.logout, 'Cerrar Sesión', () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            }, isLogout: true),
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
      title: Text(
        title,
        style: TextStyle(color: isLogout ? AppConfig.rojo : Colors.white),
      ),
      onTap: onTap,
    );
  }
}