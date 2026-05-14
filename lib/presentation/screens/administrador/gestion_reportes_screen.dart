import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/denuncia_service.dart';

class ValidacionReportesScreen extends StatefulWidget {
  const ValidacionReportesScreen({super.key});

  @override
  State<ValidacionReportesScreen> createState() =>
      _ValidacionReportesScreenState();
}

class _ValidacionReportesScreenState extends State<ValidacionReportesScreen> {
  String _filtroEstado = 'resuelto_pendiente_validacion';
  String _buscarTexto = '';
  bool _cargando = true;
  bool _recargando = false;
  List<Map<String, dynamic>> _reportes = [];

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes({bool silencioso = false}) async {
    if (silencioso) {
      setState(() => _recargando = true);
    } else {
      setState(() => _cargando = true);
    }

    final service = Provider.of<DenunciaService>(context, listen: false);
    final todos = await service.obtenerTodasDenuncias();

    if (!mounted) return;

    setState(() {
      _reportes = todos;
      _cargando = false;
      _recargando = false;
    });
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  List<Map<String, dynamic>> get _reportesFiltrados {
    return _reportes.where((r) {
      if (_filtroEstado.isNotEmpty && r['estado'] != _filtroEstado) {
        return false;
      }
      if (_buscarTexto.isNotEmpty) {
        final q = _buscarTexto.toLowerCase();
        return r['codigo_unico'].toString().toLowerCase().contains(q) ||
            r['ubicacion'].toString().toLowerCase().contains(q) ||
            r['categoria'].toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppConfig.naranja;
      case 'en_revision':
        return AppConfig.azulClaro;
      case 'resuelto_pendiente_validacion':
        return AppConfig.rojo;
      case 'devuelto':
        return const Color(0xFF9C27B0);
      case 'resuelto_publicado':
        return AppConfig.verde;
      default:
        return AppConfig.grisOscuro;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_revision':
        return 'En revisión';
      case 'resuelto_pendiente_validacion':
        return 'Pend. validación';
      case 'devuelto':
        return 'Devuelto';
      case 'resuelto_publicado':
        return 'Resuelto ✓';
      default:
        return estado;
    }
  }

  Future<void> _aprobarReporte(Map<String, dynamic> reporte) async {
    final service = Provider.of<DenunciaService>(context, listen: false);
    final ok = await service.actualizarEstado(
      reporte['id'] as int,
      'resuelto_publicado',
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reporte ${reporte['codigo_unico']} publicado correctamente',
          ),
          backgroundColor: AppConfig.verde,
        ),
      );
      _cargarReportes(silencioso: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al publicar el reporte'),
          backgroundColor: AppConfig.rojo,
        ),
      );
    }
  }

  Future<void> _devolverReporte(
    Map<String, dynamic> reporte,
    String motivo,
  ) async {
    try {
      final service = Provider.of<DenunciaService>(context, listen: false);
      await service.actualizarEstadoConRespuesta(
        reporte['id'] as int,
        'devuelto',
        motivo,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reporte ${reporte['codigo_unico']} devuelto al funcionario',
          ),
          backgroundColor: const Color(0xFF9C27B0),
        ),
      );
      _cargarReportes(silencioso: true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al devolver: $e'),
          backgroundColor: AppConfig.rojo,
        ),
      );
    }
  }

  void _mostrarDetalle(Map<String, dynamic> reporte) {
    final estado = reporte['estado']?.toString() ?? '';
    final esPendienteValidacion = estado == 'resuelto_pendiente_validacion';
    final motivoController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
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
                              _getEstadoColor(estado).withOpacity(0.12),
                          child: Icon(
                            Icons.fact_check_rounded,
                            color: _getEstadoColor(estado),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reporte['codigo_unico'] ?? '—',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppConfig.azulOscuro,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reporte['ubicacion'] ?? '—',
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
                    _buildInfoRow('Categoría', reporte['categoria'] ?? '—'),
                    _buildInfoRow('Descripción', reporte['descripcion'] ?? '—'),
                    _buildInfoRow('Estado', _getEstadoText(estado)),
                    _buildInfoRow('Fecha', _formatFecha(reporte['creado_en'])),
                    if (reporte['respuesta_oficial'] != null &&
                        reporte['respuesta_oficial'].toString().isNotEmpty)
                      _buildInfoRow(
                        'Respuesta funcionario',
                        reporte['respuesta_oficial'],
                      ),
                    if (esPendienteValidacion) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'Motivo de devolución (opcional)',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppConfig.azulOscuro,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: motivoController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText:
                              'Explica por qué se devuelve al funcionario...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isNarrow = constraints.maxWidth < 430;

                          final aprobarBtn = ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _aprobarReporte(reporte);
                            },
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('Aprobar y publicar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConfig.verde,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );

                          final devolverBtn = ElevatedButton.icon(
                            onPressed: () {
                              final motivo = motivoController.text.trim();
                              Navigator.pop(ctx);
                              _devolverReporte(reporte, motivo);
                            },
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Devolver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9C27B0),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          );

                          if (isNarrow) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: aprobarBtn,
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: devolverBtn,
                                ),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: aprobarBtn),
                              const SizedBox(width: 12),
                              Expanded(child: devolverBtn),
                            ],
                          );
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _getEstadoColor(estado).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_rounded,
                              color: _getEstadoColor(estado),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Este reporte está en estado "${_getEstadoText(estado)}". Solo se puede validar cuando esté en "Pend. validación".',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _getEstadoColor(estado),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      final dt = DateTime.parse(fecha.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha.toString();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppConfig.grisOscuro,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
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

    if (isMobile) {
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(isMobile: true),
              const SizedBox(height: 16),
              _buildResumen(),
              const SizedBox(height: 16),
              _buildFiltros(true),
              const SizedBox(height: 12),
              _buildLista(),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(isMobile: false),
                    const SizedBox(height: 20),
                    _buildResumen(),
                    const SizedBox(height: 20),
                    _buildFiltros(false),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: _buildLista(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
        boxShadow: [
          BoxShadow(
            color: AppConfig.azulClaro.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -5,
            bottom: -12,
            child: Icon(
              Icons.fact_check_rounded,
              size: isMobile ? 80 : 110,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Expanded(
                    child: _HeroBadge(
                      icon: Icons.fact_check_rounded,
                      text: 'Validación de Reportes',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Validación de Reportes',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aprueba o devuelve respuestas oficiales de funcionarios.',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14.5,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumen() {
    final pendVal = _reportes
        .where((r) => r['estado'] == 'resuelto_pendiente_validacion')
        .length;
    final aprobados = _reportes
        .where((r) => r['estado'] == 'resuelto_publicado')
        .length;
    final devueltos = _reportes.where((r) => r['estado'] == 'devuelto').length;

    final isMobile = _isMobile(context);

    final cards = [
      _SummaryRow(
        label: 'Pend. validación',
        value: '$pendVal',
        color: AppConfig.rojo,
      ),
      _SummaryRow(
        label: 'Publicados',
        value: '$aprobados',
        color: AppConfig.verde,
      ),
      _SummaryRow(
        label: 'Devueltos',
        value: '$devueltos',
        color: const Color(0xFF9C27B0),
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            SizedBox(width: double.infinity, child: cards[i]),
            if (i != cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildFiltros(bool isMobile) {
    final filtros = [
      {'label': 'Todos', 'value': ''},
      {'label': 'Pend. val.', 'value': 'resuelto_pendiente_validacion'},
      {'label': 'Publicados', 'value': 'resuelto_publicado'},
      {'label': 'Devueltos', 'value': 'devuelto'},
      {'label': 'En revisión', 'value': 'en_revision'},
      {'label': 'Pendiente', 'value': 'pendiente'},
    ];

    Widget buscador = SizedBox(
      height: 44,
      child: TextField(
        onChanged: (v) => setState(() => _buscarTexto = v),
        decoration: InputDecoration(
          hintText: 'Buscar...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConfig.grisMedio),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConfig.grisMedio),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConfig.azulClaro),
          ),
          isDense: true,
        ),
      ),
    );

    Widget chipsWrap = Wrap(
      spacing: 6,
      runSpacing: 8,
      children: filtros.map((f) {
        final selected = _filtroEstado == f['value'];
        return FilterChip(
          label: Text(
            f['label']!,
            style: const TextStyle(fontSize: 12),
          ),
          selected: selected,
          onSelected: (_) => setState(() => _filtroEstado = f['value']!),
          selectedColor: AppConfig.rojo.withOpacity(0.15),
          checkmarkColor: AppConfig.rojo,
          visualDensity: VisualDensity.compact,
          labelStyle: TextStyle(
            color: selected ? AppConfig.rojo : AppConfig.grisOscuro,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        );
      }).toList(),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buscador,
          const SizedBox(height: 12),
          chipsWrap,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: buscador),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filtros.map((f) {
                final selected = _filtroEstado == f['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      f['label']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _filtroEstado = f['value']!),
                    selectedColor: AppConfig.rojo.withOpacity(0.15),
                    checkmarkColor: AppConfig.rojo,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      color: selected ? AppConfig.rojo : AppConfig.grisOscuro,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLista() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_reportesFiltrados.isEmpty) {
      return _SoftCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.fact_check_rounded,
                  size: 54,
                  color: AppConfig.rojo,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sin resultados',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppConfig.azulOscuro,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No hay reportes que coincidan con los filtros.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConfig.grisOscuro),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: _isMobile(context)
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: _reportesFiltrados.length,
      itemBuilder: (context, index) {
        final r = _reportesFiltrados[index];
        final estado = r['estado']?.toString() ?? '';
        final color = _getEstadoColor(estado);

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
              child: Icon(Icons.fact_check_rounded, color: color),
            ),
            title: Text(
              r['codigo_unico'] ?? '—',
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
                  Text(r['ubicacion'] ?? '—'),
                  const SizedBox(height: 4),
                  Text(
                    r['categoria'] ?? '—',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConfig.grisOscuro,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _StatusChip(label: _getEstadoText(estado), color: color),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: _isMobile(context)
                ? Icon(
                    estado == 'resuelto_pendiente_validacion'
                        ? Icons.fact_check_rounded
                        : Icons.chevron_right_rounded,
                    color: estado == 'resuelto_pendiente_validacion'
                        ? AppConfig.rojo
                        : AppConfig.grisOscuro,
                  )
                : estado == 'resuelto_pendiente_validacion'
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConfig.rojo.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'REVISAR',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppConfig.rojo,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      )
                    : const Icon(Icons.chevron_right_rounded),
            onTap: () => _mostrarDetalle(r),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
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

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}