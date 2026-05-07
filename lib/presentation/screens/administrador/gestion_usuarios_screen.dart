import 'package:flutter/material.dart';

import '../../../config/app_config.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  String _filtroEstado = '';
  String _buscarTexto = '';

  final List<Map<String, dynamic>> _usuarios = [
    {
      'nombre': 'Carlos Martínez',
      'correo': 'carlos.martinez@alcaldia.gov.co',
      'cargo': 'Inspector de Espacio Público',
      'departamento': 'Control Urbano',
      'rol': 'Funcionario',
      'activo': true,
      'casos': 8,
    },
    {
      'nombre': 'Ana Gómez',
      'correo': 'ana.gomez@alcaldia.gov.co',
      'cargo': 'Coordinadora de Inspección',
      'departamento': 'Planeación Urbana',
      'rol': 'Funcionario',
      'activo': true,
      'casos': 12,
    },
    {
      'nombre': 'Luis Herrera',
      'correo': 'luis.herrera@alcaldia.gov.co',
      'cargo': 'Auxiliar Administrativo',
      'departamento': 'Movilidad',
      'rol': 'Funcionario',
      'activo': false,
      'casos': 2,
    },
    {
      'nombre': 'María Rodríguez',
      'correo': 'maria.rodriguez@alcaldia.gov.co',
      'cargo': 'Inspectora Municipal',
      'departamento': 'Espacio Público',
      'rol': 'Funcionario',
      'activo': true,
      'casos': 5,
    },
  ];

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  List<Map<String, dynamic>> get _usuariosFiltrados {
    return _usuarios.where((usuario) {
      if (_filtroEstado.isNotEmpty) {
        final activo = usuario['activo'] == true;

        if (_filtroEstado == 'activo' && !activo) return false;
        if (_filtroEstado == 'inactivo' && activo) return false;
      }

      if (_buscarTexto.isNotEmpty) {
        final query = _buscarTexto.toLowerCase();

        return usuario['nombre'].toString().toLowerCase().contains(query) ||
            usuario['correo'].toString().toLowerCase().contains(query) ||
            usuario['cargo'].toString().toLowerCase().contains(query) ||
            usuario['departamento'].toString().toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  void _toggleEstado(String correo) {
    setState(() {
      final index = _usuarios.indexWhere((f) => f['correo'] == correo);

      if (index != -1) {
        _usuarios[index]['activo'] = !_usuarios[index]['activo'];
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estado del usuario actualizado'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> usuario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final activo = usuario['activo'] == true;

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
                        backgroundColor:
                            (activo ? AppConfig.verde : AppConfig.rojo)
                                .withOpacity(0.12),
                        child: Text(
                          usuario['nombre']
                              .toString()
                              .substring(0, 1)
                              .toUpperCase(),
                          style: TextStyle(
                            color: activo ? AppConfig.verde : AppConfig.rojo,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario['nombre'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              usuario['correo'],
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
                  _buildInfoRow('Cargo', usuario['cargo']),
                  _buildInfoRow('Departamento', usuario['departamento']),
                  _buildInfoRow('Rol', usuario['rol']),
                  _buildInfoRow('Estado', activo ? 'Activo' : 'Inactivo'),
                  _buildInfoRow('Casos asignados', usuario['casos'].toString()),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleEstado(usuario['correo']);
                      },
                      icon: Icon(
                        activo
                            ? Icons.block_rounded
                            : Icons.check_circle_rounded,
                      ),
                      label: Text(
                        activo ? 'Desactivar usuario' : 'Activar usuario',
                      ),
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
        _buildFilters(),
        const SizedBox(height: 12),
        Expanded(child: _buildUsuariosList()),
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
              Expanded(child: _buildUsuariosList()),
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
              Icons.people_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.manage_accounts_rounded,
                text: 'Administración de usuarios',
              ),
              const SizedBox(height: 18),
              Text(
                'Usuarios del sistema',
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
                'Consulta el estado de los funcionarios y administra su disponibilidad en el sistema.',
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
    final activos = _usuarios.where((u) => u['activo'] == true).length;
    final inactivos = _usuarios.length - activos;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.insights_rounded,
            title: 'Resumen',
            subtitle: 'Estado del equipo registrado.',
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Total',
            value: '${_usuarios.length}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Activos',
            value: '$activos',
            color: AppConfig.verde,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Inactivos',
            value: '$inactivos',
            color: AppConfig.rojo,
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
              DropdownMenuItem(value: 'activo', child: Text('Activos')),
              DropdownMenuItem(value: 'inactivo', child: Text('Inactivos')),
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
              hintText: 'Buscar por nombre, correo, cargo o departamento...',
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

  Widget _buildUsuariosList() {
    if (_usuariosFiltrados.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin resultados',
        text: 'No hay usuarios que coincidan con los filtros seleccionados.',
      );
    }

    return ListView.builder(
      itemCount: _usuariosFiltrados.length,
      itemBuilder: (context, index) {
        final usuario = _usuariosFiltrados[index];

        return _UsuarioCard(
          usuario: usuario,
          onTap: () => _mostrarDetalle(usuario),
          onToggle: () => _toggleEstado(usuario['correo']),
        );
      },
    );
  }
}

class _UsuarioCard extends StatelessWidget {
  final Map<String, dynamic> usuario;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _UsuarioCard({
    required this.usuario,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final activo = usuario['activo'] == true;
    final color = activo ? AppConfig.verde : AppConfig.rojo;

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
          backgroundColor: color.withOpacity(0.12),
          child: Text(
            usuario['nombre'].toString().substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        title: Text(
          usuario['nombre'],
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
              Text(usuario['correo']),
              const SizedBox(height: 4),
              Text(
                usuario['cargo'],
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
                  _StatusChip(
                    label: activo ? 'Activo' : 'Inactivo',
                    color: color,
                  ),
                  _StatusChip(
                    label: '${usuario['casos']} casos',
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