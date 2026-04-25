import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import 'gestion_reportes_screen.dart';
import 'gestion_usuarios_screen.dart';
import 'gestion_zonas_screen.dart';
import 'asignaciones_screen.dart';
import 'estadisticas_screen.dart';
import 'configuracion_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const AdminDashboardScreen({super.key, required this.adminData});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  
  late List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    _screens = [
      AdminDashboardContent(adminData: widget.adminData),
      const GestionReportesScreen(),
      const GestionUsuariosScreen(),
      const GestionZonasScreen(),
      const AsignacionesScreen(),
      const EstadisticasScreen(),
      const ConfiguracionScreen(),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
    );
  }
  
  Widget _buildDrawer() {
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
                  Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text('Ruta Sin Obstáculos', style: TextStyle(color: Colors.white)),
                  Text('Panel Administrador', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
            _buildDrawerItem(Icons.flag, 'Gestión de Reportes', 1),
            _buildDrawerItem(Icons.people, 'Gestión de Usuarios', 2),
            _buildDrawerItem(Icons.map, 'Gestión de Zonas', 3),
            _buildDrawerItem(Icons.assignment, 'Asignaciones', 4),
            _buildDrawerItem(Icons.bar_chart, 'Estadísticas', 5),
            _buildDrawerItem(Icons.settings, 'Configuración', 6),
            const Divider(color: AppConfig.azulClaro),
            _buildDrawerItem(Icons.exit_to_app, 'Cerrar Sesión', -1, isLogout: true),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem(IconData icon, String title, int index, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? AppConfig.rojo : Colors.white),
      title: Text(title, style: TextStyle(color: isLogout ? AppConfig.rojo : Colors.white)),
      selected: _selectedIndex == index,
      selectedTileColor: AppConfig.azulClaro.withOpacity(0.3),
      onTap: () {
        if (isLogout) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        }
      },
    );
  }
}

// Dashboard Content
class AdminDashboardContent extends StatelessWidget {
  final Map<String, dynamic> adminData;
  const AdminDashboardContent({super.key, required this.adminData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppConfig.azulOscuro, AppConfig.azulClaro]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hola, ${adminData['nombre']}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Bienvenido al panel de administración', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Estadísticas Generales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.azulOscuro)),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildStatCard('Reportes Totales', '312', Icons.list_alt, AppConfig.azulOscuro),
              _buildStatCard('Pendientes', '45', Icons.pending, AppConfig.naranja),
              _buildStatCard('En Revisión', '28', Icons.autorenew, AppConfig.azulClaro),
              _buildStatCard('Resueltos', '239', Icons.check_circle, AppConfig.verde),
              _buildStatCard('Funcionarios', '12', Icons.people, AppConfig.azulClaro),
              _buildStatCard('Zonas Activas', '8', Icons.map, AppConfig.verde),
            ],
          ),
          const SizedBox(height: 24),
          Text('Actividad Reciente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.azulOscuro)),
          const SizedBox(height: 12),
          _buildActivityItem('Nuevo reporte PSJ-8A4B2C9D', 'Hace 5 minutos', Icons.flag),
          const Divider(),
          _buildActivityItem('Caso asignado a Carlos Rodríguez', 'Hace 1 hora', Icons.assignment),
          const Divider(),
          _buildActivityItem('Reporte PSJ-123ABC resuelto', 'Hace 3 horas', Icons.check_circle),
          const Divider(),
          _buildActivityItem('Nuevo funcionario registrado', 'Ayer', Icons.person_add),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem(String activity, String time, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppConfig.azulClaro.withOpacity(0.1),
        child: Icon(icon, color: AppConfig.azulClaro, size: 20),
      ),
      title: Text(activity),
      subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }
}