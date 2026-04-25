import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class NuevosReportesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const NuevosReportesScreen({super.key, required this.userData});

  @override
  State<NuevosReportesScreen> createState() => _NuevosReportesScreenState();
}

class _NuevosReportesScreenState extends State<NuevosReportesScreen> {
  final List<Map<String, dynamic>> _nuevosReportes = [
    {'id': 'PSJ-ABC123', 'fecha': '15/09/2025', 'categoria': 'Venta informal', 'ubicacion': 'Parque Central', 'prioridad': 'alta'},
    {'id': 'PSJ-DEF456', 'fecha': '14/09/2025', 'categoria': 'Invasión vehicular', 'ubicacion': 'Calle 15', 'prioridad': 'media'},
    {'id': 'PSJ-GHI789', 'fecha': '14/09/2025', 'categoria': 'Ocupación comercial', 'ubicacion': 'Avenida Colombia', 'prioridad': 'alta'},
  ];
  
  void _asignarACaso(String id) {
    setState(() {
      _nuevosReportes.removeWhere((r) => r['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Caso asignado correctamente'), backgroundColor: AppConfig.verde),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nuevos Reportes')),
      body: _nuevosReportes.isEmpty
          ? const Center(child: Text('No hay nuevos reportes disponibles'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _nuevosReportes.length,
              itemBuilder: (context, index) {
                final reporte = _nuevosReportes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppConfig.rojo.withOpacity(0.2),
                      child: const Icon(Icons.new_releases, color: AppConfig.rojo),
                    ),
                    title: Text(reporte['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reporte['ubicacion']),
                        Text(reporte['categoria'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _asignarACaso(reporte['id']),
                      style: ElevatedButton.styleFrom(backgroundColor: AppConfig.verde),
                      child: const Text('Asignar a mí'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}