import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'ciudadano/ciudadano_home_screen.dart';
import 'funcionario/login_screen.dart';
import 'administrador/login_screen.dart';

class RolSelectionScreen extends StatelessWidget {
  const RolSelectionScreen({super.key});

  static const double _mobileBreakpoint = 700;
  static const double _desktopBreakpoint = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < _mobileBreakpoint;
          final isDesktop = width >= _desktopBreakpoint;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppConfig.azulOscuro,
                  AppConfig.azulClaro,
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  const _BackgroundDecoration(),
                  Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 20 : 40,
                        vertical: isMobile ? 24 : 36,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 1120 : 760,
                        ),
                        child: isDesktop
                            ? _buildDesktopLayout(context)
                            : _buildMobileLayout(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        const _HeaderSection(isDesktop: false),
        const SizedBox(height: 28),
        _RoleCard(
          isDesktop: false,
          children: [
            const _CardTitle(),
            const SizedBox(height: 22),
            _buildRolButton(
              context: context,
              icon: Icons.person_rounded,
              title: 'Ciudadano',
              subtitle: 'Reporta invasiones y consulta el estado de tus solicitudes.',
              color: AppConfig.azulClaro,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CiudadanoHomeScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildRolButton(
              context: context,
              icon: Icons.badge_rounded,
              title: 'Funcionario',
              subtitle: 'Gestiona reportes asignados y realiza seguimiento.',
              color: AppConfig.azulOscuro,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FuncionarioLoginScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildRolButton(
              context: context,
              icon: Icons.admin_panel_settings_rounded,
              title: 'Administrador',
              subtitle: 'Administra usuarios, reportes y configuración general.',
              color: AppConfig.rojo,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminLoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 24),
        const _Footer(),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 5,
          child: _HeaderSection(isDesktop: true),
        ),
        const SizedBox(width: 42),
        Expanded(
          flex: 5,
          child: _RoleCard(
            isDesktop: true,
            children: [
              _CardTitle(),
              SizedBox(height: 24),
              _DesktopRoleButtons(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRolButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _RolButton(
      icon: icon,
      title: title,
      subtitle: subtitle,
      color: color,
      onTap: onTap,
    );
  }
}

class _DesktopRoleButtons extends StatelessWidget {
  const _DesktopRoleButtons();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RolButton(
          icon: Icons.person_rounded,
          title: 'Ciudadano',
          subtitle: 'Reporta invasiones y consulta el estado de tus solicitudes.',
          color: AppConfig.azulClaro,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CiudadanoHomeScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _RolButton(
          icon: Icons.badge_rounded,
          title: 'Funcionario',
          subtitle: 'Gestiona reportes asignados y realiza seguimiento.',
          color: AppConfig.azulOscuro,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FuncionarioLoginScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _RolButton(
          icon: Icons.admin_panel_settings_rounded,
          title: 'Administrador',
          subtitle: 'Administra usuarios, reportes y configuración general.',
          color: AppConfig.rojo,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminLoginScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final bool isDesktop;

  const _HeaderSection({
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isDesktop ? 28 : 22),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(isDesktop ? 32 : 28),
            border: Border.all(
              color: Colors.white.withOpacity(0.22),
            ),
          ),
          child: Icon(
            Icons.route_rounded,
            size: isDesktop ? 82 : 68,
            color: Colors.white,
          ),
        ),
        SizedBox(height: isDesktop ? 30 : 22),
        Text(
          'Ruta Sin Obstáculos',
          textAlign: isDesktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            fontSize: isDesktop ? 46 : 30,
            height: 1.05,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Sistema de reporte y gestión de invasiones al espacio público.',
            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 19 : 15,
              height: 1.45,
              color: Colors.white.withOpacity(0.84),
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        SizedBox(height: isDesktop ? 28 : 18),
        Wrap(
          alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: const [
            _InfoChip(
              icon: Icons.public_rounded,
              text: 'Ciudadanía',
            ),
            _InfoChip(
              icon: Icons.verified_user_rounded,
              text: 'Gestión institucional',
            ),
            _InfoChip(
              icon: Icons.analytics_rounded,
              text: 'Seguimiento',
            ),
          ],
        ),
        if (isDesktop) ...[
          const SizedBox(height: 40),
          const _Footer(alignment: CrossAxisAlignment.start),
        ],
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool isDesktop;
  final List<Widget> children;

  const _RoleCard({
    required this.isDesktop,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 34 : 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isDesktop ? 32 : 26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Selecciona tu rol',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppConfig.azulOscuro,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Elige cómo deseas ingresar al sistema.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: AppConfig.grisOscuro,
          ),
        ),
      ],
    );
  }
}

class _RolButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RolButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_RolButton> createState() => _RolButtonState();
}

class _RolButtonState extends State<_RolButton> {
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
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _hovering
                  ? widget.color.withOpacity(0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovering
                    ? widget.color.withOpacity(0.42)
                    : AppConfig.grisMedio,
                width: 1.2,
              ),
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: widget.color.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.11),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppConfig.grisOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _hovering
                        ? widget.color.withOpacity(0.12)
                        : AppConfig.grisClaro,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
                    color: _hovering ? widget.color : AppConfig.grisOscuro,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.92),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final CrossAxisAlignment alignment;

  const _Footer({
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          '© 2025 - Ruta Sin Obstáculos',
          textAlign: alignment == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.left,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Todos los derechos reservados',
          textAlign: alignment == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.left,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.58),
          ),
        ),
      ],
    );
  }
}

class _BackgroundDecoration extends StatelessWidget {
  const _BackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _BlurCircle(
              size: 230,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -90,
            child: _BlurCircle(
              size: 280,
              color: Colors.white.withOpacity(0.07),
            ),
          ),
          Positioned(
            top: 180,
            left: 40,
            child: _BlurCircle(
              size: 80,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _BlurCircle({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}