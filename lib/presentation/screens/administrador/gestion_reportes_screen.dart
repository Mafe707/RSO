import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';
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
  bool _recargando = false;
  List<Map<String, dynamic>> _reportes = [];
  List<GrupoDenuncias> _grupos = [];

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

    final response = await SupabaseConfig.client
        .from('denuncias')
        .select('*, evidencias(id, archivo_url, tipo)')
        .order('creado_en', ascending: false);

    final todos = DenunciaService.castearLista(response);

    if (!mounted) return;

    final filtradosPorEstado = todos.where((r) {
      return _filtroEstado.isEmpty || r['estado'] == _filtroEstado;
    }).toList();

    setState(() {
      _reportes = todos;
      _grupos = DenunciaService.agruparDenuncias(filtradosPorEstado);
      _cargando = false;
      _recargando = false;
    });
  }

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 780;

  List<GrupoDenuncias> get _gruposFiltrados {
    if (_buscarTexto.isEmpty) return _grupos;
    final q = _buscarTexto.toLowerCase();
    return _grupos.where((g) {
      final coincideGrupo = g.ubicacion.toLowerCase().contains(q) || g.categoria.toLowerCase().contains(q);
      final coincideDenuncia = g.denuncias.any((d) =>
        (d['codigo_unico'] ?? '').toString().toLowerCase().contains(q) ||
        (d['ubicacion'] ?? '').toString().toLowerCase().contains(q) ||
        (d['categoria'] ?? '').toString().toLowerCase().contains(q) ||
        (d['descripcion'] ?? '').toString().toLowerCase().contains(q));
      return coincideGrupo || coincideDenuncia;
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

  Future<void> _aprobarGrupo(GrupoDenuncias grupo) async {
    final service = Provider.of<DenunciaService>(context, listen: false);
    final ok = await service.actualizarEstadoGrupo(grupo.ids, 'resuelto_publicado');
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(grupo.totalCasos > 1
            ? 'Grupo "${grupo.ubicacion}" (${grupo.totalCasos} casos) publicado correctamente'
            : 'Denuncia "${grupo.ubicacion}" publicada correctamente'),
        backgroundColor: AppConfig.verde,
      ));
      _cargarReportes(silencioso: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error al publicar'), backgroundColor: AppConfig.rojo));
    }
  }

  Future<void> _devolverGrupo(GrupoDenuncias grupo, String motivo) async {
    final service = Provider.of<DenunciaService>(context, listen: false);
    try {
      for (final id in grupo.ids) {
        await service.actualizarEstadoConRespuesta(id, 'devuelto', motivo);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(grupo.totalCasos > 1
            ? 'Grupo devuelto al funcionario (${grupo.totalCasos} casos)'
            : 'Denuncia devuelta al funcionario'),
        backgroundColor: const Color(0xFF9C27B0),
      ));
      _cargarReportes(silencioso: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al devolver: $e'), backgroundColor: AppConfig.rojo));
    }
  }

  List<String> _getTodasImagenes(Map<String, dynamic> denuncia) {
    final List<String> urls = [];
    final imagenUrl = denuncia['imagen_url']?.toString() ?? '';
    if (imagenUrl.isNotEmpty) urls.add(imagenUrl);
    final evidencias = denuncia['evidencias'];
    if (evidencias is List) {
      for (final e in evidencias) {
        final url = (e is Map ? e['archivo_url'] : null)?.toString() ?? '';
        if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
      }
    }
    return urls;
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      final dt = DateTime.parse(fecha.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return '—'; }
  }

  void _abrirVisorImagenes(List<String> imagenes, int indiceInicial) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _VisorImagenesScreen(imagenes: imagenes, indiceInicial: indiceInicial),
    ));
  }

  void _mostrarDetalleGrupo(GrupoDenuncias grupo) {
    final estado = grupo.estadoGrupo;
    final estadoColor = _getEstadoColor(estado);
    final esPendienteValidacion = estado == 'resuelto_pendiente_validacion';
    final motivoController = TextEditingController();
    final respuestaFuncionario = grupo.denuncias
        .map((d) => d['respuesta_oficial']?.toString() ?? '')
        .firstWhere((r) => r.isNotEmpty, orElse: () => '');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: DraggableScrollableSheet(
            initialChildSize: 0.92,
            maxChildSize: 0.97,
            minChildSize: 0.5,
            builder: (_, controller) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                Container(
                  width: 46, height: 5,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: AppConfig.grisMedio, borderRadius: BorderRadius.circular(999)),
                ),
                // Cabecera fija
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      CircleAvatar(
                        backgroundColor: estadoColor.withOpacity(0.12),
                        child: Icon(Icons.fact_check_rounded, color: estadoColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(grupo.categoria, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppConfig.azulOscuro)),
                        Text(grupo.ubicacion, style: TextStyle(color: AppConfig.grisOscuro, fontSize: 12),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      ])),
                      _StatusChip(label: _getEstadoText(estado), color: estadoColor),
                    ]),
                    const SizedBox(height: 6),
                    // ── CORRECCIÓN: solo mostrar "agrupadas" si hay más de 1 denuncia ──
                    Row(children: [
                      Icon(
                        grupo.totalCasos > 1 ? Icons.group_rounded : Icons.person_rounded,
                        size: 13,
                        color: estadoColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        grupo.totalCasos > 1
                            ? '${grupo.totalCasos} denuncias agrupadas · misma ubicación y tipo'
                            : '1 denuncia',
                        style: TextStyle(fontSize: 11.5, color: estadoColor, fontWeight: FontWeight.w600),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Respuesta del funcionario
                    if (respuestaFuncionario.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppConfig.azulOscuro.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppConfig.azulOscuro.withOpacity(0.2)),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(Icons.person_rounded, size: 14, color: AppConfig.azulOscuro),
                            const SizedBox(width: 6),
                            const Text('Respuesta del funcionario',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppConfig.azulOscuro)),
                          ]),
                          const SizedBox(height: 8),
                          Text(respuestaFuncionario, style: const TextStyle(fontSize: 13)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ] else if (esPendienteValidacion) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppConfig.naranja.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          Icon(Icons.warning_amber_rounded, size: 14, color: AppConfig.naranja),
                          const SizedBox(width: 6),
                          const Text('El funcionario no escribió respuesta.', style: TextStyle(fontSize: 12)),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Acciones
                    if (esPendienteValidacion) ...[
                      const Text('Motivo de devolución (opcional)',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: motivoController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Explica por qué se devuelve al funcionario...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(10),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _devolverGrupo(grupo, motivoController.text.trim());
                          },
                          icon: const Icon(Icons.undo_rounded, size: 15),
                          label: const Text('Devolver'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF9C27B0),
                            side: const BorderSide(color: Color(0xFF9C27B0)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )),
                        const SizedBox(width: 10),
                        Expanded(child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _aprobarGrupo(grupo);
                          },
                          icon: const Icon(Icons.check_circle_rounded, size: 15),
                          label: Text(grupo.totalCasos > 1 ? 'Publicar (${grupo.totalCasos})' : 'Publicar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConfig.verde,
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        )),
                      ]),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: estadoColor.withOpacity(0.07), borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          Icon(Icons.info_rounded, color: estadoColor, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            'Estado: "${_getEstadoText(estado)}". Solo se puede validar cuando esté en "Pend. validación".',
                            style: TextStyle(fontSize: 12, color: estadoColor, fontWeight: FontWeight.w600),
                          )),
                        ]),
                      ),
                    ],
                  ]),
                ),
                const Divider(height: 1),
                // Lista de denuncias del grupo (scrolleable)
                Expanded(child: ListView.separated(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: grupo.denuncias.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final d = grupo.denuncias[i];
                    final imagenes = _getTodasImagenes(d);
                    return _DenunciaDetalleCard(
                      denuncia: d,
                      imagenes: imagenes,
                      index: i + 1,
                      total: grupo.denuncias.length,
                      formatFecha: _formatFecha,
                      getEstadoText: _getEstadoText,
                      getEstadoColor: _getEstadoColor,
                      onVerImagen: (idx) => _abrirVisorImagenes(imagenes, idx),
                    );
                  },
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 130,
          child: Text(label, style: TextStyle(fontSize: 13, color: AppConfig.grisOscuro, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHero(isMobile: true),
            const SizedBox(height: 16),
            _buildResumen(),
            const SizedBox(height: 16),
            _buildFiltros(true),
            const SizedBox(height: 12),
            _buildLista(),
          ]),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildHero(isMobile: false),
                const SizedBox(height: 20),
                _buildResumen(),
                const SizedBox(height: 20),
                _buildFiltros(false),
                const SizedBox(height: 16),
              ]),
            ),
            Expanded(child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: _buildLista(),
            )),
          ]),
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
        boxShadow: [BoxShadow(color: AppConfig.azulClaro.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Stack(children: [
        Positioned(
          right: -5, bottom: -12,
          child: Icon(Icons.fact_check_rounded, size: isMobile ? 80 : 110, color: Colors.white.withOpacity(0.08)),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [
            Expanded(child: _HeroBadge(icon: Icons.fact_check_rounded, text: 'Validación de Reportes')),
          ]),
          const SizedBox(height: 14),
          Text('Validación de Reportes',
            style: TextStyle(fontSize: isMobile ? 22 : 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Aprueba o devuelve respuestas oficiales de funcionarios agrupadas por ubicación y tipo.',
            style: TextStyle(fontSize: isMobile ? 13 : 14.5, color: Colors.white.withOpacity(0.84))),
        ]),
      ]),
    );
  }

  Widget _buildResumen() {
    final pendVal = _reportes.where((r) => r['estado'] == 'resuelto_pendiente_validacion').length;
    final aprobados = _reportes.where((r) => r['estado'] == 'resuelto_publicado').length;
    final devueltos = _reportes.where((r) => r['estado'] == 'devuelto').length;
    final isMobile = _isMobile(context);

    final cards = [
      _SummaryRow(label: 'Pend. validación', value: '$pendVal', color: AppConfig.rojo),
      _SummaryRow(label: 'Publicados', value: '$aprobados', color: AppConfig.verde),
      _SummaryRow(label: 'Devueltos', value: '$devueltos', color: const Color(0xFF9C27B0)),
    ];

    if (isMobile) {
      return Column(children: [
        for (int i = 0; i < cards.length; i++) ...[
          SizedBox(width: double.infinity, child: cards[i]),
          if (i != cards.length - 1) const SizedBox(height: 10),
        ],
      ]);
    }

    return Row(children: [
      Expanded(child: cards[0]),
      const SizedBox(width: 12),
      Expanded(child: cards[1]),
      const SizedBox(width: 12),
      Expanded(child: cards[2]),
    ]);
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
          filled: true, fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConfig.grisMedio)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConfig.grisMedio)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppConfig.azulClaro)),
          isDense: true,
        ),
      ),
    );

    Widget chipsWrap = Wrap(
      spacing: 6, runSpacing: 8,
      children: filtros.map((f) {
        final selected = _filtroEstado == f['value'];
        return FilterChip(
          label: Text(f['label']!, style: const TextStyle(fontSize: 12)),
          selected: selected,
          onSelected: (_) {
            setState(() => _filtroEstado = f['value']!);
            _cargarReportes(silencioso: true);
          },
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
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        buscador, const SizedBox(height: 12), chipsWrap,
      ]);
    }

    return Row(children: [
      Expanded(child: buscador),
      const SizedBox(width: 10),
      Expanded(flex: 2, child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: filtros.map((f) {
          final selected = _filtroEstado == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: FilterChip(
              label: Text(f['label']!, style: const TextStyle(fontSize: 12)),
              selected: selected,
              onSelected: (_) {
                setState(() => _filtroEstado = f['value']!);
                _cargarReportes(silencioso: true);
              },
              selectedColor: AppConfig.rojo.withOpacity(0.15),
              checkmarkColor: AppConfig.rojo,
              visualDensity: VisualDensity.compact,
              labelStyle: TextStyle(
                color: selected ? AppConfig.rojo : AppConfig.grisOscuro,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          );
        }).toList()),
      )),
    ]);
  }

  Widget _buildLista() {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_gruposFiltrados.isEmpty) {
      return _SoftCard(child: Center(child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.fact_check_rounded, size: 54, color: AppConfig.rojo),
          const SizedBox(height: 12),
          const Text('Sin resultados', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro)),
          const SizedBox(height: 6),
          Text('No hay grupos que coincidan con los filtros.', textAlign: TextAlign.center, style: TextStyle(color: AppConfig.grisOscuro)),
        ]),
      )));
    }

    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: _isMobile(context) ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics(),
      itemCount: _gruposFiltrados.length,
      itemBuilder: (context, index) {
        final grupo = _gruposFiltrados[index];
        final estado = grupo.estadoGrupo;
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
            title: Text(grupo.ubicacion, style: const TextStyle(fontWeight: FontWeight.w900, color: AppConfig.azulOscuro)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── CORRECCIÓN: texto diferente según si es 1 o varios ──
                Text(
                  grupo.totalCasos > 1
                      ? '${grupo.totalCasos} casos agrupados'
                      : '1 caso',
                ),
                const SizedBox(height: 4),
                Text(grupo.categoria, style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro)),
                const SizedBox(height: 7),
                _StatusChip(label: _getEstadoText(estado), color: color),
              ]),
            ),
            isThreeLine: true,
            trailing: _isMobile(context)
              ? Icon(
                  estado == 'resuelto_pendiente_validacion' ? Icons.fact_check_rounded : Icons.chevron_right_rounded,
                  color: estado == 'resuelto_pendiente_validacion' ? AppConfig.rojo : AppConfig.grisOscuro,
                )
              : estado == 'resuelto_pendiente_validacion'
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppConfig.rojo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text('REVISAR', style: TextStyle(fontSize: 10, color: AppConfig.rojo, fontWeight: FontWeight.w900)),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: () => _mostrarDetalleGrupo(grupo),
          ),
        );
      },
    );
  }
}

