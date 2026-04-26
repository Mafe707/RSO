import 'package:flutter/material.dart';

import '../../config/app_config.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _notificacionesEmail = true;
  bool _notificacionesSistema = true;
  bool _modoMantenimiento = false;
  bool _asignacionAutomatica = true;

  final _diasRespuestaController = TextEditingController(text: '3');
  final _correoSoporteController =
      TextEditingController(text: 'soporte@alcaldia.gov.co');

  @override
  void dispose() {
    _diasRespuestaController.dispose();
    _correoSoporteController.dispose();
    super.dispose();
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  void _guardarConfiguracion() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración guardada correctamente'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  void _mostrarDialogoMantenimiento(bool value) {
    if (!value) {
      setState(() => _modoMantenimiento = false);
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_rounded, color: AppConfig.naranja),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Activar mantenimiento',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          content: const Text(
            'Esta opción indica visualmente que el sistema está en mantenimiento. Confirma si deseas activarla.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _modoMantenimiento = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.naranja,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Activar'),
            ),
          ],
        );
      },
    );
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
                if (isMobile)
                  Column(
                    children: [
                      _buildGeneralCard(),
                      const SizedBox(height: 18),
                      _buildNotificationsCard(),
                      const SizedBox(height: 18),
                      _buildSecurityCard(),
                      const SizedBox(height: 18),
                      _buildSystemStatusCard(),
                      const SizedBox(height: 18),
                      _buildSaveButton(),
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
                            _buildGeneralCard(),
                            const SizedBox(height: 18),
                            _buildSecurityCard(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            _buildNotificationsCard(),
                            const SizedBox(height: 18),
                            _buildSystemStatusCard(),
                            const SizedBox(height: 18),
                            _buildSaveButton(),
                          ],
                        ),
                      ),
                    ],
                  ),
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
          colors: [AppConfig.azulOscuro, AppConfig.rojo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppConfig.rojo.withOpacity(0.18),
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
              Icons.settings_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.tune_rounded,
                text: 'Configuración administrativa',
              ),
              const SizedBox(height: 18),
              Text(
                'Ajustes del sistema',
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
                'Administra parámetros generales, notificaciones y opciones operativas del sistema.',
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

  Widget _buildGeneralCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.settings_applications_rounded,
            title: 'Configuración general',
            subtitle: 'Parámetros básicos de funcionamiento.',
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _diasRespuestaController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Días máximos de respuesta',
              hintText: 'Ej: 3',
              prefixIcon: const Icon(Icons.schedule_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _correoSoporteController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Correo de soporte',
              hintText: 'soporte@alcaldia.gov.co',
              prefixIcon: const Icon(Icons.email_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SwitchTile(
            icon: Icons.assignment_ind_rounded,
            title: 'Asignación automática',
            subtitle: 'Permitir asignación automática de reportes.',
            value: _asignacionAutomatica,
            color: AppConfig.verde,
            onChanged: (value) {
              setState(() => _asignacionAutomatica = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.notifications_rounded,
            title: 'Notificaciones',
            subtitle: 'Controla alertas y avisos del sistema.',
            color: AppConfig.naranja,
          ),
          const SizedBox(height: 20),
          _SwitchTile(
            icon: Icons.email_rounded,
            title: 'Notificaciones por correo',
            subtitle: 'Enviar alertas administrativas al correo registrado.',
            value: _notificacionesEmail,
            color: AppConfig.azulClaro,
            onChanged: (value) {
              setState(() => _notificacionesEmail = value);
            },
          ),
          const SizedBox(height: 12),
          _SwitchTile(
            icon: Icons.notifications_active_rounded,
            title: 'Notificaciones del sistema',
            subtitle: 'Mostrar avisos dentro del panel administrativo.',
            value: _notificacionesSistema,
            color: AppConfig.verde,
            onChanged: (value) {
              setState(() => _notificacionesSistema = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.security_rounded,
            title: 'Seguridad y operación',
            subtitle: 'Opciones importantes del sistema.',
            color: AppConfig.rojo,
          ),
          const SizedBox(height: 20),
          _SwitchTile(
            icon: Icons.construction_rounded,
            title: 'Modo mantenimiento',
            subtitle:
                'Indicar temporalmente que el sistema está en mantenimiento.',
            value: _modoMantenimiento,
            color: AppConfig.rojo,
            onChanged: _mostrarDialogoMantenimiento,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _CardHeading(
            icon: Icons.health_and_safety_rounded,
            title: 'Estado actual',
            subtitle: 'Resumen de configuración activa.',
            color: AppConfig.verde,
          ),
          SizedBox(height: 18),
          _StatusLine(
            icon: Icons.cloud_done_rounded,
            title: 'Base de datos',
            text: 'Conectada',
            color: AppConfig.verde,
          ),
          Divider(height: 22),
          _StatusLine(
            icon: Icons.verified_user_rounded,
            title: 'Autenticación',
            text: 'Activa',
            color: AppConfig.azulClaro,
          ),
          Divider(height: 22),
          _StatusLine(
            icon: Icons.notifications_active_rounded,
            title: 'Alertas',
            text: 'Configuradas',
            color: AppConfig.naranja,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _guardarConfiguracion,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Guardar configuración'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConfig.rojo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
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
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.3,
                    color: AppConfig.grisOscuro,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  const _StatusLine({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(
                text,
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
  final Color color;

  const _CardHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
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