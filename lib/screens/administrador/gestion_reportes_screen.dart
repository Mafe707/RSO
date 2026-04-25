import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class GestionReportesScreen extends StatefulWidget {
  const GestionReportesScreen({super.key});

  @override
  State<GestionReportesScreen> createState() => _GestionReportesScreenState();
}

class _GestionReportesScreenState extends State<GestionReportesScreen> {
  String _filtroEstado = '';
  String _filtroCategoria = '';
  
  final List<Map<String, dynamic>> _reportes = [
    {'id': 'PSJ-8A4B2C9D', 'fecha': '05/09/2025', 'categoria': 'Venta informal', 'ubicacion': 'Cra 25 #18-35', 'estado': 'revision', 'asignado': 'Carlos Rodríguez'},
    {'id': 'PSJ-123ABC', 'fecha': '10/09/2025', 'categoria': 'Invasión vehicular', 'ubicacion': 'Calle 19 #24-50', 'estado': 'pendiente', 'asignado': 'No asignado'},
    {'id': 'PSJ-456DEF', 'fecha': '01/09/2025', 'categoria': 'Ocupación comercial', 'ubicacion': 'Av. Los Estudiantes', 'estado': 'resuelto', 'asignado': 'María González'},
    {'id': 'PSJ-789GHI', 'fecha': '12/09/2025', 'categoria': 'Publicidad no autorizada', 'ubicacion': 'Transversal 23', 'estado': 'revision', 'asignado': 'Javier López'},
  ];
  
  List<Map<String, dynamic>> get _reportesFiltrados {
    return _reportes.where((r) {
      if (_filtroEstado.isNotEmpty && r['estado'] != _filtroEstado) return false;
      if (_filtroCategoria.isNotEmpty && r['categoria'] != _filtroCategoria) return false;
      return true;
    }).toList();
  }
  
  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'revision': return 'En revisión';
      case 'resuelto': return 'Resuelto';
      default: return estado;
    }
  }
  
  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return AppConfig.naranja;
      case 'revision': return AppConfig.azulClaro;
      case 'resuelto': return AppConfig.verde;
      default: return AppConfig.grisOscuro;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Reportes'), automaticallyImplyLeading: false),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroEstado.isEmpty ? null : _filtroEstado,
                    hint: const Text('Estado'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todos')),
                      const DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                      const DropdownMenuItem(value: 'revision', child: Text('En revisión')),
                      const DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
                    ],
                    onChanged: (value) => setState(() => _filtroEstado = value ?? ''),
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filtroCategoria.isEmpty ? null : _filtroCategoria,
                    hint: const Text('Categoría'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todas')),
                      const DropdownMenuItem(value: 'Venta informal', child: Text('Venta informal')),
                      const DropdownMenuItem(value: 'Invasión vehicular', child: Text('Invasión vehicular')),
                      const DropdownMenuItem(value: 'Ocupación comercial', child: Text('Ocupación comercial')),
                    ],
                    onChanged: (value) => setState(() => _filtroCategoria = value ?? ''),
                    decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _reportesFiltrados.length,
              itemBuilder: (context, index) {
                final reporte = _reportesFiltrados[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEstadoColor(reporte['estado']).withOpacity(0.2),
                      child: Icon(Icons.flag, color: _getEstadoColor(reporte['estado'])),
                    ),
                    title: Text(reporte['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${reporte['ubicacion']} • ${reporte['categoria']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(reporte['estado']).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_getEstadoText(reporte['estado']), style: TextStyle(fontSize: 11, color: _getEstadoColor(reporte['estado']))),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          onPressed: () {},
                          tooltip: 'Editar',
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}