// ── Visor de imágenes fullscreen ─────────────────────────────

class _VisorImagenesScreen extends StatefulWidget {
  final List<String> imagenes;
  final int indiceInicial;

  const _VisorImagenesScreen({required this.imagenes, required this.indiceInicial});

  @override
  State<_VisorImagenesScreen> createState() => _VisorImagenesScreenState();
}

class _VisorImagenesScreenState extends State<_VisorImagenesScreen> {
  late int _indice;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _indice = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_indice + 1} / ${widget.imagenes.length}',
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        actions: [
          if (widget.imagenes.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.imagenes.length, (i) => Container(
                  width: _indice == i ? 16 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _indice == i ? Colors.white : Colors.white38,
                    borderRadius: BorderRadius.circular(999),
                  ),
                )),
              ),
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagenes.length,
        onPageChanged: (i) => setState(() => _indice = i),
        itemBuilder: (_, idx) => InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Center(
            child: Image.network(
              widget.imagenes[idx],
              fit: BoxFit.contain,
              loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_rounded, color: Colors.white54, size: 60)),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────

class _DenunciaDetalleCard extends StatefulWidget {
  final Map<String, dynamic> denuncia;
  final List<String> imagenes;
  final int index;
  final int total;
  final String Function(dynamic) formatFecha;
  final String Function(String) getEstadoText;
  final Color Function(String) getEstadoColor;
  final void Function(int indice) onVerImagen;

