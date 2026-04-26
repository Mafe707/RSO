import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';

class MapaCasosScreen extends StatefulWidget {
  const MapaCasosScreen({super.key});

  @override
  State<MapaCasosScreen> createState() => _MapaCasosScreenState();
}

class _MapaCasosScreenState extends State<MapaCasosScreen> {
  String _filtroEstado = '';
  String _filtroCategoria = '';

  final List<Map<String, dynamic>> _casos = [
    {
      'id': 'PSJ-8A4B2C9D',
      'titulo': 'Venta informal en el centro',
      'categoria': 'Venta informal',
      'estado': 'revision',
      'ubicacion': 'Cra 25 #18-35, Centro',
      'prioridad': 'alta',
    },
    {
      'id': 'PSJ-123ABC',
      'titulo': 'Vehículo abandonado',
      'categoria': 'Invasión vehicular',
      'estado': 'pendiente',
      'ubicacion': 'Calle 19 #24-50',
      'prioridad': 'media',
    },
    {
      'id': 'PSJ-456DEF',
      'titulo': 'Ocupación comercial',
      'categoria': 'Ocupación comercial',
      'estado': 'resuelto',
      'ubicacion': 'Av. Los Estudiantes',
      'prioridad': 'baja',
    },
    {
      'id': 'PSJ-789GHI',
      'titulo': 'Publicidad no autorizada',
      'categoria': 'Publicidad no autorizada',
      'estado': 'pendiente',
      'ubicacion': 'Transversal 23',
      'prioridad': 'alta',
    },
  ];

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  Map<String, dynamic> _buildUserData(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    return {
      'nombre': user?.userMetadata?['nombre'] ?? 'Funcionario',
      'correo': user?.email ?? '',
      'cargo': user?.userMetadata?['cargo'] ?? '',
      'departamento': user?.userMetadata?['departamento'] ?? '',
    };
  }

  Future<void> _cerrarSesion() async {
    final authService = Provider.of<AuthService>(
      context,
      listen: false,
    );

    await authService.logout();

    if (mounted) {
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  List<Map<String, dynamic>> get _casosFiltrados {
    return _casos.where((caso) {
      if (_filtroEstado.isNotEmpty && caso['estado'] != _filtroEstado) {
        return false;
      }

      if (_filtroCategoria.isNotEmpty &&
          caso['categoria'] != _filtroCategoria) {
        return false;
      }

      return true;
    }).toList();
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppConfig.naranja;
      case 'revision':
        return AppConfig.azulClaro;
      case 'resuelto':
        return AppConfig.verde;
      default:
        return AppConfig.grisOscuro;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'revision':
        return 'En revisión';
      case 'resuelto':
        return 'Resuelto';
      default:
        return estado;
    }
  }

  Color _getPrioridadColor(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return AppConfig.rojo;
      case 'media':
        return AppConfig.naranja;
      case 'baja':
        return AppConfig.verde;
      default:
        return AppConfig.grisOscuro;
    }
  }

