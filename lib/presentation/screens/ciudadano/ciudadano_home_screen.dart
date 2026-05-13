import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/ciudadano_auth_service.dart';
import 'ciudadano_login_screen.dart';
import 'ciudadano_perfil_screen.dart';

import '../../../config/app_config.dart';
import 'reportar_screen.dart';
import 'consultar_screen.dart';
import 'mapa_screen.dart';
import 'informacion_screen.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';

class CiudadanoHomeScreen extends StatelessWidget {
  const CiudadanoHomeScreen({super.key});

  static const double _mobileBreakpoint = 700;
  static const double _desktopMaxWidth = 1180;

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < _mobileBreakpoint;
  }

  void _mostrarMenuPerfilMovil(
    BuildContext context,
    CiudadanoAuthService ciudadanoSvc,
    String nombre,
    String apellido,
    String inicial,
  ) {
    final correo = ciudadanoSvc.ciudadanoData?['correo']?.toString() ?? '';
    final fotoUrl = ciudadanoSvc.ciudadanoData?['foto_url']?.toString();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppConfig.grisMedio,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  Row(
                    children: [
                      _AvatarCircle(
                        fotoUrl: fotoUrl,
                        inicial: inicial,
                        radius: 24,
                        fontSize: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$nombre $apellido'.trim().isEmpty
                                  ? 'Ciudadano'
                                  : '$nombre $apellido',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (correo.isNotEmpty)
                              Text(
                                correo,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConfig.grisOscuro.withOpacity(0.85),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _MoreItem(
                    icon: Icons.person_rounded,
                    title: 'Mi perfil',
                    subtitle: 'Ver y editar tus datos',
                    color: AppConfig.azulClaro,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CiudadanoPerfilScreen(),
                        ),
                      );
                    },
                  ),
                  _MoreItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar sesión',
                    subtitle: 'Salir de tu cuenta actual',
                    color: AppConfig.rojo,
                    onTap: () async {
                      Navigator.pop(ctx);
                      await ciudadanoSvc.logout();
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
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final ciudadanoSvc = Provider.of<CiudadanoAuthService>(context);
    final nombre =
        ciudadanoSvc.ciudadanoData?['nombre'] as String? ?? 'Ciudadano';
    final apellido = ciudadanoSvc.ciudadanoData?['apellido'] as String? ?? '';
    final inicial = nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppConfig.azulOscuro,
        title: const Text(
          'Ruta Sin Obstáculos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
leading: isMobile
    ? null
    : Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
        actions: [
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CiudadanoPerfilScreen(),
                  ),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Row(
                    children: [
                      _AvatarCircle(
                        fotoUrl:
                            ciudadanoSvc.ciudadanoData?['foto_url']?.toString(),
                        inicial: inicial,
                        radius: 17,
                        fontSize: 15,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$nombre $apellido',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (isMobile)
            InkWell(
              onTap: () => _mostrarMenuPerfilMovil(
                context,
                ciudadanoSvc,
                nombre,
                apellido,
                inicial,
              ),
              borderRadius: BorderRadius.circular(50),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _AvatarCircle(
                  fotoUrl: ciudadanoSvc.ciudadanoData?['foto_url']?.toString(),
                  inicial: inicial,
                  radius: 16,
                  fontSize: 13,
                ),
              ),
            ),

          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _LocationBar(isMobile: isMobile),
        ),
      ),
      drawer: CiudadanoDrawer.maybe(context, currentIndex: 0),
      bottomNavigationBar: CiudadanoBottomNav.maybe(context, currentIndex: 0),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _desktopMaxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 32,
                vertical: isMobile ? 16 : 28,
              ),
              child: _buildHomeContent(context, isMobile, nombre),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent(
    BuildContext context,
    bool isMobile,
    String nombreCiudadano,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWelcomeBanner(isMobile, nombreCiudadano),
        SizedBox(height: isMobile ? 22 : 28),
        _SectionHeader(
          title: 'Acciones rápidas',
          subtitle: 'Elige qué deseas hacer hoy.',
          actionText: isMobile ? null : 'San Juan de Pasto',
        ),
        const SizedBox(height: 16),
        isMobile
            ? _buildMobileActionCards(context)
            : _buildDesktopActionCards(context),
        SizedBox(height: isMobile ? 26 : 34),
        if (!isMobile)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildHowItWorks()),
              const SizedBox(width: 20),
              Expanded(child: _buildInfoPanel(context)),
            ],
          )
        else ...[
          _buildHowItWorks(),
          const SizedBox(height: 18),
          _buildInfoPanel(context),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildWelcomeBanner(bool isMobile, String nombreCiudadano) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppConfig.azulOscuro.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: isMobile ? -10 : -20,
            top: isMobile ? 12 : -12,
            child: Icon(
              Icons.route_rounded,
              size: isMobile ? 72 : 140,
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
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 7),
                    Text(
                      'Portal ciudadano',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Hola, $nombreCiudadano 👋',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ayuda a mantener libre el espacio público',
                style: TextStyle(
                  fontSize: isMobile ? 25 : 36,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Text(
                  'Reporta invasiones, consulta el estado de tus solicitudes y conoce cómo funciona el proceso de atención.',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    height: 1.45,
                    color: Colors.white.withOpacity(0.82),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _BannerChip(
                    icon: Icons.lock_outline_rounded,
                    text: 'Reporte seguro',
                  ),
                  _BannerChip(
                    icon: Icons.confirmation_number_outlined,
                    text: 'Código de seguimiento',
                  ),
                  _BannerChip(
                    icon: Icons.access_time_rounded,
                    text: 'Disponible 24/7',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionCards(BuildContext context) {
    return Column(
      children: [
        _ActionTile(
          icon: Icons.add_location_alt_rounded,
          title: 'Reportar invasión',
          subtitle: 'Registra ubicación, categoría, descripción y evidencia.',
          color: AppConfig.azulOscuro,
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ReportarScreen()),
          ),
        ),
        const SizedBox(height: 14),
        _ActionTile(
          icon: Icons.search_rounded,
          title: 'Consultar estado',
          subtitle: 'Usa tu código único para conocer el avance.',
          color: AppConfig.azulClaro,
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ConsultarScreen()),
          ),
        ),
        const SizedBox(height: 14),
        _ActionTile(
          icon: Icons.map_rounded,
          title: 'Mapa de reportes',
          subtitle: 'Visualiza puntos y reportes registrados.',
          color: AppConfig.rojo,
          onTap: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MapaScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopActionCards(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.add_location_alt_rounded,
            title: 'Reportar',
            subtitle: 'Crear una nueva denuncia ciudadana',
            color: AppConfig.azulOscuro,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ReportarScreen()),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            icon: Icons.search_rounded,
            title: 'Consultar',
            subtitle: 'Revisar el estado de un reporte',
            color: AppConfig.azulClaro,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ConsultarScreen()),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionCard(
            icon: Icons.map_rounded,
            title: 'Mapa',
            subtitle: 'Ver reportes por ubicación',
            color: AppConfig.rojo,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MapaScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHowItWorks() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.timeline_rounded,
            title: '¿Cómo funciona?',
            subtitle: 'Proceso simple para hacer seguimiento.',
          ),
          const SizedBox(height: 18),
          _buildStep(
            number: 1,
            title: 'Reporta',
            text:
                'Registra ubicación, categoría, descripción y evidencia fotográfica.',
          ),
          const SizedBox(height: 14),
          _buildStep(
            number: 2,
            title: 'Guarda tu código',
            text: 'Recibirás un código único para consultar el avance.',
          ),
          const SizedBox(height: 14),
          _buildStep(
            number: 3,
            title: 'Consulta',
            text: 'Revisa el estado de tu reporte cuando lo necesites.',
          ),
          const SizedBox(height: 14),
          _buildStep(
            number: 4,
            title: 'Seguimiento institucional',
            text: 'La autoridad competente revisará y gestionará el caso.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppConfig.azulClaro.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(color: AppConfig.azulClaro.withOpacity(0.35)),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                color: AppConfig.azulOscuro,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoPanel(BuildContext context) {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.info_outline_rounded,
            title: 'Información útil',
            subtitle: 'Conoce qué puedes reportar y cómo se gestiona.',
          ),
          const SizedBox(height: 18),
          const _InfoRow(
            icon: Icons.storefront_rounded,
            title: 'Ocupación comercial',
            text: 'Uso de andenes o vías por establecimientos o mobiliario.',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            icon: Icons.directions_car_rounded,
            title: 'Invasión vehicular',
            text:
                'Vehículos que bloquean zonas peatonales o espacios públicos.',
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            icon: Icons.campaign_rounded,
            title: 'Publicidad no autorizada',
            text:
                'Elementos publicitarios instalados en zonas no permitidas.',
            color: AppConfig.rojo,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const InformacionScreen()),
              ),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Ver más información'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppConfig.azulOscuro,
                side:
                    BorderSide(color: AppConfig.azulOscuro.withOpacity(0.25)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBar extends StatelessWidget {
  final bool isMobile;
  const _LocationBar({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          const Text(
            'San Juan de Pasto',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 38, 151, 188).withOpacity(0.92),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Ciudadano',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
                  fontWeight: FontWeight.w800,
                  color: AppConfig.azulOscuro,
                  letterSpacing: -0.2,
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
            child: Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  size: 16,
                  color: AppConfig.azulOscuro,
                ),
                const SizedBox(width: 6),
                Text(
                  actionText!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConfig.azulOscuro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 160),
        scale: _hovering ? 1.015 : 1,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _hovering
                    ? widget.color.withOpacity(0.42)
                    : AppConfig.grisMedio,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hovering
                      ? widget.color.withOpacity(0.12)
                      : Colors.black.withOpacity(0.045),
                  blurRadius: _hovering ? 18 : 12,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 30),
                ),
                const SizedBox(height: 18),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: widget.color,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.35,
                    color: AppConfig.grisOscuro,
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.arrow_forward_rounded, color: widget.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppConfig.grisMedio),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppConfig.grisOscuro,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.chevron_right_rounded, color: color, size: 28),
            ],
          ),
        ),
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
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppConfig.azulOscuro.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppConfig.azulOscuro, size: 24),
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
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

class _BannerChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BannerChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String? fotoUrl;
  final String inicial;
  final double radius;
  final double fontSize;

  const _AvatarCircle({
    required this.fotoUrl,
    required this.inicial,
    required this.radius,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    if (fotoUrl != null && fotoUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(fotoUrl!),
        onBackgroundImageError: (_, __) {},
        backgroundColor: Colors.white.withOpacity(0.22),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withOpacity(0.22),
      child: Text(
        inicial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class _MoreItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.14),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppConfig.azulOscuro,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12.5,
              color: AppConfig.grisOscuro.withOpacity(0.85),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppConfig.azulOscuro,
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}