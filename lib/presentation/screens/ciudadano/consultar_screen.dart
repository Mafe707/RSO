import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import '../../../services/denuncia_service.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';

class ConsultarScreen extends StatefulWidget {
  const ConsultarScreen({super.key});

  @override
  State<ConsultarScreen> createState() => _ConsultarScreenState();
}

class _ConsultarScreenState extends State<ConsultarScreen>
    with SingleTickerProviderStateMixin {
  final _codigoController = TextEditingController();
  late TabController _tabController;

  bool _consultando = false;
  bool _buscado = false;
  Map<String, dynamic>? _denunciaEncontrada;

  bool _cargandoMios = false;
  List<Map<String, dynamic>> _misReportes = [];
  bool _cargadoMios = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && !_cargadoMios) {
        _cargarMisReportes();
      }
    });
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un código de seguimiento'),
          backgroundColor: AppConfig.rojo,
        ),
      );
      return;
    }

    setState(() {
      _consultando = true;
      _buscado = true;
      _denunciaEncontrada = null;
    });

    try {
      final svc = Provider.of<DenunciaService>(context, listen: false);
      final resultado = await svc.obtenerDenunciaPorCodigo(codigo);
      if (!mounted) return;
      setState(() {
        _denunciaEncontrada = resultado;
        _consultando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _consultando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al consultar: ${e.toString()}'),
          backgroundColor: AppConfig.rojo,
        ),
      );
    }
  }

  Future<void> _cargarMisReportes() async {
    final ciudadanoSvc =
        Provider.of<CiudadanoAuthService>(context, listen: false);
    final correo = ciudadanoSvc.ciudadanoData?['correo'];
    if (correo == null) return;

    setState(() => _cargandoMios = true);

    try {
      final svc = Provider.of<DenunciaService>(context, listen: false);
      final todos = await svc.obtenerTodasDenuncias();
      if (!mounted) return;
      setState(() {
        _misReportes = todos
            .where((d) =>
                d['ciudadano_correo'] != null &&
                d['ciudadano_correo'].toString().toLowerCase() ==
                    correo.toString().toLowerCase())
            .toList();
        _cargandoMios = false;
        _cargadoMios = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoMios = false);
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_revision':
      case 'revision':
        return 'En revisión';
      case 'resuelta':
        return 'Resuelta';
      case 'rechazada':
        return 'Rechazada';
      case 'resuelto_pendiente_validacion':
        return 'Pendiente validación';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFF8D7DA);
      case 'en_revision':
      case 'revision':
        return const Color(0xFFCCE5FF);
      case 'resuelta':
        return const Color(0xFFD4EDDA);
      case 'rechazada':
        return const Color(0xFFF8D7DA);
      case 'resuelto_pendiente_validacion':
        return const Color(0xFFFFF3CD);
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getEstadoTextColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFF721C24);
      case 'en_revision':
      case 'revision':
        return const Color(0xFF004085);
      case 'resuelta':
        return const Color(0xFF155724);
      case 'rechazada':
        return const Color(0xFF721C24);
      case 'resuelto_pendiente_validacion':
        return const Color(0xFF856404);
      default:
        return Colors.grey[800]!;
    }
  }

  String _formatFecha(dynamic valor) {
    if (valor == null) return '—';
    try {
      final dt = DateTime.parse(valor.toString()).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y $h:$min';
    } catch (_) {
      return valor.toString();
    }
  }

  List<String> _extraerImagenes(Map<String, dynamic> denuncia) {
    final urls = <String>[];
    final imagenPrincipal = denuncia['imagen_url'];
    if (imagenPrincipal != null &&
        imagenPrincipal.toString().trim().isNotEmpty) {
      urls.add(imagenPrincipal.toString().trim());
    }
    final evidencias = denuncia['evidencias'];
    if (evidencias is List) {
      for (final e in evidencias) {
        if (e is Map) {
          final url = e['archivo_url']?.toString().trim() ?? '';
          if (url.isNotEmpty && !urls.contains(url)) urls.add(url);
        }
      }
    }
    return urls;
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Consultar Estado'),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            color: Colors.white.withOpacity(0.08),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.search_rounded), text: 'Por código'),
                Tab(icon: Icon(Icons.list_alt_rounded), text: 'Mis reportes'),
              ],
            ),
          ),
        ),
      ),
      drawer: CiudadanoDrawer.maybe(context, currentIndex: 2),
      bottomNavigationBar: CiudadanoBottomNav.maybe(context, currentIndex: 2),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 32),
                child: isMobile
                    ? _buildMobileLayout()
                    : _buildWebLayout(),
              ),
            ),
          ),
          _buildMisReportesTab(isMobile),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(),
        const SizedBox(height: 18),
        _buildSearchCard(),
        _buildResultSection(),
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
              _buildHero(),
              const SizedBox(height: 20),
              _buildTipsCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSearchCard(),
              _buildResultSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
        ),
        borderRadius: BorderRadius.circular(28),
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
            right: -10,
            bottom: -18,
            child: Icon(
              Icons.manage_search_rounded,
              size: 110,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.track_changes_rounded,
                        size: 15, color: Colors.white),
                    SizedBox(width: 7),
                    Text(
                      'Seguimiento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Consultar denuncia',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ingresa tu código único para conocer el estado actual.',
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildSearchCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.search_rounded,
            title: 'Buscar por código',
            subtitle: 'Ingresa el código que recibiste al reportar.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _codigoController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Código de seguimiento',
              hintText: 'Ej: PSJ-8A4B2C9D',
              prefixIcon: const Icon(Icons.confirmation_number_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onSubmitted: (_) => _consultar(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _consultando ? null : _consultar,
              icon: _consultando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_consultando ? 'Buscando...' : 'Consultar estado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.azulOscuro,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    if (!_buscado) return const SizedBox.shrink();
    if (_consultando) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_denunciaEncontrada == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: _SoftCard(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded,
                  size: 52, color: AppConfig.grisOscuro.withOpacity(0.4)),
              const SizedBox(height: 14),
              const Text(
                'No se encontró ninguna denuncia con ese código',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Verifica que el código sea exactamente como fue generado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppConfig.grisOscuro),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: _buildDenunciaCard(_denunciaEncontrada!),
    );
  }

  Widget _buildDenunciaCard(Map<String, dynamic> d) {
    final estado = d['estado']?.toString() ?? 'pendiente';
    final imagenes = _extraerImagenes(d);
    final respuesta = d['respuesta_oficial']?.toString();

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.assignment_rounded,
            title: 'Detalle de la denuncia',
            subtitle: 'Información completa del reporte.',
          ),
          const SizedBox(height: 18),
          _buildDetailRow('Código', d['codigo_unico']?.toString() ?? '—'),
          _buildEstadoRow(estado),
          _buildDetailRow('Categoría', d['categoria']?.toString() ?? '—'),
          _buildDetailRow('Ubicación', d['ubicacion']?.toString() ?? '—'),
          _buildDetailRow('Descripción', d['descripcion']?.toString() ?? '—'),
          _buildDetailRow('Fecha', _formatFecha(d['creado_en'])),
          if (imagenes.isNotEmpty) ...[
            const Divider(height: 24),
            const Text(
              'Evidencias',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagenes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imagenes[i],
                    width: 110,
                    height: 110,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 110,
                      height: 110,
                      color: AppConfig.grisClaro,
                      child: const Icon(Icons.broken_image_rounded,
                          size: 42, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 34),
          const Text(
            'Respuesta oficial',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppConfig.azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConfig.grisMedio),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 19, color: AppConfig.azulClaro),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (respuesta != null && respuesta.isNotEmpty)
                            ? respuesta
                            : 'Aún no hay respuesta oficial para este reporte.',
                        style: TextStyle(
                          fontStyle: (respuesta != null && respuesta.isNotEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                          height: 1.35,
                          color: (respuesta != null && respuesta.isNotEmpty)
                              ? Colors.black87
                              : AppConfig.grisOscuro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Última actualización: ${_formatFecha(d['actualizado_en'])}',
                        style: TextStyle(
                            fontSize: 11, color: AppConfig.grisOscuro),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMisReportesTab(bool isMobile) {
    Provider.of<CiudadanoAuthService>(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt_rounded,
                        color: Colors.white, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mis reportes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Reportes donde compartiste tus datos.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _cargadoMios = false;
                          _misReportes = [];
                        });
                        _cargarMisReportes();
                      },
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      tooltip: 'Actualizar',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (_cargandoMios)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (!_cargadoMios)
                _SoftCard(
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 48, color: AppConfig.azulClaro),
                      const SizedBox(height: 12),
                      const Text(
                        'Solo aparecen aquí los reportes donde elegiste compartir tus datos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Los reportes anónimos solo se pueden consultar con el código.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: AppConfig.grisOscuro),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarMisReportes,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Cargar mis reportes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.azulOscuro,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_misReportes.isEmpty)
                _SoftCard(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_late_outlined,
                          size: 52,
                          color: AppConfig.grisOscuro.withOpacity(0.4)),
                      const SizedBox(height: 14),
                      const Text(
                        'No tienes reportes registrados con tus datos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Al hacer un reporte, elige "Compartir mis datos" para que aparezca aquí.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: AppConfig.grisOscuro),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _misReportes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) =>
                      _buildMiniReporteCard(_misReportes[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniReporteCard(Map<String, dynamic> d) {
    final estado = d['estado']?.toString() ?? 'pendiente';
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d['codigo_unico']?.toString() ?? '—',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppConfig.azulOscuro,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d['categoria']?.toString() ?? '—',
                      style: TextStyle(
                          fontSize: 13, color: AppConfig.grisOscuro),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getEstadoColor(estado),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _getEstadoText(estado),
                  style: TextStyle(
                    color: _getEstadoTextColor(estado),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AppConfig.azulClaro),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  d['ubicacion']?.toString() ?? '—',
                  style: TextStyle(
                      fontSize: 12.5, color: AppConfig.grisOscuro),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppConfig.azulClaro),
              const SizedBox(width: 5),
              Text(
                _formatFecha(d['creado_en']),
                style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro),
              ),
            ],
          ),
          if (d['respuesta_oficial'] != null &&
              d['respuesta_oficial'].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppConfig.verde.withOpacity(0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppConfig.verde.withOpacity(0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded,
                      size: 15, color: AppConfig.verde),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      d['respuesta_oficial'].toString(),
                      style: const TextStyle(
                          fontSize: 12.5, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: Colors.black87),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 13.5, height: 1.35, color: AppConfig.grisOscuro),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoRow(String estado) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 112,
            child: Text(
              'Estado:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _getEstadoColor(estado),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _getEstadoText(estado),
                  style: TextStyle(
                    color: _getEstadoTextColor(estado),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Recomendaciones',
            subtitle: 'Ten en cuenta antes de consultar.',
          ),
          const SizedBox(height: 18),
          const _TipItem(
            icon: Icons.check_circle_outline_rounded,
            text: 'Copia el código exactamente como fue generado.',
          ),
          const _TipItem(
            icon: Icons.schedule_rounded,
            text: 'La actualización del estado puede tomar un tiempo.',
          ),
          const _TipItem(
            icon: Icons.list_alt_rounded,
            text: 'Si compartiste tus datos, revisa la pestaña "Mis reportes".',
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
      padding: const EdgeInsets.all(22),
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
                  fontWeight: FontWeight.w800,
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

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConfig.azulClaro),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                  fontSize: 13, height: 1.3, color: AppConfig.grisOscuro),
            ),
          ),
        ],
      ),
    );
  }
}