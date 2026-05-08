import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/denuncia_service.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  bool _cargando = true;
  List<Map<String, dynamic>> _denuncias = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final service = Provider.of<DenunciaService>(context, listen: false);
    final data = await service.obtenerTodasDenuncias();
    if (!mounted) return;
    setState(() { _denuncias = data; _cargando = false; });
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  int _count(String estado) =>
      _denuncias.where((d) => d['estado'] == estado).length;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final total = _denuncias.length;
    final publicados = _count('resuelto_publicado');
    final pendValidacion = _count('resuelto_pendiente_validacion');
    final devueltos = _count('devuelto');
    final enRevision = _count('en_revision');
    final pendientes = _count('pendiente');
    final tasa = total > 0 ? ((publicados / total) * 100).round() : 0;

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(isMobile: isMobile),
                SizedBox(height: isMobile ? 22 : 28),
                if (_cargando)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else ...[
                  _SectionHeader(title: 'Indicadores principales', subtitle: 'Resumen del sistema.'),
                  const SizedBox(height: 16),
                  _buildStats(isMobile, total, publicados, tasa, pendValidacion),
                  SizedBox(height: isMobile ? 22 : 28),
                  if (isMobile) Column(children: [
                    _buildEstadoChart(pendientes, enRevision, pendValidacion, devueltos, publicados, total),
                    const SizedBox(height: 18),
                    _buildCategoriaChart(),
                  ]) else Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildEstadoChart(pendientes, enRevision, pendValidacion, devueltos, publicados, total)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildCategoriaChart()),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConfig.azulOscuro, AppConfig.verde],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(color: AppConfig.verde.withOpacity(0.18), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14, bottom: -24,
            child: Icon(Icons.bar_chart_rounded,
              size: isMobile ? 90 : 130, color: Colors.white.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBadge(icon: Icons.query_stats_rounded, text: 'Indicadores administrativos'),
              const SizedBox(height: 18),
              Text(
                'Estadísticas del sistema',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36, height: 1.08,
                  fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Analiza reportes, validaciones y estados para mejorar la gestión institucional.',
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

  Widget _buildStats(bool isMobile, int total, int publicados, int tasa, int pendVal) {
    final cards = [
      _StatCard(title: 'Total reportes', value: '$total', icon: Icons.flag_rounded, color: AppConfig.rojo),
      _StatCard(title: 'Tasa resueltos', value: '$tasa%', icon: Icons.check_circle_rounded, color: AppConfig.verde),
      _StatCard(title: 'Publicados', value: '$publicados', icon: Icons.public_rounded, color: AppConfig.azulClaro),
      _StatCard(title: 'Pend. validación', value: '$pendVal', icon: Icons.fact_check_rounded, color: AppConfig.naranja),
    ];

    if (isMobile) {
      return Column(children: [
        cards[0], const SizedBox(height: 12),
        cards[1], const SizedBox(height: 12),
        cards[2], const SizedBox(height: 12),
        cards[3],
      ]);
    }

    return Row(children: [
      Expanded(child: cards[0]), const SizedBox(width: 16),
      Expanded(child: cards[1]), const SizedBox(width: 16),
      Expanded(child: cards[2]), const SizedBox(width: 16),
      Expanded(child: cards[3]),
    ]);
  }

  Widget _buildEstadoChart(int pend, int rev, int pendVal, int dev, int pub, int total) {
    final items = [
      _ChartItem('Pendientes', pend, AppConfig.naranja),
      _ChartItem('En revisión', rev, AppConfig.azulClaro),
      _ChartItem('Pend. validación', pendVal, AppConfig.rojo),
      _ChartItem('Devueltos', dev, const Color(0xFF9C27B0)),
      _ChartItem('Publicados', pub, AppConfig.verde),
    ];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(icon: Icons.pie_chart_rounded, title: 'Reportes por estado', subtitle: 'Distribución actual.'),
          const SizedBox(height: 20),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ProgressLine(label: item.label, value: item.value, total: total == 0 ? 1 : total, color: item.color),
          )),
        ],
      ),
    );
  }

  Widget _buildCategoriaChart() {
    final categorias = <String, int>{};
    for (final d in _denuncias) {
      final cat = d['categoria']?.toString() ?? 'Otro';
      categorias[cat] = (categorias[cat] ?? 0) + 1;
    }
    final sorted = categorias.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = _denuncias.length;

    final colors = [AppConfig.rojo, AppConfig.azulClaro, AppConfig.naranja, AppConfig.verde, AppConfig.grisOscuro];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(icon: Icons.category_rounded, title: 'Reportes por categoría', subtitle: 'Tipos más frecuentes.'),
          const SizedBox(height: 20),
          ...sorted.take(5).toList().asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _ProgressLine(
              label: e.value.key,
              value: e.value.value,
              total: total == 0 ? 1 : total,
              color: colors[e.key % colors.length],
            ),
          )),
        ],
      ),
    );
  }
}

class _ChartItem {
  final String label;
  final int value;
  final Color color;
  const _ChartItem(this.label, this.value, this.color);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
          fontSize: 22, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
        )),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 13.5, color: AppConfig.grisOscuro)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(17)),
            child: Icon(icon, color: color, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(height: 2),
              Text(title, style: TextStyle(fontSize: 12.5, color: AppConfig.grisOscuro, fontWeight: FontWeight.w600)),
            ],
          )),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _ProgressLine({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final percent = value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text('$value', style: TextStyle(fontWeight: FontWeight.w900, color: color)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent, minHeight: 9,
            color: color, backgroundColor: color.withOpacity(0.12),
          ),
        ),
      ],
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
            color: AppConfig.verde.withOpacity(0.1), borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.verde),
        ),
        const SizedBox(width: 13),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
            )),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppConfig.grisOscuro)),
          ],
        )),
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
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}