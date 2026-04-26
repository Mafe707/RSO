import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  String? _categoriaFiltro;
  String? _estadoFiltro;

  final List<Map<String, dynamic>> _reportes = [
    {
      'id': '1',
      'titulo': 'Venta informal en el centro',
      'categoria': 'Venta informal',
      'estado': 'pendiente',
      'ubicacion': 'Cra 25 #18-35, Centro',
    },
    {
      'id': '2',
      'titulo': 'Vehículo abandonado',
      'categoria': 'Invasión vehicular',
      'estado': 'revision',
      'ubicacion': 'Calle 19 #24-50',
    },
    {
      'id': '3',
      'titulo': 'Publicidad no autorizada',
      'categoria': 'Publicidad no autorizada',
      'estado': 'resuelta',
      'ubicacion': 'Av. Los Estudiantes',
    },
    {
      'id': '4',
      'titulo': 'Ocupación comercial',
      'categoria': 'Ocupación comercial',
      'estado': 'revision',
      'ubicacion': 'Calle 17 #20-69',
    },
    {
      'id': '5',
      'titulo': 'Materiales de construcción',
      'categoria': 'Otro',
      'estado': 'pendiente',
      'ubicacion': 'Transversal 23 #15-10',
    },
  ];

  List<Map<String, dynamic>> get _reportesFiltrados {
    return _reportes.where((reporte) {
      if (_categoriaFiltro != null &&
          reporte['categoria'] != _categoriaFiltro) {
        return false;
      }

      if (_estadoFiltro != null && reporte['estado'] != _estadoFiltro) {
        return false;
      }

      return true;
    }).toList();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 800;
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppConfig.rojo;
      case 'revision':
        return AppConfig.azulClaro;
      case 'resuelta':
        return AppConfig.verde;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'revision':
        return 'En revisión';
      case 'resuelta':
        return 'Resuelta';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Mapa de Reportes'),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
      ),
      drawer: CiudadanoDrawer.maybe(
        context,
        currentIndex: 3,
      ),
      bottomNavigationBar: CiudadanoBottomNav.maybe(
        context,
        currentIndex: 3,
      ),
      body: isMobile ? _buildMobileLayout() : _buildWebLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          flex: 2,
          child: _buildMapPlaceholder(),
        ),
        Expanded(
          flex: 2,
          child: _buildReportsPanel(isMobile: true),
        ),
        _buildLegend(),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            children: [
              Expanded(
                flex: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    children: [
                      _buildFilters(),
                      Expanded(
                        child: _buildMapPlaceholder(),
                      ),
                      _buildLegend(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: _buildReportsPanel(isMobile: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final categorias = _reportes
        .map((reporte) => reporte['categoria'].toString())
        .toSet()
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 19,
                color: AppConfig.azulOscuro,
              ),
              SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppConfig.azulOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterDropdown(
                  label: 'Categoría',
                  value: _categoriaFiltro,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas'),
                    ),
                    ...categorias.map(
                      (categoria) => DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _categoriaFiltro = value);
                  },
                ),
                const SizedBox(width: 12),
                _FilterDropdown(
                  label: 'Estado',
                  value: _estadoFiltro,
                  items: const [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'pendiente',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'revision',
                      child: Text('En revisión'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'resuelta',
                      child: Text('Resuelta'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _estadoFiltro = value);
                  },
                ),
                if (_categoriaFiltro != null || _estadoFiltro != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _categoriaFiltro = null;
                        _estadoFiltro = null;
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Limpiar'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      width: double.infinity,
      color: AppConfig.grisClaro,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MapPatternPainter(),
            ),
          ),
          Center(
            child: Container(
              margin: const EdgeInsets.all(22),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.94),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.map_rounded,
                    size: 62,
                    color: AppConfig.azulClaro,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Mapa interactivo',
                    style: TextStyle(
                      color: AppConfig.azulOscuro,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Marcadores: ${_reportesFiltrados.length} reportes',
                    style: TextStyle(
                      color: AppConfig.grisOscuro,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MiniStatusChip(
                        label: 'Pendiente',
                        color: AppConfig.rojo,
                      ),
                      _MiniStatusChip(
                        label: 'En revisión',
                        color: AppConfig.azulClaro,
                      ),
                      _MiniStatusChip(
                        label: 'Resuelta',
                        color: AppConfig.verde,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsPanel({required bool isMobile}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(24))
            : BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 18,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reportes cercanos',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppConfig.azulOscuro,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppConfig.azulClaro.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_reportesFiltrados.length} reportes',
                    style: const TextStyle(
                      color: AppConfig.azulOscuro,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _reportesFiltrados.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _reportesFiltrados.length,
                    itemBuilder: (context, index) {
                      final reporte = _reportesFiltrados[index];

                      return _ReportCard(
                        reporte: reporte,
                        color: _getEstadoColor(reporte['estado']),
                        estadoText: _getEstadoText(reporte['estado']),
                        onTap: () => _mostrarDetalleReporte(reporte),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 54,
              color: AppConfig.grisOscuro,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sin resultados',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No hay reportes con los filtros seleccionados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConfig.grisOscuro),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppConfig.grisMedio),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('Pendiente', AppConfig.rojo),
          _buildLegendItem('En revisión', AppConfig.azulClaro),
          _buildLegendItem('Resuelta', AppConfig.verde),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 11.5),
        ),
      ],
    );
  }

  void _mostrarDetalleReporte(Map<String, dynamic> reporte) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
              bottom: Radius.circular(18),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: AppConfig.grisMedio,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getEstadoColor(reporte['estado']),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reporte['titulo'],
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            reporte['ubicacion'],
                            style: TextStyle(color: AppConfig.grisOscuro),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(),
                _buildInfoRow('Categoría', reporte['categoria']),
                _buildInfoRow('Estado', _getEstadoText(reporte['estado'])),
                _buildInfoRow('Descripción', reporte['titulo']),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.azulOscuro,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Cerrar'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: AppConfig.grisOscuro),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(label),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> reporte;
  final Color color;
  final String estadoText;
  final VoidCallback onTap;

  const _ReportCard({
    required this.reporte,
    required this.color,
    required this.estadoText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppConfig.grisMedio),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.location_on_rounded, color: color),
        ),
        title: Text(
          reporte['titulo'],
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reporte['ubicacion']),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      estadoText,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    reporte['categoria'],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}

class _MiniStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniStatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 2;

    for (double y = 40; y < size.height; y += 80) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + 40),
        linePaint,
      );
    }

    for (double x = 30; x < size.width; x += 90) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + 45, size.height),
        linePaint,
      );
    }

    final markerPaint = Paint()
      ..color = AppConfig.azulClaro.withOpacity(0.16);

    final points = [
      Offset(size.width * 0.25, size.height * 0.30),
      Offset(size.width * 0.62, size.height * 0.42),
      Offset(size.width * 0.48, size.height * 0.68),
      Offset(size.width * 0.78, size.height * 0.26),
    ];

    for (final point in points) {
      canvas.drawCircle(point, 16, markerPaint);
      canvas.drawCircle(
        point,
        5,
        Paint()..color = AppConfig.azulClaro,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}