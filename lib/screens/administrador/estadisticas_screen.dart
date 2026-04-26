import 'package:flutter/material.dart';

import '../../config/app_config.dart';

class EstadisticasScreen extends StatelessWidget {
  const EstadisticasScreen({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

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
                _SectionHeader(
                  title: 'Indicadores principales',
                  subtitle: 'Resumen visual del comportamiento del sistema.',
                  actionText: isMobile ? null : 'Periodo actual',
                ),
                const SizedBox(height: 16),
                _buildStats(isMobile),
                SizedBox(height: isMobile ? 22 : 28),
                if (isMobile)
                  Column(
                    children: [
                      _buildEstadoChart(),
                      const SizedBox(height: 18),
                      _buildCategoriaChart(),
                      const SizedBox(height: 18),
                      _buildPrioridadCard(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildEstadoChart()),
                      const SizedBox(width: 20),
                      Expanded(child: _buildCategoriaChart()),
                    ],
                  ),
                if (!isMobile) ...[
                  const SizedBox(height: 20),
                  _buildPrioridadCard(),
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
          BoxShadow(
            color: AppConfig.verde.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -24,
            child: Icon(
              Icons.bar_chart_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.query_stats_rounded,
                text: 'Indicadores administrativos',
              ),
              const SizedBox(height: 18),
              Text(
                'Estadísticas del sistema',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Analiza reportes, prioridades, categorías y estados para mejorar la gestión institucional.',
                style: TextStyle(
                  fontSize: isMobile ? 13.5 : 15.5,
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

  Widget _buildStats(bool isMobile) {
    final cards = [
      const _StatCard(
        title: 'Total reportes',
        value: '312',
        icon: Icons.flag_rounded,
        color: AppConfig.rojo,
      ),
      const _StatCard(
        title: 'Tasa resueltos',
        value: '76%',
        icon: Icons.check_circle_rounded,
        color: AppConfig.verde,
      ),
      const _StatCard(
        title: 'Promedio atención',
        value: '72h',
        icon: Icons.schedule_rounded,
        color: AppConfig.azulClaro,
      ),
      const _StatCard(
        title: 'Pendientes',
        value: '45',
        icon: Icons.pending_actions_rounded,
        color: AppConfig.naranja,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          cards[0],
          const SizedBox(height: 12),
          cards[1],
          const SizedBox(height: 12),
          cards[2],
          const SizedBox(height: 12),
          cards[3],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 16),
        Expanded(child: cards[1]),
        const SizedBox(width: 16),
        Expanded(child: cards[2]),
        const SizedBox(width: 16),
        Expanded(child: cards[3]),
      ],
    );
  }

  Widget _buildEstadoChart() {
    final items = [
      _ChartItem('Pendientes', 45, AppConfig.naranja),
      _ChartItem('En revisión', 28, AppConfig.azulClaro),
      _ChartItem('Resueltos', 239, AppConfig.verde),
    ];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.pie_chart_rounded,
            title: 'Reportes por estado',
            subtitle: 'Distribución actual de la gestión.',
          ),
          const SizedBox(height: 20),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ProgressLine(
                label: item.label,
                value: item.value,
                total: 312,
                color: item.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaChart() {
    final items = [
      _ChartItem('Venta informal', 102, AppConfig.rojo),
      _ChartItem('Invasión vehicular', 78, AppConfig.azulClaro),
      _ChartItem('Ocupación comercial', 66, AppConfig.naranja),
      _ChartItem('Publicidad', 38, AppConfig.verde),
      _ChartItem('Otros', 28, AppConfig.grisOscuro),
    ];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.category_rounded,
            title: 'Reportes por categoría',
            subtitle: 'Tipos de denuncias más frecuentes.',
          ),
          const SizedBox(height: 20),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _ProgressLine(
                label: item.label,
                value: item.value,
                total: 312,
                color: item.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioridadCard() {
    final prioridades = [
      const _PriorityCard(
        label: 'Alta',
        value: '98',
        description: 'Requieren atención prioritaria',
        icon: Icons.priority_high_rounded,
        color: AppConfig.rojo,
      ),
      const _PriorityCard(
        label: 'Media',
        value: '136',
        description: 'Casos en seguimiento normal',
        icon: Icons.remove_rounded,
        color: AppConfig.naranja,
      ),
      const _PriorityCard(
        label: 'Baja',
        value: '78',
        description: 'Casos sin urgencia inmediata',
        icon: Icons.keyboard_arrow_down_rounded,
        color: AppConfig.verde,
      ),
    ];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.stacked_bar_chart_rounded,
            title: 'Prioridades',
            subtitle: 'Clasificación operativa de atención.',
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 720;

              if (stack) {
                return Column(
                  children: [
                    prioridades[0],
                    const SizedBox(height: 12),
                    prioridades[1],
                    const SizedBox(height: 12),
                    prioridades[2],
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: prioridades[0]),
                  const SizedBox(width: 12),
                  Expanded(child: prioridades[1]),
                  const SizedBox(width: 12),
                  Expanded(child: prioridades[2]),
                ],
              );
            },
          ),
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
  final String? actionText;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ],
          ),
        ),
        if (actionText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppConfig.grisMedio),
            ),
            child: Text(
              actionText!,
              style: const TextStyle(
                fontSize: 12,
                color: AppConfig.azulOscuro,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(icon, color: color, size: 29),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppConfig.grisOscuro,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
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

  const _ProgressLine({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : value / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 9,
            color: color,
            backgroundColor: color.withOpacity(0.12),
          ),
        ),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  const _PriorityCard({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppConfig.azulOscuro,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppConfig.grisOscuro,
              height: 1.3,
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
            color: AppConfig.verde.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.verde),
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
                  fontWeight: FontWeight.w900,
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

class _HeroBadge extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroBadge({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
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