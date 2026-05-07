import 'package:flutter/material.dart';

import '../../../config/app_config.dart';

class GestionReportesScreen extends StatefulWidget {
  const GestionReportesScreen({super.key});

  @override
  State<GestionReportesScreen> createState() => _GestionReportesScreenState();
}

class _GestionReportesScreenState extends State<GestionReportesScreen> {
  String _filtroEstado = '';
  String _filtroCategoria = '';
  String _buscarTexto = '';

  final List<Map<String, dynamic>> _reportes = [
    {
      'codigo': 'PSJ-8A4B2C9D',
      'ubicacion': 'Cra 25 #18-35, Centro',
      'categoria': 'Venta informal',
      'descripcion': 'Puesto de venta informal bloqueando el paso peatonal.',
      'estado': 'pendiente',
      'fecha': '05/09/2025',
      'prioridad': 'alta',
      'funcionario': 'Sin asignar',
    },
    {
      'codigo': 'PSJ-123ABC',
      'ubicacion': 'Calle 19 #24-50',
      'categoria': 'Invasión vehicular',
      'descripcion': 'Vehículo estacionado sobre el andén.',
      'estado': 'revision',
      'fecha': '10/09/2025',
      'prioridad': 'media',
      'funcionario': 'Carlos Martínez',
    },
    {
      'codigo': 'PSJ-456DEF',
      'ubicacion': 'Av. Los Estudiantes',
      'categoria': 'Ocupación comercial',
      'descripcion': 'Mesas ocupando espacio público.',
      'estado': 'resuelto',
      'fecha': '01/09/2025',
      'prioridad': 'baja',
      'funcionario': 'Ana Gómez',
    },
    {
      'codigo': 'PSJ-789GHI',
      'ubicacion': 'Transversal 23',
      'categoria': 'Publicidad no autorizada',
      'descripcion': 'Aviso publicitario en zona no permitida.',
      'estado': 'pendiente',
      'fecha': '12/09/2025',
      'prioridad': 'alta',
      'funcionario': 'Sin asignar',
    },
  ];

