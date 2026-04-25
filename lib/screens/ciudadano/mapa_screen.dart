import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  String? _categoriaFiltro;
  String? _estadoFiltro;
  
  final List<Map<String, dynamic>> _reportes = [
    {'id': '1', 'titulo': 'Venta informal en el centro', 'categoria': 'Venta informal', 'estado': 'pendiente', 'ubicacion': 'Cra 25 #18-35, Centro'},
    {'id': '2', 'titulo': 'Vehículo abandonado', 'categoria': 'Invasión vehicular', 'estado': 'revision', 'ubicacion': 'Calle 19 #24-50'},
    {'id': '3', 'titulo': 'Publicidad no autorizada', 'categoria': 'Publicidad no autorizada', 'estado': 'resuelta', 'ubicacion': 'Av. Los Estudiantes'},
    {'id': '4', 'titulo': 'Ocupación comercial', 'categoria': 'Ocupación comercial', 'estado': 'revision', 'ubicacion': 'Calle 17 #20-69'},
    {'id': '5', 'titulo': 'Materiales de construcción', 'categoria': 'Otro', 'estado': 'pendiente', 'ubicacion': 'Transversal 23 #15-10'},
  ];
  
  List<Map<String, dynamic>> get _reportesFiltrados {
    return _reportes.where((r) {
      if (_categoriaFiltro != null && r['categoria'] != _categoriaFiltro) return false;
      if (_estadoFiltro != null && r['estado'] != _estadoFiltro) return false;
      return true;
    }).toList();
  }
  
  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return Colors.red;
      case 'revision': return Colors.blue;
      case 'resuelta': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'revision': return 'En revisión';
      case 'resuelta': return 'Resuelta';
      default: return estado;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Reportes')),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtros', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        hint: const Text('Categoría'),
                        value: _categoriaFiltro,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todas')),
                          ..._reportes.map((r) => r['categoria']).toSet().map((cat) => DropdownMenuItem(value: cat, child: Text(cat))),
                        ],
                        onChanged: (value) => setState(() => _categoriaFiltro = value),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        hint: const Text('Estado'),
                        value: _estadoFiltro,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Todos')),
                          const DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                          const DropdownMenuItem(value: 'revision', child: Text('En revisión')),
                          const DropdownMenuItem(value: 'resuelta', child: Text('Resuelta')),
                        ],
                        onChanged: (value) => setState(() => _estadoFiltro = value),
                      ),
                      if (_categoriaFiltro != null || _estadoFiltro != null)
                        TextButton(onPressed: () => setState(() { _categoriaFiltro = null; _estadoFiltro = null; }), child: const Text('Limpiar')),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Mapa simulado
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              color: AppConfig.grisClaro,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 64, color: AppConfig.azulClaro),
                  const SizedBox(height: 12),
                  Text('Mapa interactivo con Google Maps', style: TextStyle(color: AppConfig.grisOscuro)),
                  const SizedBox(height: 8),
                  Text('Marcadores: ${_reportesFiltrados.length} reportes', style: TextStyle(fontWeight: FontWeight.bold, color: AppConfig.azulOscuro)),
                ],
              ),
            ),
          ),
          
          // Lista de reportes
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, -2))],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Reportes cercanos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.azulOscuro)),
                        Text('${_reportesFiltrados.length} reportes', style: TextStyle(color: AppConfig.grisOscuro)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _reportesFiltrados.length,
                      itemBuilder: (context, index) {
                        final reporte = _reportesFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getEstadoColor(reporte['estado']).withOpacity(0.2),
                              child: Icon(Icons.location_on, color: _getEstadoColor(reporte['estado'])),
                            ),
                            title: Text(reporte['titulo'], style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(reporte['ubicacion']),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getEstadoColor(reporte['estado']).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(_getEstadoText(reporte['estado']), style: TextStyle(fontSize: 10, color: _getEstadoColor(reporte['estado']))),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(reporte['categoria'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _mostrarDetalleReporte(reporte),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Leyenda
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppConfig.grisMedio))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Pendiente', Colors.red),
                _buildLegendItem('En revisión', Colors.blue),
                _buildLegendItem('Resuelta', Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(width: 14, height: 14, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(title, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
  
  void _mostrarDetalleReporte(Map<String, dynamic> reporte) {
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
                Container(width: 8, height: 40, decoration: BoxDecoration(color: _getEstadoColor(reporte['estado']), borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reporte['titulo'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(reporte['ubicacion'], style: TextStyle(color: AppConfig.grisOscuro)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildInfoRow('Categoría', reporte['categoria']),
            _buildInfoRow('Estado', _getEstadoText(reporte['estado'])),
            _buildInfoRow('Descripción', reporte['titulo']),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}