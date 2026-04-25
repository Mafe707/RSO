import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class MisCasosScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MisCasosScreen({super.key, required this.userData});

  @override
  State<MisCasosScreen> createState() => _MisCasosScreenState();
}

class _MisCasosScreenState extends State<MisCasosScreen> {
  String _filtroEstado = '';
  String _filtroPrioridad = '';
  String _buscarTexto = '';
  
  final List<Map<String, dynamic>> _casos = [
    {'id': 'PSJ-8A4B2C9D', 'fecha': '05/09/2025', 'categoria': 'Venta informal', 'ubicacion': 'Cra 25 #18-35', 'prioridad': 'alta', 'estado': 'revision'},
    {'id': 'PSJ-123ABC', 'fecha': '10/09/2025', 'categoria': 'Invasión vehicular', 'ubicacion': 'Calle 19 #24-50', 'prioridad': 'media', 'estado': 'pendiente'},
    {'id': 'PSJ-456DEF', 'fecha': '01/09/2025', 'categoria': 'Ocupación comercial', 'ubicacion': 'Av. Los Estudiantes', 'prioridad': 'baja', 'estado': 'resuelto'},
    {'id': 'PSJ-789GHI', 'fecha': '12/09/2025', 'categoria': 'Publicidad no autorizada', 'ubicacion': 'Transversal 23', 'prioridad': 'alta', 'estado': 'pendiente'},
    {'id': 'PSJ-321JKL', 'fecha': '08/09/2025', 'categoria': 'Otro', 'ubicacion': 'Calle 25 #30-15', 'prioridad': 'media', 'estado': 'revision'},
  ];
  
  List<Map<String, dynamic>> get _casosFiltrados {
    return _casos.where((c) {
      if (_filtroEstado.isNotEmpty && c['estado'] != _filtroEstado) return false;
      if (_filtroPrioridad.isNotEmpty && c['prioridad'] != _filtroPrioridad) return false;
      if (_buscarTexto.isNotEmpty) {
        return c['id'].toLowerCase().contains(_buscarTexto.toLowerCase()) ||
               c['ubicacion'].toLowerCase().contains(_buscarTexto.toLowerCase());
      }
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
  
  String _getPrioridadText(String prioridad) {
    switch (prioridad) {
      case 'alta': return 'Alta';
      case 'media': return 'Media';
      case 'baja': return 'Baja';
      default: return prioridad;
    }
  }
  
  Color _getPrioridadColor(String prioridad) {
    switch (prioridad) {
      case 'alta': return AppConfig.rojo;
      case 'media': return AppConfig.naranja;
      case 'baja': return AppConfig.verde;
      default: return AppConfig.grisOscuro;
    }
  }
  
  void _verDetalles(Map<String, dynamic> caso) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8, height: 40, decoration: BoxDecoration(color: _getEstadoColor(caso['estado']), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(child: Text(caso['id'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Ubicación', caso['ubicacion']),
            _buildInfoRow('Categoría', caso['categoria']),
            _buildInfoRow('Fecha', caso['fecha']),
            _buildInfoRow('Prioridad', _getPrioridadText(caso['prioridad'])),
            _buildInfoRow('Estado', _getEstadoText(caso['estado'])),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cambiarEstado(caso['id'], 'revision'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.azulClaro),
                    child: const Text('En revisión'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cambiarEstado(caso['id'], 'resuelto'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.verde),
                    child: const Text('Resolver'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
            ),
          ],
        ),
      ),
    );
  }
  
  void _cambiarEstado(String id, String nuevoEstado) {
    setState(() {
      final index = _casos.indexWhere((c) => c['id'] == id);
      if (index != -1) {
        _casos[index]['estado'] = nuevoEstado;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Caso $id actualizado a ${_getEstadoText(nuevoEstado)}'), backgroundColor: AppConfig.verde),
    );
    Navigator.pop(context);
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Casos')),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                Row(
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
                        value: _filtroPrioridad.isEmpty ? null : _filtroPrioridad,
                        hint: const Text('Prioridad'),
                        items: [
                          const DropdownMenuItem(value: '', child: Text('Todas')),
                          const DropdownMenuItem(value: 'alta', child: Text('Alta')),
                          const DropdownMenuItem(value: 'media', child: Text('Media')),
                          const DropdownMenuItem(value: 'baja', child: Text('Baja')),
                        ],
                        onChanged: (value) => setState(() => _filtroPrioridad = value ?? ''),
                        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar por ID o ubicación...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _buscarTexto = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _casosFiltrados.length,
              itemBuilder: (context, index) {
                final caso = _casosFiltrados[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEstadoColor(caso['estado']).withOpacity(0.2),
                      child: Icon(Icons.assignment, color: _getEstadoColor(caso['estado'])),
                    ),
                    title: Text(caso['id'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(caso['ubicacion']),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(caso['estado']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_getEstadoText(caso['estado']), style: TextStyle(fontSize: 11, color: _getEstadoColor(caso['estado']))),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getPrioridadColor(caso['prioridad']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(_getPrioridadText(caso['prioridad']), style: TextStyle(fontSize: 11, color: _getPrioridadColor(caso['prioridad']))),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _verDetalles(caso),
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