  const _DenunciaDetalleCard({
    required this.denuncia,
    required this.imagenes,
    required this.index,
    required this.total,
    required this.formatFecha,
    required this.getEstadoText,
    required this.getEstadoColor,
    required this.onVerImagen,
  });

  @override
  State<_DenunciaDetalleCard> createState() => _DenunciaDetalleCardState();
}

class _DenunciaDetalleCardState extends State<_DenunciaDetalleCard> {
  int _imgIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.denuncia;
    final imagenes = widget.imagenes;
    final estadoColor = widget.getEstadoColor(d['estado']?.toString() ?? '');

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Encabezado de la tarjeta individual
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppConfig.azulOscuro.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.total > 1 ? 'Denuncia ${widget.index} de ${widget.total}' : 'Denuncia',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppConfig.azulOscuro),
              ),
            ),
            const Spacer(),
            _StatusChip(
              label: widget.getEstadoText(d['estado']?.toString() ?? ''),
              color: estadoColor,
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if ((d['codigo_unico'] ?? '').toString().isNotEmpty)
              _InfoRow(label: 'Código', value: d['codigo_unico'].toString()),
            if ((d['categoria'] ?? '').toString().isNotEmpty)
              _InfoRow(label: 'Categoría', value: d['categoria'].toString()),
            if ((d['ubicacion'] ?? '').toString().isNotEmpty)
              _InfoRow(label: 'Ubicación', value: d['ubicacion'].toString()),
            if ((d['descripcion'] ?? '').toString().isNotEmpty)
              _InfoRow(label: 'Descripción', value: d['descripcion'].toString()),
            if ((d['creado_en'] ?? '') != '')
              _InfoRow(label: 'Fecha', value: widget.formatFecha(d['creado_en'])),
            if ((d['respuesta_oficial'] ?? '').toString().isNotEmpty)
              _InfoRow(label: 'Respuesta', value: d['respuesta_oficial'].toString()),
          ]),
        ),
        // Imágenes
        if (imagenes.isNotEmpty) ...[
          ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Stack(children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: imagenes.length,
                  onPageChanged: (i) => setState(() => _imgIndex = i),
                  itemBuilder: (_, idx) => Image.network(
                    imagenes[idx],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded, color: AppConfig.grisMedio, size: 40)),
                  ),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => widget.onVerImagen(_imgIndex),
                  child: Container(color: Colors.transparent),
                ),
              ),
              if (imagenes.length > 1) ...[
                Positioned(
                  bottom: 10, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(imagenes.length, (idx) => Container(
                      width: _imgIndex == idx ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _imgIndex == idx ? Colors.white : Colors.white54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    )),
                  ),
                ),
                Positioned(
                  top: 10, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                    child: Text('${_imgIndex + 1}/${imagenes.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
              Positioned(
                bottom: 10, right: 12,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
          if (imagenes.length > 1)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: SizedBox(
                height: 64,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  itemCount: imagenes.length,
                  itemBuilder: (_, idx) => GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(idx,
                        duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
                      setState(() => _imgIndex = idx);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _imgIndex == idx ? AppConfig.azulOscuro : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(imagenes[idx], fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 20)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Icon(Icons.image_not_supported_rounded, size: 14, color: AppConfig.grisMedio),
              const SizedBox(width: 6),
              Text('Sin evidencia fotográfica', style: TextStyle(fontSize: 12, color: AppConfig.grisMedio)),
            ]),
          ),
      ]),
    );
  }
}

// Widget helper interno para filas de info en la tarjeta de detalle
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro, fontWeight: FontWeight.w700)),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
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
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w800)),
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
      ]),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 14, offset: const Offset(0, 8))],
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
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 7),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
      ]),
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
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}