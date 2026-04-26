import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/auth_service.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';

class CasosAsignadosScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CasosAsignadosScreen({
    super.key,
    this.userData,
  });

  @override
  State<CasosAsignadosScreen> createState() => _CasosAsignadosScreenState();
}

class _CasosAsignadosScreenState extends State<CasosAsignadosScreen> {
  String _filtroEstado = '';

  final List<Map<String, dynamic>> _casosAsignados = [
    {
      'id': 'PSJ-8A4B2C9D',
      'fecha': '05/09/2025',
      'categoria': 'Venta informal',
      'ubicacion': 'Cra 25 #18-35',
      'estado': 'revision',
      'prioridad': 'alta',
    },
    {
      'id': 'PSJ-123ABC',
      'fecha': '10/09/2025',
      'categoria': 'Invasión vehicular',
      'ubicacion': 'Calle 19 #24-50',
      'estado': 'pendiente',
      'prioridad': 'media',
    },
    {
      'id': 'PSJ-456DEF',
      'fecha': '01/09/2025',
      'categoria': 'Ocupación comercial',
      'ubicacion': 'Av. Los Estudiantes',
      'estado': 'resuelto',
      'prioridad': 'baja',
    },
  ];

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  Map<String, dynamic> _buildUserData(BuildContext context) {
    if (widget.userData != null) {
      return widget.userData!;
    }

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
    if (_filtroEstado.isEmpty) return _casosAsignados;

    return _casosAsignados
        .where((caso) => caso['estado'] == _filtroEstado)
        .toList();
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

  void _cambiarEstado(String id, String nuevoEstado) {
    setState(() {
      final index = _casosAsignados.indexWhere((caso) => caso['id'] == id);

      if (index != -1) {
        _casosAsignados[index]['estado'] = nuevoEstado;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Caso $id actualizado correctamente'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> caso) {
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
                        backgroundColor:
                            _getEstadoColor(caso['estado']).withOpacity(0.12),
                        child: Icon(
                          Icons.assignment_rounded,
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
                  const Divider(height: 30),
                  _buildInfoRow('Fecha', caso['fecha']),
                  _buildInfoRow('Categoría', caso['categoria']),
                  _buildInfoRow('Ubicación', caso['ubicacion']),
                  _buildInfoRow('Estado', _getEstadoText(caso['estado'])),
                  _buildInfoRow(
                    'Prioridad',
                    _getPrioridadText(caso['prioridad']),
                  ),
                  const SizedBox(height: 20),
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
                                  _cambiarEstado(caso['id'], 'revision');
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
                                  _cambiarEstado(caso['id'], 'resuelto');
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
                                _cambiarEstado(caso['id'], 'revision');
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
                                _cambiarEstado(caso['id'], 'resuelto');
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
          'Casos Asignados',
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
        userData: userData,
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
        _buildFilterCard(),
        const SizedBox(height: 12),
        Expanded(child: _buildCasesList()),
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
              _buildFilterCard(),
              const SizedBox(height: 14),
              Expanded(child: _buildCasesList()),
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
              Icons.assignment_turned_in_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.verified_rounded,
                text: 'Casos asignados',
              ),
              const SizedBox(height: 18),
              Text(
                'Seguimiento de casos',
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
                'Gestiona los casos asignados y actualiza su estado de atención.',
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
            subtitle: 'Estado actual de tus casos asignados.',
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Total',
            value: '${_casosAsignados.length}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Pendientes',
            value:
                '${_casosAsignados.where((c) => c['estado'] == 'pendiente').length}',
            color: AppConfig.naranja,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'En revisión',
            value:
                '${_casosAsignados.where((c) => c['estado'] == 'revision').length}',
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Resueltos',
            value:
                '${_casosAsignados.where((c) => c['estado'] == 'resuelto').length}',
            color: AppConfig.verde,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard() {
    return _SoftCard(
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, color: AppConfig.azulOscuro),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _filtroEstado.isEmpty ? null : _filtroEstado,
              hint: const Text('Filtrar por estado'),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: const [
                DropdownMenuItem(value: '', child: Text('Todos')),
                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                DropdownMenuItem(value: 'revision', child: Text('En revisión')),
                DropdownMenuItem(value: 'resuelto', child: Text('Resuelto')),
              ],
              onChanged: (value) {
                setState(() => _filtroEstado = value ?? '');
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCasesList() {
    if (_casosFiltrados.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin casos',
        text: 'No hay casos asignados con ese estado.',
      );
    }

    return ListView.builder(
      itemCount: _casosFiltrados.length,
      itemBuilder: (context, index) {
        final caso = _casosFiltrados[index];

        return _AssignedCaseCard(
          caso: caso,
          estadoText: _getEstadoText(caso['estado']),
          estadoColor: _getEstadoColor(caso['estado']),
          prioridadText: _getPrioridadText(caso['prioridad']),
          prioridadColor: _getPrioridadColor(caso['prioridad']),
          onTap: () => _mostrarDetalle(caso),
        );
      },
    );
  }
}

class _AssignedCaseCard extends StatelessWidget {
  final Map<String, dynamic> caso;
  final String estadoText;
  final Color estadoColor;
  final String prioridadText;
  final Color prioridadColor;
  final VoidCallback onTap;

  const _AssignedCaseCard({
    required this.caso,
    required this.estadoText,
    required this.estadoColor,
    required this.prioridadText,
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