  final List<String> _funcionarios = [
    'Carlos Martínez',
    'Ana Gómez',
    'Luis Herrera',
    'María Rodríguez',
  ];

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  List<Map<String, dynamic>> get _reportesFiltrados {
    return _reportes.where((reporte) {
      if (_filtroEstado.isNotEmpty && reporte['estado'] != _filtroEstado) {
        return false;
      }

      if (_filtroCategoria.isNotEmpty &&
          reporte['categoria'] != _filtroCategoria) {
        return false;
      }

      if (_buscarTexto.isNotEmpty) {
        final query = _buscarTexto.toLowerCase();

        return reporte['codigo'].toString().toLowerCase().contains(query) ||
            reporte['ubicacion'].toString().toLowerCase().contains(query) ||
            reporte['categoria'].toString().toLowerCase().contains(query) ||
            reporte['funcionario'].toString().toLowerCase().contains(query);
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

  void _cambiarEstado(String codigo, String nuevoEstado) {
    setState(() {
      final index = _reportes.indexWhere((r) => r['codigo'] == codigo);

      if (index != -1) {
        _reportes[index]['estado'] = nuevoEstado;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte $codigo actualizado correctamente'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  void _asignarFuncionario(String codigo, String funcionario) {
    setState(() {
      final index = _reportes.indexWhere((r) => r['codigo'] == codigo);

      if (index != -1) {
        _reportes[index]['funcionario'] = funcionario;
        _reportes[index]['estado'] = 'revision';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte $codigo asignado a $funcionario'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> reporte) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
            child: SingleChildScrollView(
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
                        backgroundColor: _getEstadoColor(
                          reporte['estado'],
                        ).withOpacity(0.12),
                        child: Icon(
                          Icons.flag_rounded,
                          color: _getEstadoColor(reporte['estado']),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reporte['codigo'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reporte['ubicacion'],
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
                  _buildInfoRow('Categoría', reporte['categoria']),
                  _buildInfoRow('Descripción', reporte['descripcion']),
                  _buildInfoRow('Fecha', reporte['fecha']),
                  _buildInfoRow('Estado', _getEstadoText(reporte['estado'])),
                  _buildInfoRow(
                    'Prioridad',
                    _getPrioridadText(reporte['prioridad']),
                  ),
                  _buildInfoRow('Funcionario', reporte['funcionario']),
                  const SizedBox(height: 20),
                  const Text(
                    'Asignar funcionario',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppConfig.azulOscuro,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    hint: const Text('Seleccione funcionario'),
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: _funcionarios.map((funcionario) {
                      return DropdownMenuItem<String>(
                        value: funcionario,
                        child: Text(funcionario),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      Navigator.pop(context);
                      _asignarFuncionario(reporte['codigo'], value);
                    },
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 430;

                      if (isNarrow) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: _stateButton(
                                label: 'En revisión',
                                icon: Icons.pending_actions_rounded,
                                color: AppConfig.azulClaro,
                                onPressed: () {
                                  Navigator.pop(context);
                                  _cambiarEstado(
                                    reporte['codigo'],
                                    'revision',
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: _stateButton(
                                label: 'Resolver',
                                icon: Icons.check_circle_rounded,
                                color: AppConfig.verde,
                                onPressed: () {
                                  Navigator.pop(context);
                                  _cambiarEstado(
                                    reporte['codigo'],
                                    'resuelto',
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _stateButton(
                              label: 'En revisión',
                              icon: Icons.pending_actions_rounded,
                              color: AppConfig.azulClaro,
                              onPressed: () {
                                Navigator.pop(context);
                                _cambiarEstado(reporte['codigo'], 'revision');
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _stateButton(
                              label: 'Resolver',
                              icon: Icons.check_circle_rounded,
                              color: AppConfig.verde,
                              onPressed: () {
                                Navigator.pop(context);
                                _cambiarEstado(reporte['codigo'], 'resuelto');
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stateButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
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

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: isMobile ? _buildMobileLayout() : _buildWebLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHero(isMobile: true),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 12),
        Expanded(child: _buildReportesList()),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHero(isMobile: false),
              const SizedBox(height: 20),
              _buildSummaryCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildFilters(),
              const SizedBox(height: 14),
              Expanded(child: _buildReportesList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConfig.azulOscuro, AppConfig.rojo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppConfig.rojo.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -24,
            child: Icon(
              Icons.flag_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.manage_search_rounded,
                text: 'Administración de reportes',
              ),
              const SizedBox(height: 18),
              Text(
                'Reportes ciudadanos',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Revisa, filtra, asigna y actualiza el estado de los reportes registrados.',
                style: TextStyle(
                  fontSize: isMobile ? 13.5 : 15.5,
                  height: 1.4,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.insights_rounded,
            title: 'Resumen',
            subtitle: 'Estado actual de reportes.',
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Total',
            value: '${_reportes.length}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Pendientes',
            value:
                '${_reportes.where((r) => r['estado'] == 'pendiente').length}',
            color: AppConfig.naranja,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'En revisión',
            value:
                '${_reportes.where((r) => r['estado'] == 'revision').length}',
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Resueltos',
            value:
                '${_reportes.where((r) => r['estado'] == 'resuelto').length}',
            color: AppConfig.verde,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final categorias =
        _reportes.map((r) => r['categoria'].toString()).toSet().toList();

    return _SoftCard(
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, color: AppConfig.azulOscuro),
              SizedBox(width: 8),
              Text(
                'Filtros de búsqueda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 540;

              if (stack) {
                return Column(
                  children: [
                    _estadoDropdown(),
                    const SizedBox(height: 12),
                    _categoriaDropdown(categorias),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _estadoDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _categoriaDropdown(categorias)),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por código, ubicación, categoría o funcionario...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (value) {
              setState(() => _buscarTexto = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _estadoDropdown() {
    return DropdownButtonFormField<String>(
      value: _filtroEstado.isEmpty ? null : _filtroEstado,
      hint: const Text('Estado'),
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: '', child: Text('Todos')),
        DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
        DropdownMenuItem(value: 'revision', child: Text('En revisión')),
        DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
      ],
      onChanged: (value) {
        setState(() => _filtroEstado = value ?? '');
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _categoriaDropdown(List<String> categorias) {
    return DropdownButtonFormField<String>(
      value: _filtroCategoria.isEmpty ? null : _filtroCategoria,
      hint: const Text('Categoría'),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: '', child: Text('Todas')),
        ...categorias.map(
          (categoria) => DropdownMenuItem(
            value: categoria,
            child: Text(categoria),
          ),
        ),
      ],
      onChanged: (value) {
        setState(() => _filtroCategoria = value ?? '');
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildReportesList() {
    if (_reportesFiltrados.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        text: 'No hay reportes que coincidan con los filtros seleccionados.',
      );
    }

    return ListView.builder(
      itemCount: _reportesFiltrados.length,
      itemBuilder: (context, index) {
        final reporte = _reportesFiltrados[index];

        return _ReporteCard(
          reporte: reporte,
          estadoText: _getEstadoText(reporte['estado']),
          prioridadText: _getPrioridadText(reporte['prioridad']),
          estadoColor: _getEstadoColor(reporte['estado']),
          prioridadColor: _getPrioridadColor(reporte['prioridad']),
          onTap: () => _mostrarDetalle(reporte),
        );
      },
    );
  }
}

class _ReporteCard extends StatelessWidget {
  final Map<String, dynamic> reporte;
  final String estadoText;
  final String prioridadText;
  final Color estadoColor;
  final Color prioridadColor;
  final VoidCallback onTap;

  const _ReporteCard({
    required this.reporte,
    required this.estadoText,
    required this.prioridadText,
    required this.estadoColor,
    required this.prioridadColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppConfig.grisMedio),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: estadoColor.withOpacity(0.12),
          child: Icon(Icons.flag_rounded, color: estadoColor),
        ),
        title: Text(
          reporte['codigo'],
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppConfig.azulOscuro,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reporte['ubicacion']),
              const SizedBox(height: 5),
              Text(
                reporte['funcionario'],
                style: TextStyle(
                  fontSize: 12,
                  color: AppConfig.grisOscuro,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(label: estadoText, color: estadoColor),
                  _StatusChip(label: prioridadText, color: prioridadColor),
                  Text(
                    reporte['categoria'],
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConfig.grisMedio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _CardHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppConfig.rojo.withOpacity(0.09),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.rojo),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: AppConfig.rojo),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConfig.grisOscuro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}