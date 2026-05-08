import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/denuncia_service.dart';

class ValidacionReportesScreen extends StatefulWidget {
  const ValidacionReportesScreen({super.key});

  @override
  State<ValidacionReportesScreen> createState() => _ValidacionReportesScreenState();
}

class _ValidacionReportesScreenState extends State<ValidacionReportesScreen> {
  String _filtroEstado = 'resuelto_pendiente_validacion';
  String _buscarTexto = '';
  bool _cargando = true;
  List<Map<String, dynamic>> _reportes = [];

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() => _cargando = true);
    final service = Provider.of<DenunciaService>(context, listen: false);
    final todos = await service.obtenerTodasDenuncias();
    if (!mounted) return;
    setState(() {
      _reportes = todos;
      _cargando = false;
    });
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  List<Map<String, dynamic>> get _reportesFiltrados {
    return _reportes.where((r) {
      if (_filtroEstado.isNotEmpty && r['estado'] != _filtroEstado) return false;
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
      case 'pendiente': return AppConfig.naranja;
      case 'en_revision': return AppConfig.azulClaro;
      case 'resuelto_pendiente_validacion': return AppConfig.rojo;
      case 'devuelto': return const Color(0xFF9C27B0);
      case 'resuelto_publicado': return AppConfig.verde;
      default: return AppConfig.grisOscuro;
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'en_revision': return 'En revisión';
      case 'resuelto_pendiente_validacion': return 'Pend. validación';
      case 'devuelto': return 'Devuelto';
      case 'resuelto_publicado': return 'Resuelto ✓';
      default: return estado;
    }
  }

  Future<void> _aprobarReporte(Map<String, dynamic> reporte) async {
    final service = Provider.of<DenunciaService>(context, listen: false);
    final ok = await service.actualizarEstado(reporte['id'] as int, 'resuelto_publicado');
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte ${reporte['codigo_unico']} publicado correctamente'),
          backgroundColor: AppConfig.verde,
        ),
      );
      _cargarReportes();
    }
  }

  Future<void> _devolverReporte(Map<String, dynamic> reporte, String motivo) async {
    final service = Provider.of<DenunciaService>(context, listen: false);
    await service.actualizarEstadoConRespuesta(
      reporte['id'] as int,
      'devuelto',
      motivo,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte ${reporte['codigo_unico']} devuelto al funcionario'),
        backgroundColor: const Color(0xFF9C27B0),
      ),
    );
    _cargarReportes();
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
                      width: 46, height: 5,
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
                        backgroundColor: _getEstadoColor(estado).withOpacity(0.12),
                        child: Icon(Icons.fact_check_rounded, color: _getEstadoColor(estado)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reporte['codigo_unico'] ?? '—',
                              style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              reporte['ubicacion'] ?? '—',
                              style: TextStyle(color: AppConfig.grisOscuro, fontSize: 13),
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
                    _buildInfoRow('Respuesta funcionario', reporte['respuesta_oficial']),

                  if (esPendienteValidacion) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Motivo de devolución (opcional)',
                      style: TextStyle(
                        fontWeight: FontWeight.w900, color: AppConfig.azulOscuro, fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: motivoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Explica por qué se devuelve al funcionario...',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(builder: (context, constraints) {
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                      final devolverBtn = ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _devolverReporte(reporte, motivoController.text.trim());
                        },
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Devolver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9C27B0),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );

                      if (isNarrow) {
                        return Column(children: [
                          SizedBox(width: double.infinity, child: aprobarBtn),
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: devolverBtn),
                        ]);
                      }
                      return Row(children: [
                        Expanded(child: aprobarBtn),
                        const SizedBox(width: 12),
                        Expanded(child: devolverBtn),
                      ]);
                    }),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatFecha(dynamic valor) {
    if (valor == null) return '—';
    try {
      final dt = DateTime.parse(valor.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return valor.toString();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text('$label:', style: const TextStyle(
              fontWeight: FontWeight.w800, color: Colors.black87,
            )),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppConfig.grisOscuro, height: 1.35)),
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
        Expanded(child: _buildLista()),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: Column(children: [
          _buildHero(isMobile: false),
          const SizedBox(height: 20),
          _buildResumenCard(),
        ])),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: Column(children: [
          _buildFilters(),
          const SizedBox(height: 14),
          Expanded(child: _buildLista()),
        ])),
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
          BoxShadow(color: AppConfig.rojo.withOpacity(0.18), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14, bottom: -24,
            child: Icon(Icons.fact_check_rounded,
              size: isMobile ? 90 : 130, color: Colors.white.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBadge(icon: Icons.manage_search_rounded, text: 'Validación de cierres'),
              const SizedBox(height: 18),
              Text(
                'Validar reportes resueltos',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36, height: 1.08,
                  fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Revisa los cierres enviados por funcionarios y decide si se publican o se devuelven.',
                style: TextStyle(
                  fontSize: isMobile ? 13.5 : 15.5, height: 1.4,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    final pendientes = _reportes.where((r) => r['estado'] == 'resuelto_pendiente_validacion').length;
    final devueltos = _reportes.where((r) => r['estado'] == 'devuelto').length;
    final publicados = _reportes.where((r) => r['estado'] == 'resuelto_publicado').length;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(icon: Icons.insights_rounded, title: 'Resumen', subtitle: 'Estado de validaciones.'),
          const SizedBox(height: 18),
          _SummaryRow(label: 'Pend. validación', value: '$pendientes', color: AppConfig.rojo),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Devueltos', value: '$devueltos', color: const Color(0xFF9C27B0)),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Publicados', value: '$publicados', color: AppConfig.verde),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return _SoftCard(
      child: Column(
        children: [
          Row(children: const [
            Icon(Icons.tune_rounded, color: AppConfig.azulOscuro),
            SizedBox(width: 8),
            Text('Filtros', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
            )),
          ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _filtroEstado.isEmpty ? null : _filtroEstado,
            hint: const Text('Estado'),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: '', child: Text('Todos')),
              DropdownMenuItem(value: 'resuelto_pendiente_validacion', child: Text('Pend. validación')),
              DropdownMenuItem(value: 'devuelto', child: Text('Devueltos')),
              DropdownMenuItem(value: 'resuelto_publicado', child: Text('Publicados')),
              DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
              DropdownMenuItem(value: 'en_revision', child: Text('En revisión')),
            ],
            onChanged: (v) => setState(() => _filtroEstado = v ?? ''),
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por código, ubicación o categoría...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onChanged: (v) => setState(() => _buscarTexto = v),
          ),
        ],
      ),
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
                Icon(Icons.fact_check_rounded, size: 54, color: AppConfig.rojo),
                const SizedBox(height: 12),
                const Text('Sin resultados', style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
                )),
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
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppConfig.azulOscuro),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r['ubicacion'] ?? '—'),
                  const SizedBox(height: 4),
                  Text(r['categoria'] ?? '—',
                    style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro)),
                  const SizedBox(height: 7),
                  _StatusChip(label: _getEstadoText(estado), color: color),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: estado == 'resuelto_pendiente_validacion'
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.rojo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('REVISAR', style: TextStyle(
                      fontSize: 10, color: AppConfig.rojo, fontWeight: FontWeight.w900,
                    )),
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
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 10.5, color: color, fontWeight: FontWeight.w800,
      )),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
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
          BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 14, offset: const Offset(0, 8)),
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
  const _CardHeading({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46, width: 46,
          decoration: BoxDecoration(
            color: AppConfig.rojo.withOpacity(0.09), borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.rojo),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
              )),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppConfig.grisOscuro)),
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
  const _HeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800,
          )),
        ],
      ),
    );
  }
}