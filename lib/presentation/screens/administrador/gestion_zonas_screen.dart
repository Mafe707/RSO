import 'package:flutter/material.dart';

import '../../../config/app_config.dart';

class GestionZonasScreen extends StatefulWidget {
  const GestionZonasScreen({super.key});

  @override
  State<GestionZonasScreen> createState() => _GestionZonasScreenState();
}

class _GestionZonasScreenState extends State<GestionZonasScreen> {
  String _buscarTexto = '';

  final List<Map<String, dynamic>> _zonas = [
    {
      'nombre': 'Centro Histórico',
      'descripcion': 'Zona de alta actividad comercial y peatonal.',
      'reportes': 48,
      'funcionarios': 4,
      'prioridad': 'alta',
      'activo': true,
    },
    {
      'nombre': 'Avenida Los Estudiantes',
      'descripcion': 'Corredor universitario con reportes frecuentes.',
      'reportes': 24,
      'funcionarios': 2,
      'prioridad': 'media',
      'activo': true,
    },
    {
      'nombre': 'Barrio La Aurora',
      'descripcion': 'Zona residencial con baja recurrencia de reportes.',
      'reportes': 9,
      'funcionarios': 1,
      'prioridad': 'baja',
      'activo': true,
    },
    {
      'nombre': 'Sector Terminal',
      'descripcion': 'Zona con alta movilidad y ocupación temporal.',
      'reportes': 31,
      'funcionarios': 3,
      'prioridad': 'alta',
      'activo': false,
    },
  ];

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  List<Map<String, dynamic>> get _zonasFiltradas {
    if (_buscarTexto.isEmpty) return _zonas;

    final query = _buscarTexto.toLowerCase();

    return _zonas.where((zona) {
      return zona['nombre'].toString().toLowerCase().contains(query) ||
          zona['descripcion'].toString().toLowerCase().contains(query) ||
          zona['prioridad'].toString().toLowerCase().contains(query);
    }).toList();
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

  void _toggleZona(String nombre) {
    setState(() {
      final index = _zonas.indexWhere((zona) => zona['nombre'] == nombre);

      if (index != -1) {
        _zonas[index]['activo'] = !_zonas[index]['activo'];
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estado de la zona actualizado'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> zona) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final activo = zona['activo'] == true;

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
                        backgroundColor: _getPrioridadColor(
                          zona['prioridad'],
                        ).withOpacity(0.12),
                        child: Icon(
                          Icons.map_rounded,
                          color: _getPrioridadColor(zona['prioridad']),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              zona['nombre'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              zona['descripcion'],
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
                  _buildInfoRow('Reportes', zona['reportes'].toString()),
                  _buildInfoRow(
                    'Funcionarios',
                    zona['funcionarios'].toString(),
                  ),
                  _buildInfoRow(
                    'Prioridad',
                    _getPrioridadText(zona['prioridad']),
                  ),
                  _buildInfoRow('Estado', activo ? 'Activa' : 'Inactiva'),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleZona(zona['nombre']);
                      },
                      icon: Icon(
                        activo
                            ? Icons.block_rounded
                            : Icons.check_circle_rounded,
                      ),
                      label: Text(activo ? 'Desactivar zona' : 'Activar zona'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            activo ? AppConfig.rojo : AppConfig.verde,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
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
        _buildSearchCard(),
        const SizedBox(height: 12),
        Expanded(child: _buildZonasList()),
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
              _buildSearchCard(),
              const SizedBox(height: 14),
              Expanded(child: _buildZonasList()),
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
          colors: [AppConfig.azulOscuro, AppConfig.verde],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppConfig.verde.withOpacity(0.18),
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
              Icons.map_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.location_city_rounded,
                text: 'Gestión territorial',
              ),
              const SizedBox(height: 18),
              Text(
                'Zonas de atención',
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
                'Administra zonas, prioridades y cobertura operativa para la atención de reportes.',
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
    final activas = _zonas.where((zona) => zona['activo'] == true).length;
    final reportes = _zonas.fold<int>(
      0,
      (total, zona) => total + (zona['reportes'] as int),
    );

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.insights_rounded,
            title: 'Resumen',
            subtitle: 'Estado de cobertura por zonas.',
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Zonas registradas',
            value: '${_zonas.length}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Zonas activas',
            value: '$activas',
            color: AppConfig.verde,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Reportes asociados',
            value: '$reportes',
            color: AppConfig.rojo,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return _SoftCard(
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.search_rounded, color: AppConfig.azulOscuro),
              SizedBox(width: 8),
              Text(
                'Buscar zonas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, descripción o prioridad...',
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

  Widget _buildZonasList() {
    if (_zonasFiltradas.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        text: 'No hay zonas que coincidan con la búsqueda.',
      );
    }

    return ListView.builder(
      itemCount: _zonasFiltradas.length,
      itemBuilder: (context, index) {
        final zona = _zonasFiltradas[index];

        return _ZonaCard(
          zona: zona,
          prioridadText: _getPrioridadText(zona['prioridad']),
          prioridadColor: _getPrioridadColor(zona['prioridad']),
          onTap: () => _mostrarDetalle(zona),
          onToggle: () => _toggleZona(zona['nombre']),
        );
      },
    );
  }
}

class _ZonaCard extends StatelessWidget {
  final Map<String, dynamic> zona;
  final String prioridadText;
  final Color prioridadColor;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _ZonaCard({
    required this.zona,
    required this.prioridadText,
    required this.prioridadColor,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final activo = zona['activo'] == true;
    final estadoColor = activo ? AppConfig.verde : AppConfig.rojo;

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
          backgroundColor: prioridadColor.withOpacity(0.12),
          child: Icon(Icons.map_rounded, color: prioridadColor),
        ),
        title: Text(
          zona['nombre'],
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
              Text(zona['descripcion']),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(label: prioridadText, color: prioridadColor),
                  _StatusChip(
                    label: activo ? 'Activa' : 'Inactiva',
                    color: estadoColor,
                  ),
                  _StatusChip(
                    label: '${zona['reportes']} reportes',
                    color: AppConfig.azulClaro,
                  ),
                ],
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: Icon(
            activo ? Icons.block_rounded : Icons.check_circle_rounded,
            color: activo ? AppConfig.rojo : AppConfig.verde,
          ),
          onPressed: onToggle,
        ),
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
            color: AppConfig.verde.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.verde),
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
              Icon(icon, size: 54, color: AppConfig.verde),
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