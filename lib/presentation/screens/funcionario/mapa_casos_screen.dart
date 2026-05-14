import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';
import 'login_screen.dart';
import '../../../analytics/models/zona_riesgo_model.dart';
import '../../../analytics/models/hotspot_alert_model.dart';
import '../../../analytics/services/prediccion_service.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

class MapaCasosScreen extends StatefulWidget {
  const MapaCasosScreen({super.key});

  @override
  State<MapaCasosScreen> createState() => _MapaCasosScreenState();
}

class _MapaCasosScreenState extends State<MapaCasosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final Completer<GoogleMapController> _mapController = Completer();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  ZonaRiesgo? _zonaSeleccionada;

  static const LatLng _pastoCentro = LatLng(1.2136, -77.2811);

  static const double _mobileSheetMin = 0.25;
  static const double _mobileSheetInitial = 0.40;
  static const double _mobileSheetMax = 0.90;

  bool get _isMobile => MediaQuery.of(context).size.width < 800;

  Map<String, dynamic> _buildUserData(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    final dynamic funcionarioData =
        authService.funcionarioData is Map<String, dynamic>
            ? authService.funcionarioData
            : <String, dynamic>{};

    final user = authService.currentUser;
    final meta = user?.userMetadata ?? <String, dynamic>{};

    return {
      'nombre':
          funcionarioData['nombre'] ??
          meta['nombre'] ??
          meta['name'] ??
          'Funcionario',
      'correo':
          funcionarioData['correo'] ??
          meta['correo'] ??
          user?.email ??
          '',
      'cargo': funcionarioData['cargo'] ?? meta['cargo'] ?? '',
      'departamento':
          funcionarioData['departamento'] ?? meta['departamento'] ?? '',
      'foto_url': funcionarioData['foto_url'] ?? meta['foto_url'] ?? '',
    };
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrediccionService>().inicializar();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FuncionarioLoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _focusZona(ZonaRiesgo zona,
      {bool resetMobileSheet = false}) async {
    setState(() => _zonaSeleccionada = zona);

    final ctrl = await _mapController.future;
    await ctrl.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(zona.latCentro, zona.lngCentro),
          zoom: 16.2,
        ),
      ),
    );

    if (_isMobile && resetMobileSheet && _sheetController.isAttached) {
      _sheetController.reset();
    }
  }

  Set<Marker> _buildMarkers(List<ZonaRiesgo> zonas) {
    final Set<Marker> markers = {};

    for (final zona in zonas) {
      markers.add(
        Marker(
          markerId: MarkerId(zona.gridId),
          position: LatLng(zona.latCentro, zona.lngCentro),
          icon: BitmapDescriptor.defaultMarker, // rojo siempre
          infoWindow: InfoWindow(
            title: zona.zonaNombre,
            snippet:
                '${zona.categoriaPredominante} · ${zona.reportesHistoricos} reportes · IA: ${zona.porcentaje}',
          ),
          onTap: () async {
            setState(() => _zonaSeleccionada = zona);
            if (_isMobile && _sheetController.isAttached) {
              _sheetController.reset();
            }
          },
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final userData = _buildUserData(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Analítica Predictiva — IA',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        toolbarHeight: 64,
        centerTitle: false,
        automaticallyImplyLeading: false,
        leading: _isMobile
            ? null
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: () => context.read<PrediccionService>().recargar(),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
        // ── Sin TabBar aquí; las cápsulas van debajo del AppBar ──
      ),
      drawer: FuncionarioDrawer.maybe(
        context,
        currentIndex: 3,
        userData: userData,
      ),
      bottomNavigationBar: FuncionarioBottomNav.maybe(
        context,
        currentIndex: 3,
      ),
      body: Consumer<PrediccionService>(
        builder: (context, svc, _) {
          if (svc.cargando) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Ejecutando modelo Random Forest...',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }

          if (svc.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(svc.error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: svc.recargar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // ── Barra de cápsulas estilo consultar_screen ──
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF24476B),
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: const Color(0xFF3B628D),
                    borderRadius: BorderRadius.circular(22),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.20)),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  splashBorderRadius: BorderRadius.circular(22),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 6),
                  tabs: const [
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_outlined, size: 18),
                          SizedBox(width: 7),
                          Text('Mapa IA'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 18),
                          SizedBox(width: 7),
                          Text('Alertas'),
                        ],
                      ),
                    ),
                    Tab(
                      height: 44,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 18),
                          SizedBox(width: 7),
                          Text('Resumen'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildTabMapa(svc),
                    _buildTabAlertas(svc),
                    _buildTabResumen(svc),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────── TAB MAPA ────────────────────────────

  Widget _buildTabMapa(PrediccionService svc) {
    return _isMobile ? _buildMapaMobile(svc) : _buildMapaWeb(svc);
  }

  Widget _buildMapaMobile(PrediccionService svc) {
    final screenH = MediaQuery.of(context).size.height;
    final mapHeight = screenH * 0.40;

    return Stack(
      children: [
        Column(
          children: [
            _buildIaBanner(svc),
            _buildAlertaBanner(svc),
            SizedBox(
              height: mapHeight,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildGoogleMap(svc)),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildLeyendaCompacta(),
                  ),
                  if (_zonaSeleccionada != null)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: _buildZonaCardCompacta(_zonaSeleccionada!),
                    ),
                ],
              ),
            ),
          ],
        ),
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _mobileSheetInitial,
          minChildSize: _mobileSheetMin,
          maxChildSize: _mobileSheetMax,
          snap: true,
          snapSizes: const [
            _mobileSheetMin,
            _mobileSheetInitial,
            0.68,
            _mobileSheetMax,
          ],
          builder: (context, scrollController) {
            final zonasTop = svc.zonas.take(10).toList();

            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FB),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.list_alt_rounded,
                          size: 17,
                          color: Color(0xFF0B1E3D),
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Zonas detectadas por IA',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF0B1E3D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: _buildResumenCardsCompact(svc),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: zonasTop.length,
                      itemBuilder: (ctx, i) => _ZonaFuncionarioTile(
                        zona: zonasTop[i],
                        onTap: () => _focusZona(
                          zonasTop[i],
                          resetMobileSheet: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMapaWeb(PrediccionService svc) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildIaBanner(svc),
                    _buildAlertaBanner(svc),
                    Expanded(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: _buildGoogleMap(svc),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: _buildLeyenda(),
                          ),
                          if (_zonaSeleccionada != null)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              width: 340,
                              child:
                                  _buildZonaDetalleCard(_zonaSeleccionada!),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 360,
                child: Column(
                  children: [
                    _buildResumenCards(svc),
                    const SizedBox(height: 12),
                    Expanded(child: _buildListaZonasFuncionario(svc)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleMap(PrediccionService svc) {
  return GoogleMap(
    initialCameraPosition: const CameraPosition(
      target: _pastoCentro,
      zoom: 14.5,
    ),

    onMapCreated: (controller) {
      if (!_mapController.isCompleted) {
        _mapController.complete(controller);
      }
    },

    markers: _buildMarkers(svc.zonas),

    // 👇 ESTO SOLUCIONA EL ZOOM TÁCTIL
    gestureRecognizers: <
        Factory<OneSequenceGestureRecognizer>>{
      Factory<OneSequenceGestureRecognizer>(
        () => EagerGestureRecognizer(),
      ),
    },

    zoomGesturesEnabled: true,
    scrollGesturesEnabled: true,
    rotateGesturesEnabled: true,
    tiltGesturesEnabled: true,

    zoomControlsEnabled: !_isMobile,
    myLocationButtonEnabled: false,
    mapToolbarEnabled: false,
    compassEnabled: true,

    onTap: (_) {
      setState(() => _zonaSeleccionada = null);
    },
  );
}

  // ─────────────────────── LEYENDAS ────────────────────────────────

  Widget _buildLeyenda() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Random Forest IA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B1E3D),
            ),
          ),
          const SizedBox(height: 6),
          _legendRow('Riesgo Alto', const Color(0xFFD32F2F)),
          const SizedBox(height: 3),
          _legendRow('Riesgo Medio', const Color(0xFFF57C00)),
          const SizedBox(height: 3),
          _legendRow('Riesgo Bajo', const Color(0xFF388E3C)),
        ],
      ),
    );
  }

  Widget _buildLeyendaCompacta() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08), blurRadius: 6),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Riesgo IA',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B1E3D),
            ),
          ),
          SizedBox(height: 4),
          _MiniLegendDot(label: 'Alto', color: Color(0xFFD32F2F)),
          SizedBox(height: 2),
          _MiniLegendDot(label: 'Medio', color: Color(0xFFF57C00)),
          SizedBox(height: 2),
          _MiniLegendDot(label: 'Bajo', color: Color(0xFF388E3C)),
        ],
      ),
    );
  }

  Widget _legendRow(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600)),
      ],
    );
  }

  // ─────────────────────── BANNERS ─────────────────────────────────

  Widget _buildIaBanner(PrediccionService svc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B1E3D),
            Color.fromARGB(255, 26, 91, 166),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded,
              color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Predicción con Inteligencia Artificial',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Random Forest · ${svc.totalReportesUsados} reportes analizados · Pasto, Nariño',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              svc.fuente == 'real'
                  ? '✓ Datos reales'
                  : svc.fuente == 'mixto'
                      ? '⚡ Mixto'
                      : '🧪 Simulado',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaBanner(PrediccionService svc) {
    if (svc.alertas.isEmpty) return const SizedBox.shrink();

    final critica = svc.alertas.firstWhere(
      (a) => a.esCritica,
      orElse: () => svc.alertas.first,
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: critica.esCritica
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: critica.esCritica
              ? const Color(0xFFD32F2F)
              : const Color(0xFFF57C00),
        ),
      ),
      child: Row(
        children: [
          Icon(
            critica.esCritica
                ? Icons.warning_rounded
                : Icons.info_outline_rounded,
            color: critica.esCritica
                ? const Color(0xFFD32F2F)
                : const Color(0xFFF57C00),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${svc.alertas.length} zona${svc.alertas.length > 1 ? 's' : ''} con alta actividad. '
              '${critica.zonaNombre} reporta mayor concentración de invasiones.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: critica.esCritica
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFFF57C00),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── TARJETAS ZONA ───────────────────────────

  Widget _buildZonaDetalleCard(ZonaRiesgo zona) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15), blurRadius: 16),
        ],
        border: Border.all(color: zona.colorRiesgo.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: zona.colorRiesgo.withOpacity(0.12),
                child: Icon(zona.iconoCategoria,
                    color: zona.colorRiesgo, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  zona.zonaNombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: zona.colorRiesgo.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Riesgo ${zona.labelRiesgo}',
                  style: TextStyle(
                    fontSize: 10,
                    color: zona.colorRiesgo,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _zonaSeleccionada = null),
                child: const Icon(Icons.close,
                    size: 16, color: Colors.black45),
              ),
            ],
          ),
          const Divider(height: 14),
          Row(
            children: [
              _MetricaChip(
                  label: 'Reportes',
                  valor: '${zona.reportesHistoricos}'),
              const SizedBox(width: 8),
              _MetricaChip(
                label: 'Últimas 48h',
                valor: '${zona.reportesUltimas48h}',
                destacado: zona.reportesUltimas48h >= 5,
              ),
              const SizedBox(width: 8),
              _MetricaChip(
                label: 'Prob. IA',
                valor: zona.porcentaje,
                destacado: zona.probabilidadAlto >= 0.6,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.category_outlined,
                  size: 12, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                zona.categoriaPredominante,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
          if (zona.mensajeAlerta != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: zona.colorRiesgo.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: zona.colorRiesgo, size: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      zona.mensajeAlerta!,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: zona.colorRiesgo,
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
    );
  }

  Widget _buildZonaCardCompacta(ZonaRiesgo zona) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: zona.colorRiesgo.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.10), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: zona.colorRiesgo.withOpacity(0.12),
            child: Icon(zona.iconoCategoria,
                color: zona.colorRiesgo, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  zona.zonaNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 12.5),
                ),
                Text(
                  '${zona.categoriaPredominante} · IA ${zona.porcentaje}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: zona.colorRiesgo,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () =>
                setState(() => _zonaSeleccionada = null),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── ESTADÍSTICAS ────────────────────────────

  Widget _buildResumenCards(PrediccionService svc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.map_outlined,
            label: 'Zonas\nanalizadas',
            valor: '${svc.totalZonasAnalizadas}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.warning_amber_rounded,
            label: 'Riesgo\nalto',
            valor: '${svc.zonasAltoRiesgo}',
            color: const Color(0xFFD32F2F),
          ),
          const SizedBox(width: 8),
          _StatCard(
            icon: Icons.notifications_active_outlined,
            label: 'Alertas\nactivas',
            valor: '${svc.alertasActivas}',
            color: const Color(0xFFF57C00),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCardsCompact(PrediccionService svc) {
    return Row(
      children: [
        _MiniResumenChip(
          label: 'Zonas',
          valor: '${svc.totalZonasAnalizadas}',
          color: AppConfig.azulOscuro,
        ),
        const SizedBox(width: 6),
        _MiniResumenChip(
          label: 'Alto',
          valor: '${svc.zonasAltoRiesgo}',
          color: const Color(0xFFD32F2F),
        ),
        const SizedBox(width: 6),
        _MiniResumenChip(
          label: 'Alertas',
          valor: '${svc.alertasActivas}',
          color: const Color(0xFFF57C00),
        ),
      ],
    );
  }

  Widget _buildListaZonasFuncionario(PrediccionService svc) {
    final zonasTop = svc.zonas.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 4, 14, 6),
          child: Text(
            'Zonas detectadas por IA',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF0B1E3D),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: zonasTop.length,
            itemBuilder: (ctx, i) => _ZonaFuncionarioTile(
              zona: zonasTop[i],
              onTap: () => _focusZona(zonasTop[i]),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────── TAB ALERTAS ─────────────────────────────

  Widget _buildTabAlertas(PrediccionService svc) {
    if (svc.alertas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline,
                size: 52, color: Color(0xFF388E3C)),
            SizedBox(height: 12),
            Text(
              'Sin alertas activas',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF388E3C),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'No se detectaron zonas críticas en este momento.',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: svc.alertas.length,
      itemBuilder: (ctx, i) => _AlertaCard(alerta: svc.alertas[i]),
    );
  }

  // ─────────────────────── TAB RESUMEN ─────────────────────────────

  Widget _buildTabResumen(PrediccionService svc) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilaEstadisticasResumen(svc),
          const SizedBox(height: 16),
          _buildDistribucionRiesgo(svc),
          const SizedBox(height: 16),
          _buildInfoModeloCard(svc),
        ],
      ),
    );
  }

  Widget _buildFilaEstadisticasResumen(PrediccionService svc) {
  final medio = svc.zonas.where((z) => z.nivelRiesgo == NivelRiesgo.medio).length;
  final bajo  = svc.zonas.where((z) => z.nivelRiesgo == NivelRiesgo.bajo).length;

  return Row(
    children: [
      _StatCard(
        icon: Icons.map_outlined,
        label: 'Zonas\nanalizadas',
        valor: '${svc.totalZonasAnalizadas}',
        color: AppConfig.azulOscuro,
      ),
      const SizedBox(width: 8),
      _StatCard(
        icon: Icons.warning_amber_rounded,
        label: 'Riesgo\nalto',
        valor: '${svc.zonasAltoRiesgo}',
        color: const Color(0xFFD32F2F),
      ),
      const SizedBox(width: 8),
      _StatCard(
        icon: Icons.bar_chart_rounded,
        label: 'Riesgo\nmedio',
        valor: '$medio',
        color: const Color(0xFFF57C00),
      ),
      const SizedBox(width: 8),
      _StatCard(
        icon: Icons.check_circle_outline,
        label: 'Riesgo\nbajo',
        valor: '$bajo',
        color: const Color(0xFF388E3C),
      ),
    ],
  );
}
  Widget _buildDistribucionRiesgo(PrediccionService svc) {
  final total = svc.totalZonasAnalizadas;
  if (total == 0) return const SizedBox.shrink();

  final alto  = svc.zonasAltoRiesgo;
  final medio = svc.zonas.where((z) => z.nivelRiesgo == NivelRiesgo.medio).length;
  final bajo  = svc.zonas.where((z) => z.nivelRiesgo == NivelRiesgo.bajo).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de riesgo',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Color(0xFF0B1E3D),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetricaChip(
                label: 'Alto',
                valor:
                    '${(alto / total * 100).toStringAsFixed(0)}%',
                destacado: true,
              ),
              const SizedBox(width: 8),
              _MetricaChip(
                label: 'Medio',
                valor:
                    '${(medio / total * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(width: 8),
              _MetricaChip(
                label: 'Bajo',
                valor:
                    '${(bajo / total * 100).toStringAsFixed(0)}%',
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Row(
              children: [
                if (alto > 0)
                  Expanded(
                    flex: alto,
                    child: Container(
                      height: 10,
                      color: const Color(0xFFD32F2F),
                    ),
                  ),
                if (medio > 0)
                  Expanded(
                    flex: medio,
                    child: Container(
                      height: 10,
                      color: const Color(0xFFF57C00),
                    ),
                  ),
                if (bajo > 0)
                  Expanded(
                    flex: bajo,
                    child: Container(
                      height: 10,
                      color: const Color(0xFF388E3C),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoModeloCard(PrediccionService svc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 15, color: Color(0xFF0B1E3D)),
              SizedBox(width: 6),
              Text(
                'Información técnica del modelo',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0B1E3D),
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          _infoRow('Algoritmo', 'Random Forest (clasificación)'),
          _infoRow('Features', '12 variables por reporte'),
          _infoRow('Clases', 'Bajo / Medio / Alto riesgo'),
          _infoRow(
            'Datos',
            svc.fuente == 'real'
                ? 'Reales de Supabase'
                : svc.fuente == 'mixto'
                    ? 'Mixtos'
                    : 'Simulados con semilla fija',
          ),
          _infoRow('Reportes', '${svc.totalReportesUsados}'),
          _infoRow(
              'Zonas', '${svc.totalZonasAnalizadas} analizadas'),
          _infoRow('Ciudad', 'Pasto, Nariño, Colombia'),
          _infoRow(
              'Situación', 'Alta invasión activa en Centro Histórico'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                  color: Colors.black54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WIDGETS AUXILIARES
// ═══════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.valor,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 3),
            Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 9, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniResumenChip extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;

  const _MiniResumenChip({
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 9, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricaChip extends StatelessWidget {
  final String label;
  final String valor;
  final bool destacado;

  const _MetricaChip({
    required this.label,
    required this.valor,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
        decoration: BoxDecoration(
          color: destacado
              ? const Color(0xFFD32F2F).withOpacity(0.07)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: destacado
                ? const Color(0xFFD32F2F).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: destacado
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF0B1E3D),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 8.5, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonaFuncionarioTile extends StatelessWidget {
  final ZonaRiesgo zona;
  final VoidCallback onTap;

  const _ZonaFuncionarioTile({
    required this.zona,
    required this.onTap,
  });

  String _labelRiesgo(NivelRiesgo n) {
    switch (n) {
      case NivelRiesgo.alto:
        return 'Alto riesgo';
      case NivelRiesgo.medio:
        return 'Riesgo medio';
      case NivelRiesgo.bajo:
        return 'Bajo riesgo';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: zona.colorRiesgo.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor:
                    zona.colorRiesgo.withOpacity(0.12),
                child: Icon(zona.iconoCategoria,
                    color: zona.colorRiesgo, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      zona.zonaNombre,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                    Text(
                      '${zona.categoriaPredominante} · ${zona.reportesHistoricos} rep.',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: zona.colorRiesgo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _labelRiesgo(zona.nivelRiesgo),
                      style: TextStyle(
                        fontSize: 9.5,
                        color: zona.colorRiesgo,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'IA: ${zona.porcentaje}',
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertaCard extends StatelessWidget {
  final HotspotAlert alerta;

  const _AlertaCard({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final color = alerta.esCritica
        ? const Color(0xFFD32F2F)
        : const Color(0xFFF57C00);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.4)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.04),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(
                alerta.esCritica
                    ? Icons.warning_rounded
                    : Icons.info_outline_rounded,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alerta.zonaNombre,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          alerta.esCritica ? 'CRÍTICA' : 'ALERTA',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alerta.mensaje,
                    style: TextStyle(fontSize: 12.5, color: color),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${alerta.reportesEnVentana} reportes en ${alerta.ventanaHoras}h · '
                    '${alerta.generadaEn.day}/${alerta.generadaEn.month}/${alerta.generadaEn.year}',
                    style: const TextStyle(
                        fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniLegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniLegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 9.5)),
      ],
    );
  }
}