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

class MapaCasosScreen extends StatefulWidget {
  const MapaCasosScreen({super.key});

  @override
  State<MapaCasosScreen> createState() => _MapaCasosScreenState();
}

class _MapaCasosScreenState extends State<MapaCasosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final Completer<GoogleMapController> _mapController = Completer();
  ZonaRiesgo? _zonaSeleccionada;

  static const LatLng _pastoCentro = LatLng(1.2136, -77.2811);

  bool get _isMobile => MediaQuery.of(context).size.width < 800;

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
    super.dispose();
  }

  Map<String, dynamic> _buildUserData(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;

    return {
      'nombre': user?.userMetadata?['nombre'] ?? 'Funcionario',
      'correo': user?.email ?? '',
      'cargo': user?.userMetadata?['cargo'] ?? '',
      'departamento': user?.userMetadata?['departamento'] ?? '',
      'foto_url': user?.userMetadata?['foto_url'] ?? '',
    };
  }

  Future<void> _cerrarSesion() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.logout();

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const FuncionarioLoginScreen(),
        ),
        (route) => false,
      );
    }
  }

  Set<Marker> _buildMarkers(List<ZonaRiesgo> zonas) {
    final Set<Marker> markers = {};

    for (final zona in zonas) {
      double hue;

      switch (zona.nivelRiesgo) {
        case NivelRiesgo.alto:
          hue = BitmapDescriptor.hueRed;
          break;
        case NivelRiesgo.medio:
          hue = BitmapDescriptor.hueOrange;
          break;
        case NivelRiesgo.bajo:
          hue = BitmapDescriptor.hueGreen;
          break;
      }

      markers.add(
        Marker(
          markerId: MarkerId(zona.gridId),
          position: LatLng(zona.latCentro, zona.lngCentro),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          infoWindow: InfoWindow(
            title: '${zona.zonaNombre} — ${zona.labelRiesgo}',
            snippet:
                '${zona.categoriaPredominante} · ${zona.reportesHistoricos} rep · IA: ${zona.porcentaje}',
          ),
          onTap: () => setState(() => _zonaSeleccionada = zona),
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
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        toolbarHeight: 64,
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
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined), text: 'Mapa IA'),
            Tab(icon: Icon(Icons.warning_amber_rounded), text: 'Alertas'),
            Tab(icon: Icon(Icons.bar_chart_rounded), text: 'Resumen'),
          ],
        ),
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
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      svc.error!,
                      textAlign: TextAlign.center,
                    ),
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

          return TabBarView(
            controller: _tabs,
            children: [
              _buildTabMapa(svc),
              _buildTabAlertas(svc),
              _buildTabResumen(svc),
            ],
          );
        },
      ),
    );
  }

  // ── TAB 1: MAPA ─────────────────────────────────────────────────────────

  Widget _buildTabMapa(PrediccionService svc) {
    if (_isMobile) {
      return Column(
        children: [
          _buildFuenteBadge(svc),
          Expanded(
            child: Stack(
              children: [
                _buildGoogleMap(svc),
                Positioned(
                  top: 10,
                  left: 10,
                  child: _buildLeyendaTecnica(),
                ),
                if (_zonaSeleccionada != null)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: _buildZonaDetalleCard(_zonaSeleccionada!),
                  ),
              ],
            ),
          ),
          _buildFilaEstadisticas(svc),
          SizedBox(
            height: 200,
            child: _buildListaZonasFuncionario(svc),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildFuenteBadge(svc),
              Expanded(
                child: Stack(
                  children: [
                    _buildGoogleMap(svc),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: _buildLeyendaTecnica(),
                    ),
                    if (_zonaSeleccionada != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        width: 340,
                        child: _buildZonaDetalleCard(_zonaSeleccionada!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 360,
          child: Column(
            children: [
              _buildFilaEstadisticas(svc),
              Expanded(child: _buildListaZonasFuncionario(svc)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleMap(PrediccionService svc) {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: _pastoCentro,
        zoom: 14.5,
      ),
      onMapCreated: (c) {
        if (!_mapController.isCompleted) {
          _mapController.complete(c);
        }
      },
      markers: _buildMarkers(svc.zonas),
      myLocationButtonEnabled: false,
      zoomControlsEnabled: !_isMobile,
      mapToolbarEnabled: false,
      onTap: (_) => setState(() => _zonaSeleccionada = null),
    );
  }

  Widget _buildLeyendaTecnica() {
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

  Widget _legendRow(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildZonaDetalleCard(ZonaRiesgo zona) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
          ),
        ],
        border: Border.all(
          color: zona.colorRiesgo.withOpacity(0.5),
        ),
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
                child: Icon(
                  zona.iconoCategoria,
                  color: zona.colorRiesgo,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  zona.zonaNombre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
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
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          Row(
            children: [
              _MetricaChip(
                label: 'Reportes',
                valor: '${zona.reportesHistoricos}',
              ),
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
              const Icon(
                Icons.category_outlined,
                size: 12,
                color: Colors.black45,
              ),
              const SizedBox(width: 4),
              Text(
                zona.categoriaPredominante,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
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
                  Icon(
                    Icons.warning_amber_rounded,
                    color: zona.colorRiesgo,
                    size: 13,
                  ),
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

  Widget _buildFuenteBadge(PrediccionService svc) {
    final Color color;
    final String texto;

    switch (svc.fuente) {
      case 'real':
        color = const Color(0xFF388E3C);
        texto = '✓ Datos reales de Supabase';
        break;
      case 'mixto':
        color = const Color(0xFFF57C00);
        texto = '⚡ Mixto (real + simulado)';
        break;
      default:
        color = const Color(0xFF1565C0);
        texto = '🧪 Datos simulados con IA';
        break;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology_rounded, color: color, size: 15),
          const SizedBox(width: 8),
          Text(
            '$texto · ${svc.totalReportesUsados} reportes analizados',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilaEstadisticas(PrediccionService svc) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          _StatCard(
            label: 'Zonas',
            valor: '${svc.totalZonasAnalizadas}',
            icon: Icons.grid_view_rounded,
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(width: 6),
          _StatCard(
            label: 'Alto riesgo',
            valor: '${svc.zonasAltoRiesgo}',
            icon: Icons.trending_up_rounded,
            color: const Color(0xFFD32F2F),
          ),
          const SizedBox(width: 6),
          _StatCard(
            label: 'Alertas',
            valor: '${svc.alertasActivas}',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFF57C00),
          ),
          const SizedBox(width: 6),
          _StatCard(
            label: 'Reportes',
            valor: '${svc.totalReportesUsados}',
            icon: Icons.assessment_rounded,
            color: const Color(0xFF388E3C),
          ),
        ],
      ),
    );
  }

  Widget _buildListaZonasFuncionario(PrediccionService svc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 6, 14, 6),
          child: Text(
            'Detalle por zona',
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
            itemCount: svc.zonas.length,
            itemBuilder: (ctx, i) {
              final zona = svc.zonas[i];

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: zona.colorRiesgo.withOpacity(0.3),
                  ),
                ),
                child: InkWell(
                  onTap: () async {
                    setState(() => _zonaSeleccionada = zona);
                    _tabs.animateTo(0);
                    final ctrl = await _mapController.future;
                    ctrl.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(zona.latCentro, zona.lngCentro),
                        16,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor:
                                  zona.colorRiesgo.withOpacity(0.12),
                              child: Icon(
                                zona.iconoCategoria,
                                color: zona.colorRiesgo,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                zona.zonaNombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: zona.colorRiesgo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                'Riesgo ${zona.labelRiesgo}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: zona.colorRiesgo,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _MetricaChip(
                              label: 'Total',
                              valor: '${zona.reportesHistoricos}',
                            ),
                            const SizedBox(width: 6),
                            _MetricaChip(
                              label: '48h',
                              valor: '${zona.reportesUltimas48h}',
                              destacado: zona.reportesUltimas48h >= 5,
                            ),
                            const SizedBox(width: 6),
                            _MetricaChip(
                              label: 'IA',
                              valor: zona.porcentaje,
                              destacado: zona.probabilidadAlto >= 0.6,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          zona.categoriaPredominante,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── TAB 2: ALERTAS ─────────────────────────────────────────────────────

  Widget _buildTabAlertas(PrediccionService svc) {
    if (svc.alertas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 56,
              color: Color(0xFF388E3C),
            ),
            SizedBox(height: 12),
            Text(
              'Sin alertas activas',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Todas las zonas dentro de parámetros normales.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: svc.alertas.length,
      itemBuilder: (ctx, i) => _AlertaCard(alerta: svc.alertas[i]),
    );
  }

  // ── TAB 3: RESUMEN ─────────────────────────────────────────────────────

  Widget _buildTabResumen(PrediccionService svc) {
    final alto = svc.zonas
        .where((z) => z.nivelRiesgo == NivelRiesgo.alto)
        .length;
    final medio = svc.zonas
        .where((z) => z.nivelRiesgo == NivelRiesgo.medio)
        .length;
    final bajo = svc.zonas
        .where((z) => z.nivelRiesgo == NivelRiesgo.bajo)
        .length;

    final catConteo = <String, int>{};
    for (final z in svc.zonas) {
      catConteo[z.categoriaPredominante] =
          (catConteo[z.categoriaPredominante] ?? 0) + 1;
    }

    final catOrdenadas = catConteo.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0B1E3D),
                  Color(0xFF1565C0),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modelo Random Forest',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '${svc.totalReportesUsados} reportes · ${svc.totalZonasAnalizadas} zonas · Pasto, Nariño',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Actualmente: alta concentración de vendedores ambulantes en el Centro Histórico',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _seccionTitle('Distribución por nivel de riesgo'),
          const SizedBox(height: 10),
          _buildBarraRiesgo(
            'Riesgo Alto',
            alto,
            svc.totalZonasAnalizadas,
            const Color(0xFFD32F2F),
          ),
          const SizedBox(height: 8),
          _buildBarraRiesgo(
            'Riesgo Medio',
            medio,
            svc.totalZonasAnalizadas,
            const Color(0xFFF57C00),
          ),
          const SizedBox(height: 8),
          _buildBarraRiesgo(
            'Riesgo Bajo',
            bajo,
            svc.totalZonasAnalizadas,
            const Color(0xFF388E3C),
          ),
          const SizedBox(height: 20),
          _seccionTitle('Categorías más frecuentes'),
          const SizedBox(height: 10),
          ...catOrdenadas.take(6).map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildBarraCategoria(
                    e.key,
                    e.value,
                    svc.totalZonasAnalizadas,
                  ),
                ),
              ),
          const SizedBox(height: 20),
          _seccionTitle('Top zonas críticas'),
          const SizedBox(height: 10),
          ...svc.zonas
              .where((z) => z.nivelRiesgo == NivelRiesgo.alto)
              .take(5)
              .map(
                (z) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 36,
                        decoration: BoxDecoration(
                          color: z.colorRiesgo,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              z.zonaNombre,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              z.categoriaPredominante,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${z.reportesHistoricos} rep.',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        z.porcentaje,
                        style: TextStyle(
                          color: z.colorRiesgo,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 20),
          _buildInfoModelo(svc),
        ],
      ),
    );

    if (_isMobile) return content;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: content,
      ),
    );
  }

  Widget _seccionTitle(String t) => Text(
        t,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: Color(0xFF0B1E3D),
        ),
      );

  Widget _buildBarraRiesgo(
    String label,
    int valor,
    int total,
    Color color,
  ) {
    final pct = total > 0 ? valor / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              '$valor zona${valor != 1 ? 's' : ''} (${(pct * 100).toStringAsFixed(0)}%)',
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildBarraCategoria(String cat, int valor, int total) {
    final pct = total > 0 ? valor / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                cat,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '$valor',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: const Color(0xFF0B1E3D).withOpacity(0.08),
            valueColor: const AlwaysStoppedAnimation(Color(0xFF1565C0)),
            minHeight: 7,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoModelo(PrediccionService svc) {
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
              Icon(
                Icons.info_outline,
                size: 15,
                color: Color(0xFF0B1E3D),
              ),
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
          _infoRow('Zonas', '${svc.totalZonasAnalizadas} analizadas'),
          _infoRow('Ciudad', 'Pasto, Nariño, Colombia'),
          _infoRow('Situación', 'Alta invasión activa en Centro Histórico'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                valor,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
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
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
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
                fontSize: 8.5,
                color: Colors.black45,
              ),
            ),
          ],
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
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                    style: TextStyle(
                      fontSize: 12.5,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${alerta.reportesEnVentana} reportes en ${alerta.ventanaHoras}h · '
                    '${alerta.generadaEn.day}/${alerta.generadaEn.month}/${alerta.generadaEn.year}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                    ),
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