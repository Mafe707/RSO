import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';

class MisCasosScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MisCasosScreen({
    super.key,
    required this.userData,
  });

  @override
  State<MisCasosScreen> createState() => _MisCasosScreenState();
}

class _MisCasosScreenState extends State<MisCasosScreen> {
  String _filtroEstado = '';
  String _filtroPrioridad = '';
  String _buscarTexto = '';

  final List<Map<String, dynamic>> _casos = [
    {
      'id': 'PSJ-8A4B2C9D',
      'fecha': '05/09/2025',
      'categoria': 'Venta informal',
      'ubicacion': 'Cra 25 #18-35',
      'prioridad': 'alta',
      'estado': 'revision',
    },
    {
      'id': 'PSJ-123ABC',
      'fecha': '10/09/2025',
      'categoria': 'Invasión vehicular',
      'ubicacion': 'Calle 19 #24-50',
      'prioridad': 'media',
      'estado': 'pendiente',
    },
    {
      'id': 'PSJ-456DEF',
      'fecha': '01/09/2025',
      'categoria': 'Ocupación comercial',
      'ubicacion': 'Av. Los Estudiantes',
      'prioridad': 'baja',
      'estado': 'resuelto',
    },
    {
      'id': 'PSJ-789GHI',
      'fecha': '12/09/2025',
      'categoria': 'Publicidad no autorizada',
      'ubicacion': 'Transversal 23',
      'prioridad': 'alta',
      'estado': 'pendiente',
    },
    {
      'id': 'PSJ-321JKL',
      'fecha': '08/09/2025',
      'categoria': 'Otro',
      'ubicacion': 'Calle 25 #30-15',
      'prioridad': 'media',
      'estado': 'revision',
    },
  ];

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
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

      if (_filtroPrioridad.isNotEmpty &&
          caso['prioridad'] != _filtroPrioridad) {
        return false;
      }

      if (_buscarTexto.isNotEmpty) {
        return caso['id']
                .toString()
                .toLowerCase()
                .contains(_buscarTexto.toLowerCase()) ||
            caso['ubicacion']
                .toString()
                .toLowerCase()
                .contains(_buscarTexto.toLowerCase());
      }

      return true;
    }).toList();
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

  void _verDetalles(Map<String, dynamic> caso) {
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
                      Container(
                        width: 8,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _getEstadoColor(caso['estado']),
                          borderRadius: BorderRadius.circular(4),
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
                              caso['ubicacion'],
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
                  const SizedBox(height: 18),
                  const Divider(),
                  _buildInfoRow('Ubicación', caso['ubicacion']),
                  _buildInfoRow('Categoría', caso['categoria']),
                  _buildInfoRow('Fecha', caso['fecha']),
                  _buildInfoRow(
                    'Prioridad',
                    _getPrioridadText(caso['prioridad']),
                  ),
                  _buildInfoRow('Estado', _getEstadoText(caso['estado'])),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackButtons = constraints.maxWidth < 420;

                      if (stackButtons) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _cambiarEstado(caso['id'], 'revision'),
                                icon: const Icon(
                                  Icons.pending_actions_rounded,
                                ),
                                label: const Text('En revisión'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.azulClaro,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _cambiarEstado(caso['id'], 'resuelto'),
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text('Resolver'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.verde,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _cambiarEstado(caso['id'], 'revision'),
                              icon: const Icon(Icons.pending_actions_rounded),
                              label: const Text('En revisión'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.azulClaro,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _cambiarEstado(caso['id'], 'resuelto'),
                              icon: const Icon(Icons.check_circle_rounded),
                              label: const Text('Resolver'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.verde,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cerrar'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _cambiarEstado(String id, String nuevoEstado) {
    setState(() {
      final index = _casos.indexWhere((caso) => caso['id'] == id);

      if (index != -1) {
        _casos[index]['estado'] = nuevoEstado;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Caso $id actualizado a ${_getEstadoText(nuevoEstado)}',
        ),
        backgroundColor: AppConfig.verde,
      ),
    );

    Navigator.pop(context);
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mis Casos',
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
        currentIndex: 1,
        userData: widget.userData,
      ),
      bottomNavigationBar: FuncionarioBottomNav.maybe(
        context,
        currentIndex: 1,
      ),
      body: SafeArea(
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
        Expanded(child: _buildCasosList()),
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
              Expanded(child: _buildCasosList()),
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
                icon: Icons.assignment_turned_in_rounded,
                text: 'Gestión de casos',
              ),
              const SizedBox(height: 18),
              Text(
                'Mis casos asignados',
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
                'Consulta, filtra y actualiza el estado de los reportes que tienes asignados.',
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
            subtitle: 'Vista rápida de tus casos.',
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Total',
            value: '${_casos.length}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Pendientes',
            value:
                '${_casos.where((caso) => caso['estado'] == 'pendiente').length}',
            color: AppConfig.naranja,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'En revisión',
            value:
                '${_casos.where((caso) => caso['estado'] == 'revision').length}',
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Resueltos',
            value:
                '${_casos.where((caso) => caso['estado'] == 'resuelto').length}',
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
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 520;

              if (stack) {
                return Column(
                  children: [
                    _estadoDropdown(),
                    const SizedBox(height: 12),
                    _prioridadDropdown(),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: _estadoDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _prioridadDropdown()),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por ID o ubicación...',
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

  Widget _prioridadDropdown() {
    return DropdownButtonFormField<String>(
      value: _filtroPrioridad.isEmpty ? null : _filtroPrioridad,
      hint: const Text('Prioridad'),
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: '', child: Text('Todas')),
        DropdownMenuItem(value: 'alta', child: Text('Alta')),
        DropdownMenuItem(value: 'media', child: Text('Media')),
        DropdownMenuItem(value: 'baja', child: Text('Baja')),
      ],
      onChanged: (value) {
        setState(() => _filtroPrioridad = value ?? '');
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

  Widget _buildCasosList() {
    if (_casosFiltrados.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        text: 'No hay casos que coincidan con los filtros seleccionados.',
      );
    }

    return ListView.builder(
      itemCount: _casosFiltrados.length,
      itemBuilder: (context, index) {
        final caso = _casosFiltrados[index];

        return _CaseCard(
          caso: caso,
          estadoText: _getEstadoText(caso['estado']),
          prioridadText: _getPrioridadText(caso['prioridad']),
          estadoColor: _getEstadoColor(caso['estado']),
          prioridadColor: _getPrioridadColor(caso['prioridad']),
          onTap: () => _verDetalles(caso),
        );
      },
    );
  }
}

class _CaseCard extends StatelessWidget {
  final Map<String, dynamic> caso;
  final String estadoText;
  final String prioridadText;
  final Color estadoColor;
  final Color prioridadColor;
  final VoidCallback onTap;

  const _CaseCard({
    required this.caso,
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
          caso['id'],
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
              Text(caso['ubicacion']),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(label: estadoText, color: estadoColor),
                  _StatusChip(label: prioridadText, color: prioridadColor),
                  Text(
                    caso['categoria'],
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
            color: AppConfig.azulOscuro.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.azulOscuro),
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