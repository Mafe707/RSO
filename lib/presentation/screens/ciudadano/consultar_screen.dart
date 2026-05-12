import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import '../../../services/denuncia_service.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';
import 'ciudadano_login_screen.dart';

class ConsultarScreen extends StatefulWidget {
  const ConsultarScreen({super.key});

  @override
  State<ConsultarScreen> createState() => _ConsultarScreenState();
}

class _ConsultarScreenState extends State<ConsultarScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _codigoController = TextEditingController();
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
      if (mounted) setState(() {});
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
          content: Text('Error al consultar: $e'),
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
                d['ciudadano_correo']
                    .toString()
                    .toLowerCase() ==
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
      case 'resuelto_publicado':
        return 'Resuelto';
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
      case 'resuelto_publicado':
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
      case 'resuelto_publicado':
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
    if (valor == null) return '-';
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
          if (url.isNotEmpty && !urls.contains(url)) {
            urls.add(url);
          }
        }
      }
    }

    return urls;
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  void _abrirImagenCompleta(
      BuildContext context, List<String> imagenes, int indiceInicial) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => ImagenViewerDialog(
        imagenes: imagenes,
        indiceInicial: indiceInicial,
      ),
    );
  }

  void _abrirDetalleReporte(BuildContext context, Map<String, dynamic> denuncia) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DetalleReporteSheet(
        denuncia: denuncia,
        formatFecha: _formatFecha,
        getEstadoText: _getEstadoText,
        getEstadoColor: _getEstadoColor,
        getEstadoTextColor: _getEstadoTextColor,
        extraerImagenes: _extraerImagenes,
        abrirImagenCompleta: (imagenes, indice) =>
            _abrirImagenCompleta(context, imagenes, indice),
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
          'Consultar Estado',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
        titleSpacing: 16,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              final svc =
                  Provider.of<CiudadanoAuthService>(context, listen: false);
              await svc.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CiudadanoLoginScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: CiudadanoDrawer.maybe(context, currentIndex: 2),
      bottomNavigationBar: CiudadanoBottomNav.maybe(context, currentIndex: 2),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF24476B),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF3B628D),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white.withOpacity(0.20)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              splashBorderRadius: BorderRadius.circular(22),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              tabs: const [
                Tab(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Por código'),
                    ],
                  ),
                ),
                Tab(
                  height: 48,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_turned_in_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Mis reportes'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
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
          ),
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
                    Icon(
                      Icons.track_changes_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
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
              const SizedBox(height: 18),
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
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeading(
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_consultando ? 'Buscando...' : 'Consultar estado'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.azulOscuro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
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
        child: SoftCard(
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 52,
                color: AppConfig.grisOscuro.withOpacity(0.4),
              ),
              const SizedBox(height: 14),
              const Text(
                'No se encontró ninguna denuncia con ese código.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Verifica que el código sea exactamente como fue generado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppConfig.grisOscuro,
                ),
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

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeading(
            icon: Icons.assignment_rounded,
            title: 'Detalle de la denuncia',
            subtitle: 'Información completa del reporte.',
          ),
          const SizedBox(height: 18),
          _buildDetailRow('Código', d['codigo_unico']?.toString() ?? ''),
          _buildEstadoRow(estado),
          _buildDetailRow('Categoría', d['categoria']?.toString() ?? ''),
          _buildDetailRow('Ubicación', d['ubicacion']?.toString() ?? ''),
          _buildDetailRow('Descripción', d['descripcion']?.toString() ?? ''),
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
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _abrirImagenCompleta(context, imagenes, i),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imagenes[i],
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: AppConfig.grisClaro,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.broken_image_rounded,
                              size: 42,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
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
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 19,
                  color: AppConfig.azulClaro,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        respuesta != null && respuesta.isNotEmpty
                            ? respuesta
                            : 'Aún no hay respuesta oficial para este reporte.',
                        style: TextStyle(
                          fontStyle: respuesta != null && respuesta.isNotEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                          height: 1.35,
                          color: respuesta != null && respuesta.isNotEmpty
                              ? Colors.black87
                              : AppConfig.grisOscuro,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Última actualización: ${_formatFecha(d['actualizado_en'])}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppConfig.grisOscuro,
                        ),
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
                      right: 52,
                      bottom: -10,
                      child: Icon(
                        Icons.assignment_turned_in_rounded,
                        size: 110,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in_rounded,
                                      size: 15,
                                      color: Colors.white,
                                    ),
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
                                'Mis reportes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Reportes donde compartiste tus datos.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.84),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _cargadoMios = false;
                              _misReportes = [];
                            });
                            _cargarMisReportes();
                          },
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: Colors.white,
                          ),
                          tooltip: 'Actualizar',
                        ),
                      ],
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
                SoftCard(
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 48,
                        color: AppConfig.azulClaro,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Solo aparecen aquí los reportes donde elegiste compartir tus datos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Los reportes anónimos solo se pueden consultar con el código.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConfig.grisOscuro,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _cargarMisReportes,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Cargar mis reportes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.azulOscuro,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_misReportes.isEmpty)
                SoftCard(
                  child: Column(
                    children: [
                      Icon(
                        Icons.assignment_late_outlined,
                        size: 52,
                        color: AppConfig.grisOscuro.withOpacity(0.4),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No tienes reportes registrados con tus datos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Al hacer un reporte, elige Compartir mis datos para que aparezca aquí.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConfig.grisOscuro,
                        ),
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
                  itemBuilder: (_, i) => _buildMiniReporteCard(_misReportes[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniReporteCard(Map<String, dynamic> d) {
    final estado = d['estado']?.toString() ?? 'pendiente';
    final esPendiente = estado == 'pendiente';

    return GestureDetector(
      onTap: () => _abrirDetalleReporte(context, d),
      child: SoftCard(
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
                        d['codigo_unico']?.toString() ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: esPendiente
                              ? const Color(0xFF721C24)
                              : AppConfig.azulOscuro,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        d['categoria']?.toString() ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConfig.grisOscuro,
                        ),
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
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppConfig.azulClaro,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    d['ubicacion']?.toString() ?? '',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppConfig.grisOscuro,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppConfig.azulClaro,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatFecha(d['creado_en']),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConfig.grisOscuro,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Ver detalle',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConfig.azulOscuro,
                    fontWeight: FontWeight.w700,
                  ),
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
                  border: Border.all(
                    color: AppConfig.verde.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 15,
                      color: AppConfig.verde,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        d['respuesta_oficial'].toString(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
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
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: AppConfig.grisOscuro,
              ),
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
              'Estado',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
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
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          CardHeading(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Recomendaciones',
            subtitle: 'Ten en cuenta antes de consultar.',
          ),
          SizedBox(height: 18),
          TipItem(
            icon: Icons.check_circle_outline_rounded,
            text: 'Copia el código exactamente como fue generado.',
          ),
          TipItem(
            icon: Icons.schedule_rounded,
            text: 'La actualización del estado puede tomar un tiempo.',
          ),
          TipItem(
            icon: Icons.assignment_turned_in_rounded,
            text: 'Si compartiste tus datos, revisa la pestaña Mis reportes.',
          ),
        ],
      ),
    );
  }
}

class ImagenViewerDialog extends StatefulWidget {
  final List<String> imagenes;
  final int indiceInicial;

  const ImagenViewerDialog({
    super.key,
    required this.imagenes,
    required this.indiceInicial,
  });

  @override
  State<ImagenViewerDialog> createState() => _ImagenViewerDialogState();
}

class _ImagenViewerDialogState extends State<ImagenViewerDialog> {
  late int _indiceActual;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _indiceActual = widget.indiceInicial;
    _pageController = PageController(initialPage: widget.indiceInicial);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: Colors.black87),
          ),
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imagenes.length,
            onPageChanged: (i) => setState(() => _indiceActual = i),
            itemBuilder: (_, i) => Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  widget.imagenes[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white54,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
          if (widget.imagenes.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imagenes.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _indiceActual ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color:
                          i == _indiceActual ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          if (_indiceActual > 0)
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          if (_indiceActual < widget.imagenes.length - 1)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class DetalleReporteSheet extends StatelessWidget {
  final Map<String, dynamic> denuncia;
  final String Function(dynamic) formatFecha;
  final String Function(String) getEstadoText;
  final Color Function(String) getEstadoColor;
  final Color Function(String) getEstadoTextColor;
  final List<String> Function(Map<String, dynamic>) extraerImagenes;
  final void Function(List<String>, int) abrirImagenCompleta;

  const DetalleReporteSheet({
    super.key,
    required this.denuncia,
    required this.formatFecha,
    required this.getEstadoText,
    required this.getEstadoColor,
    required this.getEstadoTextColor,
    required this.extraerImagenes,
    required this.abrirImagenCompleta,
  });

  @override
  Widget build(BuildContext context) {
    final d = denuncia;
    final estado = d['estado']?.toString() ?? 'pendiente';
    final imagenes = extraerImagenes(d);
    final respuesta = d['respuesta_oficial']?.toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 1.0,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 8, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.assignment_rounded,
                      color: AppConfig.azulOscuro),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Detalle del reporte',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConfig.azulOscuro,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d['codigo_unico']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: AppConfig.azulOscuro,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: getEstadoColor(estado),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  getEstadoText(estado),
                                  style: TextStyle(
                                    color: getEstadoTextColor(estado),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sheetRow('Categoría', d['categoria']?.toString() ?? ''),
                          _sheetRow('Ubicación', d['ubicacion']?.toString() ?? ''),
                          _sheetRow('Descripción', d['descripcion']?.toString() ?? ''),
                          _sheetRow('Fecha', formatFecha(d['creado_en'])),
                          _sheetRow(
                            'Última actualización',
                            formatFecha(d['actualizado_en']),
                          ),
                          if (d['ciudadano_nombre'] != null) ...[
                            const Divider(height: 24),
                            const Text(
                              'Datos del ciudadano',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _sheetRow(
                              'Nombre',
                              '${d['ciudadano_nombre'] ?? ''} ${d['ciudadano_apellido'] ?? ''}'
                                  .trim(),
                            ),
                            if (d['ciudadano_correo'] != null)
                              _sheetRow(
                                  'Correo', d['ciudadano_correo'].toString()),
                            if (d['ciudadano_telefono'] != null)
                              _sheetRow(
                                  'Teléfono', d['ciudadano_telefono'].toString()),
                          ],
                        ],
                      ),
                    ),
                    if (imagenes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Evidencias',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: imagenes.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (_, i) => GestureDetector(
                                  onTap: () => abrirImagenCompleta(imagenes, i),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imagenes[i],
                                          width: 120,
                                          height: 120,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(
                                            width: 120,
                                            height: 120,
                                            decoration: BoxDecoration(
                                              color: AppConfig.grisClaro,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.broken_image_rounded,
                                              size: 42,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 6,
                                        right: 6,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black54,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Icon(
                                            Icons.zoom_in_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Respuesta oficial',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: AppConfig.azulOscuro,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 19,
                                color: AppConfig.azulClaro,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  respuesta != null && respuesta.isNotEmpty
                                      ? respuesta
                                      : 'Aún no hay respuesta oficial para este reporte.',
                                  style: TextStyle(
                                    fontStyle:
                                        respuesta != null && respuesta.isNotEmpty
                                            ? FontStyle.normal
                                            : FontStyle.italic,
                                    height: 1.35,
                                    color: respuesta != null &&
                                            respuesta.isNotEmpty
                                        ? Colors.black87
                                        : AppConfig.grisOscuro,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: AppConfig.grisOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SoftCard extends StatelessWidget {
  final Widget child;
  const SoftCard({super.key, required this.child});

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

class CardHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CardHeading({
    super.key,
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

class TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const TipItem({
    super.key,
    required this.icon,
    required this.text,
  });

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
                fontSize: 13,
                height: 1.3,
                color: AppConfig.grisOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}