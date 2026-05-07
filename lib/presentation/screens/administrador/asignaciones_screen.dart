import 'package:flutter/material.dart';

import '../../../config/app_config.dart';

class AsignacionesScreen extends StatefulWidget {
  const AsignacionesScreen({super.key});

  @override
  State<AsignacionesScreen> createState() => _AsignacionesScreenState();
}

class _AsignacionesScreenState extends State<AsignacionesScreen> {
  String _filtroEstado = '';
  String _buscarTexto = '';

  final List<Map<String, dynamic>> _asignaciones = [
    {
      'codigo': 'PSJ-8A4B2C9D',
      'reporte': 'Venta informal en el centro',
      'ubicacion': 'Cra 25 #18-35, Centro',
      'funcionario': 'Carlos Martínez',
      'zona': 'Centro Histórico',
      'estado': 'pendiente',
      'fecha': '05/09/2025',
      'prioridad': 'alta',
    },
    {
      'codigo': 'PSJ-123ABC',
      'reporte': 'Vehículo sobre andén',
      'ubicacion': 'Calle 19 #24-50',
      'funcionario': 'Ana Gómez',
      'zona': 'Zona Norte',
      'estado': 'revision',
      'fecha': '10/09/2025',
      'prioridad': 'media',
    },
    {
      'codigo': 'PSJ-456DEF',
      'reporte': 'Ocupación comercial',
      'ubicacion': 'Av. Los Estudiantes',
      'funcionario': 'María Rodríguez',
      'zona': 'Avenida Los Estudiantes',
      'estado': 'resuelto',
      'fecha': '01/09/2025',
      'prioridad': 'baja',
    },
    {
      'codigo': 'PSJ-789GHI',
      'reporte': 'Publicidad no autorizada',
      'ubicacion': 'Transversal 23',
      'funcionario': 'Luis Herrera',
      'zona': 'Sector Terminal',
      'estado': 'pendiente',
      'fecha': '12/09/2025',
      'prioridad': 'alta',
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

  List<Map<String, dynamic>> get _asignacionesFiltradas {
    return _asignaciones.where((asignacion) {
      if (_filtroEstado.isNotEmpty &&
          asignacion['estado'] != _filtroEstado) {
        return false;
      }

      if (_buscarTexto.isNotEmpty) {
        final query = _buscarTexto.toLowerCase();

        return asignacion['codigo'].toString().toLowerCase().contains(query) ||
            asignacion['reporte'].toString().toLowerCase().contains(query) ||
            asignacion['ubicacion'].toString().toLowerCase().contains(query) ||
            asignacion['funcionario']
                .toString()
                .toLowerCase()
                .contains(query) ||
            asignacion['zona'].toString().toLowerCase().contains(query);
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

  void _reasignar(String codigo, String funcionario) {
    setState(() {
      final index = _asignaciones.indexWhere((a) => a['codigo'] == codigo);

      if (index != -1) {
        _asignaciones[index]['funcionario'] = funcionario;
        _asignaciones[index]['estado'] = 'revision';
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Asignación $codigo actualizada correctamente'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  void _cambiarEstado(String codigo, String estado) {
    setState(() {
      final index = _asignaciones.indexWhere((a) => a['codigo'] == codigo);

      if (index != -1) {
        _asignaciones[index]['estado'] = estado;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado de $codigo actualizado correctamente'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> asignacion) {
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
                        radius: 30,
                        backgroundColor: _getEstadoColor(
                          asignacion['estado'],
                        ).withOpacity(0.12),
                        child: Icon(
                          Icons.assignment_rounded,
                          color: _getEstadoColor(asignacion['estado']),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              asignacion['codigo'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              asignacion['reporte'],
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
                  _buildInfoRow('Ubicación', asignacion['ubicacion']),
                  _buildInfoRow('Funcionario', asignacion['funcionario']),
                  _buildInfoRow('Zona', asignacion['zona']),
                  _buildInfoRow('Fecha', asignacion['fecha']),
                  _buildInfoRow(
                    'Estado',
                    _getEstadoText(asignacion['estado']),
                  ),
                  _buildInfoRow(
                    'Prioridad',
                    _getPrioridadText(asignacion['prioridad']),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Reasignar funcionario',
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
                      _reasignar(asignacion['codigo'], value);
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
                                    asignacion['codigo'],
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
                                    asignacion['codigo'],
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
                                _cambiarEstado(
                                  asignacion['codigo'],
                                  'revision',
                                );
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
                                _cambiarEstado(
                                  asignacion['codigo'],
                                  'resuelto',
                                );
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
        Expanded(child: _buildAsignacionesList()),
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
              Expanded(child: _buildAsignacionesList()),
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
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppConfig.azulOscuro.withOpacity(0.18),
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
              Icons.assignment_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.assignment_ind_rounded,
                text: 'Control de asignaciones',
              ),
              const SizedBox(height: 18),
              Text(
                'Asignaciones operativas',
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
                'Revisa qué funcionario atiende cada reporte y reasigna casos cuando sea necesario.',
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
            subtitle: 'Estado actual de asignaciones.',
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Total',
            value: '${_asignaciones.length}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Pendientes',
            value:
                '${_asignaciones.where((a) => a['estado'] == 'pendiente').length}',
            color: AppConfig.naranja,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'En revisión',
            value:
                '${_asignaciones.where((a) => a['estado'] == 'revision').length}',
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Resueltos',
            value:
                '${_asignaciones.where((a) => a['estado'] == 'resuelto').length}',
            color: AppConfig.verde,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
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
          DropdownButtonFormField<String>(
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
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por código, reporte, zona o funcionario...',
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

  Widget _buildAsignacionesList() {
    if (_asignacionesFiltradas.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        text: 'No hay asignaciones que coincidan con los filtros seleccionados.',
      );
    }

    return ListView.builder(
      itemCount: _asignacionesFiltradas.length,
      itemBuilder: (context, index) {
        final asignacion = _asignacionesFiltradas[index];

        return _AsignacionCard(
          asignacion: asignacion,
          estadoText: _getEstadoText(asignacion['estado']),
          prioridadText: _getPrioridadText(asignacion['prioridad']),
          estadoColor: _getEstadoColor(asignacion['estado']),
          prioridadColor: _getPrioridadColor(asignacion['prioridad']),
          onTap: () => _mostrarDetalle(asignacion),
        );
      },
    );
  }
}

class _AsignacionCard extends StatelessWidget {
  final Map<String, dynamic> asignacion;
  final String estadoText;
  final String prioridadText;
  final Color estadoColor;
  final Color prioridadColor;
  final VoidCallback onTap;

  const _AsignacionCard({
    required this.asignacion,
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
          child: Icon(Icons.assignment_rounded, color: estadoColor),
        ),
        title: Text(
          asignacion['codigo'],
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
              Text(asignacion['reporte']),
              const SizedBox(height: 4),
              Text(
                '${asignacion['funcionario']} · ${asignacion['zona']}',
                style: TextStyle(
                  fontSize: 12.5,
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
            color: AppConfig.azulClaro.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.azulClaro),
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
              Icon(icon, size: 54, color: AppConfig.azulClaro),
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