import 'package:flutter/material.dart';

import '../../../config/app_config.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';
import 'package:provider/provider.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_login_screen.dart';

class InformacionScreen extends StatelessWidget {
  const InformacionScreen({super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 700;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Información',
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
              final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
              await svc.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CiudadanoLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: CiudadanoDrawer.maybe(
        context,
        currentIndex: 4,
      ),
      bottomNavigationBar: CiudadanoBottomNav.maybe(
        context,
        currentIndex: 4,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHero(isMobile),
                SizedBox(height: isMobile ? 22 : 28),
                if (isMobile)
                  Column(
                    children: [
                      _buildTypesCard(),
                      const SizedBox(height: 18),
                      _buildBenefitsSection(isMobile),
                      const SizedBox(height: 18),
                      _buildFaqSection(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildTypesCard(),
                            const SizedBox(height: 20),
                            _buildBenefitsSection(isMobile),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 4,
                        child: _buildFaqSection(),
                      ),
                    ],
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
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
            right: -4,
            bottom: -6,
            child: Icon(
              Icons.info_rounded,
              size: isMobile ? 118 : 160,
              color: Colors.white.withOpacity(0.10),
            ),
          ),
          Column(
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
                      Icons.public_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Espacio público',
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
              Text(
                'Conoce qué puedes reportar',
                style: TextStyle(
                  fontSize: isMobile ? 27 : 38,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Text(
                  'El espacio público es de todos y debe mantenerse libre de obstáculos que impidan su uso y disfrute por parte de la comunidad. Cada ciudadano decide si desea reportar de forma anónima o compartiendo sus datos.',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    height: 1.45,
                    color: Colors.white.withOpacity(0.84),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypesCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.category_rounded,
            title: 'Tipos de invasión',
            subtitle: 'Casos comunes que puedes reportar.',
          ),
          const SizedBox(height: 18),
          const _TypeItem(
            icon: Icons.storefront_rounded,
            title: 'Ocupación comercial',
            description:
                'Establecimientos que expanden sus áreas hacia aceras y vías públicas.',
            color: AppConfig.azulOscuro,
          ),
          const _TypeItem(
            icon: Icons.directions_car_rounded,
            title: 'Invasiones vehiculares',
            description:
                'Vehículos estacionados en aceras, parques o espacios peatonales.',
            color: AppConfig.azulClaro,
          ),
          const _TypeItem(
            icon: Icons.shopping_bag_rounded,
            title: 'Venta informal',
            description: 'Puestos de venta no autorizados en espacio público.',
            color: AppConfig.rojo,
          ),
          const _TypeItem(
            icon: Icons.campaign_rounded,
            title: 'Publicidad no autorizada',
            description:
                'Vallas, avisos o propaganda en espacios no permitidos.',
            color: AppConfig.naranja,
          ),
          const _TypeItem(
            icon: Icons.construction_rounded,
            title: 'Obstrucciones varias',
            description:
                'Materiales de construcción, mobiliario u otros objetos que obstruyan el paso.',
            color: AppConfig.verde,
            showDivider: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(bool isMobile) {
    final cards = [
      const _BenefitCard(
        icon: Icons.location_city_rounded,
        title: 'Mejora tu ciudad',
        description: 'Contribuye a mantener los espacios públicos libres.',
      ),
      const _BenefitCard(
        icon: Icons.shield_rounded,
        title: 'Tú decides',
        description:
            'Puedes reportar de forma anónima o compartir tus datos personales.',
      ),
      const _BenefitCard(
        icon: Icons.check_circle_rounded,
        title: 'Seguimiento',
        description:
            'Si compartes tus datos, podrás revisar tu historial de reportes. Si eliges anonimato, cada consulta se hace con el código de seguimiento.',
      ),
    ];

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.favorite_rounded,
            title: 'Beneficios de reportar',
            subtitle: 'Tu reporte ayuda a mejorar la convivencia.',
          ),
          const SizedBox(height: 18),
          if (isMobile)
            Column(
              children: [
                cards[0],
                const SizedBox(height: 12),
                cards[1],
                const SizedBox(height: 12),
                cards[2],
              ],
            )
          else
            Row(
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 12),
                Expanded(child: cards[1]),
                const SizedBox(width: 12),
                Expanded(child: cards[2]),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildFaqSection() {
    return _SoftCard(
      child: const Column(
        children: [
          _CardHeading(
            icon: Icons.quiz_rounded,
            title: 'Preguntas frecuentes',
            subtitle: 'Resuelve dudas antes de reportar.',
          ),
          SizedBox(height: 18),
          _FaqCard(
            question: '¿Por qué necesito registrarme?',
            answer:
                'El registro permite hacer seguimiento de tus denuncias, proteger el sistema contra reportes fraudulentos y consultar tu historial cuando decides compartir tus datos.',
          ),
          _FaqCard(
            question: '¿Mi reporte puede ser anónimo?',
            answer:
                'Sí. Al crear un reporte puedes elegir si deseas compartir tus datos personales o mantener tu identidad en anonimato. Si compartes tus datos, podrás revisar tu historial de reportes; si eliges anonimato, cada consulta se realiza con el código de seguimiento.',
          ),
          _FaqCard(
            question: '¿Qué pasa después de hacer un reporte?',
            answer:
                'Tu reporte es enviado a las autoridades competentes para su verificación y gestión. Si elegiste anonimato, el seguimiento se hace con el código de seguimiento; si compartiste tus datos, también podrás verlo en tu historial de reportes.',
          ),
          _FaqCard(
            question: '¿En qué plazo se gestiona un reporte?',
            answer:
                'El tiempo de gestión depende de la complejidad del caso, pero generalmente se inicia el proceso en un plazo máximo de 72 horas.',
          ),
          _FaqCard(
            question: '¿Qué pasa si pierdo mi código de seguimiento?',
            answer:
                'Si el reporte fue anónimo, el código es la única forma de consultarlo. Si compartiste tus datos, podrás revisarlo desde tu historial de reportes. En ambos casos, es importante guardar el código.',
            isLast: true,
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

class _TypeItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool showDivider;

  const _TypeItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: AppConfig.grisOscuro,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) const Divider(height: 24),
      ],
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConfig.grisMedio),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppConfig.azulOscuro),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              height: 1.3,
              color: AppConfig.grisOscuro,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final String question;
  final String answer;
  final bool isLast;

  const _FaqCard({
    required this.question,
    required this.answer,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 12),
          iconColor: AppConfig.azulOscuro,
          collapsedIconColor: AppConfig.azulOscuro,
          title: Text(
            question,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 6),
      ],
    );
  }
}