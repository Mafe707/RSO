import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import 'reportar_screen.dart';
import 'consultar_screen.dart';
import 'mapa_screen.dart';
import 'informacion_screen.dart';

class CiudadanoHomeScreen extends StatelessWidget {
  const CiudadanoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta Sin Obstáculos'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 14),
                const SizedBox(width: 4),
                const Text('San Juan de Pasto', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppConfig.rojo, borderRadius: BorderRadius.circular(20)),
                  child: const Text('Ciudadano', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeBanner(),
            const SizedBox(height: 24),
            _buildSectionTitle('Acciones rápidas'),
            const SizedBox(height: 16),
            _buildActionCards(context),
            const SizedBox(height: 32),
            _buildSectionTitle('¿Cómo funciona?'),
            const SizedBox(height: 16),
            _buildHowItWorks(),
            const SizedBox(height: 32),
            _buildSectionTitle('Estadísticas'),
            const SizedBox(height: 16),
            _buildStatsCards(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      drawer: _buildDrawer(context),
    );
  }

  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¡Bienvenido!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(
            'Reporta invasiones al espacio público de forma anónima y ayuda a mejorar tu ciudad',
            style: TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.azulOscuro),
    );
  }

  Widget _buildActionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.flag,
            title: 'Reportar',
            subtitle: 'Nueva invasión',
            color: AppConfig.azulOscuro,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportarScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.search,
            title: 'Consultar',
            subtitle: 'Estado de reporte',
            color: AppConfig.azulClaro,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultarScreen())),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.map,
            title: 'Mapa',
            subtitle: 'Ver denuncias',
            color: AppConfig.rojo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaScreen())),
          ),
        ),
      ],
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
          border: Border.all(color: AppConfig.grisMedio),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: AppConfig.grisOscuro), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStep(1, 'Reporta la invasión con ubicación, categoría y evidencia'),
            const Divider(height: 24),
            _buildStep(2, 'Recibe un código único de seguimiento'),
            const Divider(height: 24),
            _buildStep(3, 'Consulta el estado de tu reporte cuando quieras'),
            const Divider(height: 24),
            _buildStep(4, 'Las autoridades gestionarán tu reporte'),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Row(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: AppConfig.azulClaro, shape: BoxShape.circle),
          child: Center(child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard(number: '128', label: 'Reportes activos', color: AppConfig.azulOscuro)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(number: '45', label: 'En revisión', color: AppConfig.naranja)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(number: '312', label: 'Resueltos', color: AppConfig.verde)),
      ],
    );
  }

  Widget _buildStatCard({required String number, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: Column(
        children: [
          Text(number, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: AppConfig.azulOscuro,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppConfig.azulOscuro),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.abc, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text('Ruta Sin Obstáculos', style: TextStyle(color: Colors.white, fontSize: 20)),
                  Text('Sistema de Reporte', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text('Inicio', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.white),
              title: const Text('Reportar Invasión', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportarScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.white),
              title: const Text('Consultar Estado', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ConsultarScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text('Información', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const InformacionScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.white),
              title: const Text('Mapa de Reportes', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MapaScreen()));
              },
            ),
            const Divider(color: AppConfig.azulClaro),
            ListTile(
              leading: const Icon(Icons.arrow_back, color: Colors.white),
              title: const Text('Volver a Selección de Roles', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}