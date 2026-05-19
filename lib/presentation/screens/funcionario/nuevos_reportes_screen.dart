import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../../../services/denuncia_service.dart';
import '../../../core/supabase/supabase_config.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';
import 'login_screen.dart';

class NuevosReportesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const NuevosReportesScreen({super.key, required this.userData});

  @override
  State<NuevosReportesScreen> createState() => _NuevosReportesScreenState();
}

class _NuevosReportesScreenState extends State<NuevosReportesScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<Map<String, dynamic>> _reportes = [];
  List<GrupoDenuncias> _grupos = [];
  bool _loading = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
    setState(() { _loading = true; _errorMsg = null; });
    try {
      final response = await _supabase
          .from('denuncias')
          .select('*, evidencias(id, archivo_url, tipo)')
          .filter('funcionario_id', 'is', null)
          .order('creado_en', ascending: false);

      final lista = DenunciaService.castearLista(response);

      setState(() {
        _reportes = lista;
        _grupos = DenunciaService.agruparDenuncias(lista);
        _loading = false;
      });
    } catch (e) {
      setState(() { _errorMsg = 'Error al cargar reportes: $e'; _loading = false; });
    }
  }

  Future<void> _asignarGrupo(GrupoDenuncias grupo) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final funcionarioId = authService.funcionarioData?['id'];
    if (funcionarioId == null) { _showError('No se pudo obtener tu información de funcionario'); return; }

    final service = Provider.of<DenunciaService>(context, listen: false);
    final ok = await service.asignarFuncionarioGrupo(grupo.ids, funcionarioId as int);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Grupo "${grupo.ubicacion}" (${grupo.totalCasos} caso${grupo.totalCasos > 1 ? 's' : ''}) asignado correctamente'),
        backgroundColor: AppConfig.verde,
      ));
      _cargarReportes();
    } else {
      _showError('Error al asignar el grupo');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppConfig.rojo));
  }

  Future<void> _cerrarSesion() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const FuncionarioLoginScreen()), (route) => false);
    }
  }

  bool _isMobile(BuildContext context) => MediaQuery.of(context).size.width < 780;

  String _getCategoriaIcon(String? categoria) {
    switch (categoria) {
      case 'Venta informal': return '🛒';
      case 'Invasión vehicular': return '🚗';
      case 'Ocupación comercial': return '🏪';
      case 'Publicidad no autorizada': return '📢';
      case 'Materiales de construcción': return '🏗️';
      default: return '📋';
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

  void _verDetallesGrupo(GrupoDenuncias grupo) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: AppConfig.azulOscuro.withOpacity(0.1),
                    child: Text(_getCategoriaIcon(grupo.categoria), style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(grupo.categoria, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppConfig.azulOscuro)),
                    Text(grupo.ubicacion, style: TextStyle(color: AppConfig.grisOscuro, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppConfig.azulOscuro.withOpacity(0.1), borderRadius: BorderRadius.circular(999)),
                    child: Text('${grupo.totalCasos} caso${grupo.totalCasos > 1 ? 's' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppConfig.azulOscuro, fontSize: 12)),
                  ),
                ]),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () { Navigator.pop(ctx); _asignarGrupo(grupo); },
                    icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                    label: Text('Asignarme este grupo (${grupo.totalCasos} caso${grupo.totalCasos > 1 ? 's' : ''})'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConfig.verde,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: ListView.separated(
              controller: controller,
              padding: const EdgeInsets.all(16),
              itemCount: grupo.denuncias.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (_, i) {
                final d = grupo.denuncias[i];
                final imagenes = _getTodasImagenes(d);
                return _DenunciaDetalleCard(
                  denuncia: d,
                  imagenes: imagenes,
                  index: i + 1,
                  total: grupo.denuncias.length,
                  formatFecha: _formatFecha,
                  onVerImagen: (idx) => _abrirVisorImagenes(imagenes, idx),
                );
              },
            )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Nuevos Reportes', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isMobile ? null : Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(tooltip: 'Actualizar', icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _cargarReportes),
          IconButton(tooltip: 'Cerrar sesión', icon: const Icon(Icons.logout_rounded, color: Colors.white), onPressed: _cerrarSesion),
        ],
      ),
      drawer: FuncionarioDrawer.maybe(context, currentIndex: 2, userData: widget.userData),
      bottomNavigationBar: FuncionarioBottomNav.maybe(context, currentIndex: 2),
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
    return RefreshIndicator(
      onRefresh: _cargarReportes,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        children: [
          _buildHero(isMobile: true),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildBody(),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: Column(children: [
          _buildHero(isMobile: false),
          const SizedBox(height: 20),
          _buildSummaryCard(),
        ])),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: _buildBody()),
      ],
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppConfig.azulOscuro, AppConfig.azulClaro], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Nuevos Reportes', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        Text('${_grupos.length} grupo${_grupos.length != 1 ? 's' : ''} · ${_reportes.length} reporte${_reportes.length != 1 ? 's' : ''} sin asignar',
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]),
    );
  }

  Widget _buildSummaryCard() {
    final gruposMultiples = _grupos.where((g) => g.totalCasos > 1).length;
    return _SoftCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Resumen', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppConfig.azulOscuro)),
      const SizedBox(height: 12),
      _SummaryRow(label: 'Grupos de invasión', value: '${_grupos.length}', color: AppConfig.azulOscuro),
      const SizedBox(height: 8),
      _SummaryRow(label: 'Con múltiples reportes', value: '$gruposMultiples', color: AppConfig.naranja),
      const SizedBox(height: 8),
      _SummaryRow(label: 'Reportes totales', value: '${_reportes.length}', color: AppConfig.azulClaro),
    ]));
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: Padding(padding: EdgeInsets.only(top: 60), child: CircularProgressIndicator()));
    if (_errorMsg != null) return _EmptyState(icon: Icons.error_outline_rounded, title: 'Error', text: _errorMsg!);
    if (_grupos.isEmpty) return const _EmptyState(icon: Icons.check_circle_outline_rounded, title: 'Sin reportes nuevos', text: 'No hay reportes disponibles para asignación.');
    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      itemCount: _grupos.length,
      itemBuilder: (_, i) => _GrupoCard(
        grupo: _grupos[i],
        categoriaIcon: _getCategoriaIcon(_grupos[i].categoria),
        onAssign: () => _asignarGrupo(_grupos[i]),
        onVerDetalle: () => _verDetallesGrupo(_grupos[i]),
      ),
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
  final void Function(int indice) onVerImagen;

  const _DenunciaDetalleCard({
    required this.denuncia,
    required this.imagenes,
    required this.index,
    required this.total,
    required this.formatFecha,
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

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Cabecera
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppConfig.azulOscuro.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text('Reporte ${widget.index}/${widget.total}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppConfig.azulOscuro)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(d['codigo_unico'] ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppConfig.azulOscuro, fontSize: 13))),
            Text(widget.formatFecha(d['creado_en']), style: TextStyle(fontSize: 11, color: AppConfig.grisOscuro)),
          ]),
        ),
        // Descripción
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Descripción', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppConfig.grisOscuro)),
            const SizedBox(height: 4),
            Text(d['descripcion'] ?? '—', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            // Denunciante
            if (d['es_anonima'] == true)
              Row(children: [
                Icon(Icons.visibility_off_rounded, size: 13, color: AppConfig.grisMedio),
                const SizedBox(width: 5),
                Text('Reporte anónimo', style: TextStyle(fontSize: 12, color: AppConfig.grisMedio, fontStyle: FontStyle.italic)),
              ])
            else ...[
              const Text('Denunciante', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppConfig.grisOscuro)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.person_rounded, size: 13, color: AppConfig.azulOscuro),
                const SizedBox(width: 5),
                Expanded(child: Text(
                  '${d['ciudadano_nombre'] ?? ''} ${d['ciudadano_apellido'] ?? ''}'.trim().isEmpty
                    ? 'Sin nombre registrado'
                    : '${d['ciudadano_nombre'] ?? ''} ${d['ciudadano_apellido'] ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                )),
              ]),
              if ((d['ciudadano_correo']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.email_rounded, size: 13, color: AppConfig.azulOscuro),
                  const SizedBox(width: 5),
                  Expanded(child: Text(d['ciudadano_correo'].toString(),
                    style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro))),
                ]),
              ],
              if ((d['ciudadano_telefono']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 3),
                Row(children: [
                  const Icon(Icons.phone_rounded, size: 13, color: AppConfig.azulOscuro),
                  const SizedBox(width: 5),
                  Text(d['ciudadano_telefono'].toString(),
                    style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro)),
                ]),
              ],
            ],
          ]),
        ),
        // Fotos
        if (imagenes.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(children: [
              const Icon(Icons.photo_library_rounded, size: 13, color: AppConfig.azulOscuro),
              const SizedBox(width: 5),
              Text('${imagenes.length} foto${imagenes.length > 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppConfig.azulOscuro)),
              const Spacer(),
              GestureDetector(
                onTap: () => widget.onVerImagen(_imgIndex),
                child: Text('Ver completa', style: TextStyle(fontSize: 11, color: AppConfig.azulClaro, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          Stack(children: [
            GestureDetector(
              onTap: () => widget.onVerImagen(_imgIndex),
              child: ClipRRect(
                borderRadius: imagenes.length == 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(16))
                  : BorderRadius.zero,
                child: SizedBox(
                  height: 220,
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
              ),
            ),
            // Overlay toque para ver completa
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
            // Ícono de expandir
            Positioned(
              bottom: 10, right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18),
              ),
            ),
          ]),
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

class _GrupoCard extends StatelessWidget {
  final GrupoDenuncias grupo;
  final String categoriaIcon;
  final VoidCallback onAssign;
  final VoidCallback onVerDetalle;

  const _GrupoCard({required this.grupo, required this.categoriaIcon, required this.onAssign, required this.onVerDetalle});

  @override
  Widget build(BuildContext context) {
    final esMultiple = grupo.totalCasos > 1;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: esMultiple ? AppConfig.naranja.withOpacity(0.5) : AppConfig.grisMedio),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              backgroundColor: esMultiple ? AppConfig.naranja.withOpacity(0.12) : AppConfig.azulOscuro.withOpacity(0.08),
              child: Text(categoriaIcon, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(grupo.categoria, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppConfig.azulOscuro)),
              const SizedBox(height: 3),
              Text(grupo.ubicacion, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: AppConfig.grisOscuro)),
            ])),
            if (esMultiple)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: AppConfig.naranja.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                child: Text('${grupo.totalCasos} reportes', style: const TextStyle(fontSize: 11, color: AppConfig.naranja, fontWeight: FontWeight.w800)),
              ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: onVerDetalle,
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('Ver detalle'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.azulOscuro,
                side: BorderSide(color: AppConfig.azulOscuro.withOpacity(0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
              label: Text(esMultiple ? 'Asignar grupo' : 'Asignar a mí'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.verde,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            )),
          ]),
        ]),
      ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _EmptyState({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(child: Center(child: Padding(
      padding: const EdgeInsets.all(26),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 54, color: AppConfig.azulClaro),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro)),
        const SizedBox(height: 6),
        Text(text, textAlign: TextAlign.center, style: TextStyle(color: AppConfig.grisOscuro)),
      ]),
    )));
  }
}