  String _getPrioridadText(String prioridad) {
    switch (prioridad) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Media';
      case 'baja':
        return 'Baja';
      default:
        return prioridad;
    }
  }

  void _mostrarDetalle(Map<String, dynamic> caso) {
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
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          _getEstadoColor(caso['estado']).withOpacity(0.12),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: _getEstadoColor(caso['estado']),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            caso['id'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppConfig.azulOscuro,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            caso['titulo'],
                            style: TextStyle(
                              color: AppConfig.grisOscuro,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 30),
                _buildInfoRow('Ubicación', caso['ubicacion']),
                _buildInfoRow('Categoría', caso['categoria']),
                _buildInfoRow('Estado', _getEstadoText(caso['estado'])),
                _buildInfoRow(
                  'Prioridad',
                  _getPrioridadText(caso['prioridad']),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Cerrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.azulOscuro,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
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
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppConfig.grisOscuro,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final userData = _buildUserData(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mapa de Casos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        centerTitle: isMobile,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.white,
            ),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: FuncionarioDrawer.maybe(
        context,
        currentIndex: 3,
        userData: userData,
      ),
      bottomNavigationBar: FuncionarioBottomNav.maybe(
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
          child: _buildMapPanel(),
        ),
        Expanded(
          flex: 2,
          child: _buildCasesPanel(isMobile: true),
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
                      Expanded(child: _buildMapPanel()),
                      _buildLegend(),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 4,
                child: _buildCasesPanel(isMobile: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final categorias = _casos
        .map((caso) => caso['categoria'].toString())
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
                color: AppConfig.azulOscuro,
                size: 19,
              ),
              SizedBox(width: 8),
              Text(
                'Filtros del mapa',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
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
                  label: 'Estado',
                  value: _filtroEstado.isEmpty ? null : _filtroEstado,
                  items: const [
                    DropdownMenuItem<String>(
                      value: '',
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
                      value: 'resuelto',
                      child: Text('Resuelto'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _filtroEstado = value ?? '');
                  },
                ),
                const SizedBox(width: 12),
                _FilterDropdown(
                  label: 'Categoría',
                  value: _filtroCategoria.isEmpty ? null : _filtroCategoria,
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
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
                    setState(() => _filtroCategoria = value ?? '');
                  },
                ),
                if (_filtroEstado.isNotEmpty ||
                    _filtroCategoria.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _filtroEstado = '';
                        _filtroCategoria = '';
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

  Widget _buildMapPanel() {
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
          ..._buildFakeMarkers(),
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
                    'Mapa operativo',
                    style: TextStyle(
                      color: AppConfig.azulOscuro,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Casos visibles: ${_casosFiltrados.length}',
                    style: TextStyle(
                      color: AppConfig.grisOscuro,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFakeMarkers() {
    final positions = [
      const Alignment(-0.58, -0.45),
      const Alignment(0.45, -0.30),
      const Alignment(-0.10, 0.45),
      const Alignment(0.65, 0.35),
    ];

    return List.generate(_casosFiltrados.length, (index) {
      final caso = _casosFiltrados[index];
      final alignment = positions[index % positions.length];

      return Align(
        alignment: alignment,
        child: GestureDetector(
          onTap: () => _mostrarDetalle(caso),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _getEstadoColor(caso['estado']),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _getEstadoColor(caso['estado']).withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildCasesPanel({required bool isMobile}) {
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
                    'Casos ubicados',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
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
                    '${_casosFiltrados.length} casos',
                    style: const TextStyle(
                      color: AppConfig.azulOscuro,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _casosFiltrados.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _casosFiltrados.length,
                    itemBuilder: (context, index) {
                      final caso = _casosFiltrados[index];

                      return _CaseMapCard(
                        caso: caso,
                        estadoColor: _getEstadoColor(caso['estado']),
                        estadoText: _getEstadoText(caso['estado']),
                        prioridadColor: _getPrioridadColor(caso['prioridad']),
                        prioridadText: _getPrioridadText(caso['prioridad']),
                        onTap: () => _mostrarDetalle(caso),
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
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No hay casos con los filtros seleccionados.',
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
          _buildLegendItem('Pendiente', AppConfig.naranja),
          _buildLegendItem('En revisión', AppConfig.azulClaro),
          _buildLegendItem('Resuelto', AppConfig.verde),
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
}

class _CaseMapCard extends StatelessWidget {
  final Map<String, dynamic> caso;
  final Color estadoColor;
  final String estadoText;
  final Color prioridadColor;
  final String prioridadText;
  final VoidCallback onTap;

  const _CaseMapCard({
    required this.caso,
    required this.estadoColor,
    required this.estadoText,
    required this.prioridadColor,
    required this.prioridadText,
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
          backgroundColor: estadoColor.withOpacity(0.12),
          child: Icon(Icons.location_on_rounded, color: estadoColor),
        ),
        title: Text(
          caso['id'],
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppConfig.azulOscuro,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(caso['ubicacion']),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(label: estadoText, color: estadoColor),
                  _StatusChip(label: prioridadText, color: prioridadColor),
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w800,
        ),
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
      constraints: const BoxConstraints(minWidth: 160),
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

    final zonePaint = Paint()
      ..color = AppConfig.azulClaro.withOpacity(0.08);

    canvas.drawCircle(
      Offset(size.width * 0.30, size.height * 0.35),
      90,
      zonePaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.70, size.height * 0.65),
      110,
      zonePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}