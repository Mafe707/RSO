import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';
import 'ciudadano_login_screen.dart';
import '../../../analytics/models/zona_riesgo_model.dart';
import '../../../analytics/models/hotspot_alert_model.dart';
import '../../../analytics/services/prediccion_service.dart';

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  ZonaRiesgo? _zonaSeleccionada;
  static const LatLng _pastoCentro = LatLng(1.2136, -77.2811);

  bool get _isMobile => MediaQuery.of(context).size.width < 800;

  static const double _mobileSheetMin = 0.30;
  static const double _mobileSheetInitial = 0.46;
  static const double _mobileSheetMax = 0.90;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrediccionService>().inicializar();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _focusZona(
    ZonaRiesgo zona, {
    bool resetMobileSheet = false,
  }) async {
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
          icon: BitmapDescriptor.defaultMarker,
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mapa de Invasiones',
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
            onPressed: () async {
              final svc = Provider.of<CiudadanoAuthService>(
                context,
                listen: false,
              );
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
      drawer: CiudadanoDrawer.maybe(context, currentIndex: 3),
      bottomNavigationBar: CiudadanoBottomNav.maybe(context, currentIndex: 3),
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
                    'Analizando zonas con IA...',
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
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

          return _isMobile ? _buildMobile(svc) : _buildWeb(svc);
        },
      ),
    );
  }

  Widget _buildMobile(PrediccionService svc) {
    final screenH = MediaQuery.of(context).size.height;
    final mapHeight = screenH * 0.31;

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
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
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
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            if (_sheetController.isAttached) {
                              _sheetController.reset();
                            }
                          },
                          child: const Text('Reportes'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: _buildResumenCardsCompact(svc),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      itemCount: zonasTop.length,
                      itemBuilder: (ctx, i) => _ZonaCiudadanoTile(
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

  Widget _buildWeb(PrediccionService svc) {
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
                              width: 320,
                              child: _buildZonaCard(_zonaSeleccionada!),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 340,
                child: Column(
                  children: [
                    _buildResumenCards(svc),
                    const SizedBox(height: 12),
                    Expanded(child: _buildListaZonas(svc)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIaBanner(PrediccionService svc) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1E3D), Color.fromARGB(255, 26, 91, 166)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
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
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              '${critica.zonaNombre} reporta mayor concentración de ${critica.zonaNombre.contains('Centro') ? 'vendedores ambulantes' : 'invasiones'}.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                color: critica.esCritica
                    ? const Color(0xFFB71C1C)
                    : const Color(0xFFE65100),
              ),
            ),
          ),
        ],
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
      myLocationButtonEnabled: false,
      zoomControlsEnabled: !_isMobile,
      mapToolbarEnabled: false,
      onTap: (_) => setState(() => _zonaSeleccionada = null),
    );
  }

  Widget _buildLeyenda() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Nivel de riesgo IA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0B1E3D),
            ),
          ),
          const SizedBox(height: 6),
          _legendItem('Alto riesgo', const Color(0xFFD32F2F)),
          const SizedBox(height: 4),
          _legendItem('Riesgo medio', const Color(0xFFF57C00)),
          const SizedBox(height: 4),
          _legendItem('Bajo riesgo', const Color(0xFF388E3C)),
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
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6),
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

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 10.5)),
      ],
    );
  }

  Widget _buildZonaCard(ZonaRiesgo zona) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12),
        ],
        border: Border.all(color: zona.colorRiesgo.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(zona.iconoCategoria, color: zona.colorRiesgo, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  zona.zonaNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _zonaSeleccionada = null),
                child: const Icon(Icons.close, size: 16, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            zona.categoriaPredominante,
            style: TextStyle(
              color: zona.colorRiesgo,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${zona.reportesHistoricos} reportes registrados',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.psychology_rounded,
                size: 12,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'IA predice ${zona.porcentaje} probabilidad de riesgo ${zona.labelRiesgo.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (zona.mensajeAlerta != null) ...[
            const SizedBox(height: 6),
            Text(
              zona.mensajeAlerta!,
              style: TextStyle(fontSize: 10.5, color: zona.colorRiesgo),
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
        border: Border.all(color: zona.colorRiesgo.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: zona.colorRiesgo.withOpacity(0.12),
            child: Icon(zona.iconoCategoria, color: zona.colorRiesgo, size: 16),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
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
            onPressed: () => setState(() => _zonaSeleccionada = null),
            icon: const Icon(Icons.close, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCards(PrediccionService svc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          _ResumenCard(
            icon: Icons.map_outlined,
            label: 'Zonas\nanalizadas',
            valor: '${svc.totalZonasAnalizadas}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(width: 8),
          _ResumenCard(
            icon: Icons.warning_amber_rounded,
            label: 'Riesgo\nalto',
            valor: '${svc.zonasAltoRiesgo}',
            color: const Color(0xFFD32F2F),
          ),
          const SizedBox(width: 8),
          _ResumenCard(
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

  Widget _buildListaZonas(PrediccionService svc) {
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
            itemBuilder: (ctx, i) => _ZonaCiudadanoTile(
              zona: zonasTop[i],
              onTap: () => _focusZona(
                zonasTop[i],
                resetMobileSheet: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String valor;
  final Color color;

  const _ResumenCard({
    required this.icon,
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              valor,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: color,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9.5, color: Colors.black54),
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
                fontSize: 9,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonaCiudadanoTile extends StatelessWidget {
  final ZonaRiesgo zona;
  final VoidCallback onTap;

  const _ZonaCiudadanoTile({
    required this.zona,
    required this.onTap,
  });

  String _labelActividad(NivelRiesgo n) {
    switch (n) {
      case NivelRiesgo.alto:
        return 'Alta actividad';
      case NivelRiesgo.medio:
        return 'Actividad media';
      case NivelRiesgo.bajo:
        return 'Baja actividad';
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: zona.colorRiesgo.withOpacity(0.12),
                child: Icon(zona.iconoCategoria, color: zona.colorRiesgo, size: 16),
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
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${zona.categoriaPredominante} · ${zona.reportesHistoricos} rep.',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: zona.colorRiesgo.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _labelActividad(zona.nivelRiesgo),
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

class _MiniLegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniLegendDot({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 9.5)),
      ],
    );
  }
}