import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  // ── Tipos de invasión ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _tipos = [];
  bool _cargandoTipos = true;

  // ── Info del sistema (desde Supabase) ─────────────────────────────────────
  String _nombreSistema = 'Cargando...';
  String _municipio = 'Cargando...';
  bool _cargandoInfo = true;

  // ── Seguridad ─────────────────────────────────────────────────────────────
  final _passwordNuevoCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  bool _obscureNuevo = true;
  bool _obscureConfirm = true;
  bool _guardandoPassword = false;

  // ── Notificaciones (persistidas en Supabase) ──────────────────────────────
  bool _notifFuncionariosPendientes = true;
  bool _notifReportesPendientes = true;
  bool _notifResumenDiario = false;
  bool _cargandoNotif = true;
  bool _guardandoNotif = false;
  String? _adminAuthUserId;

  @override
  void initState() {
    super.initState();
    _adminAuthUserId = _supabase.auth.currentUser?.id;
    _cargarTipos();
    _cargarInfoSistema();
    _cargarPreferenciasNotif();
  }

  @override
  void dispose() {
    _passwordNuevoCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  // ── Tipos de invasión ─────────────────────────────────────────────────────
  Future<void> _cargarTipos() async {
    setState(() => _cargandoTipos = true);
    try {
      final res = await _supabase
          .from('tipos_invasion')
          .select()
          .order('nombre', ascending: true);
      if (!mounted) return;

      final lista = List<Map<String, dynamic>>.from(res);

      // "Otros" siempre al final, sin importar mayúsculas/tildes
      lista.sort((a, b) {
        final aNombre = (a['nombre']?.toString() ?? '').toLowerCase().trim();
        final bNombre = (b['nombre']?.toString() ?? '').toLowerCase().trim();
        final aEsOtros = aNombre == 'otros' || aNombre == 'otro';
        final bEsOtros = bNombre == 'otros' || bNombre == 'otro';
        if (aEsOtros && !bEsOtros) return 1;
        if (!aEsOtros && bEsOtros) return -1;
        return aNombre.compareTo(bNombre);
      });

      setState(() {
        _tipos = lista;
        _cargandoTipos = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoTipos = false);
      _showSnack('Error al cargar tipos: $e', AppConfig.rojo);
    }
  }

  Future<void> _toggleTipo(Map<String, dynamic> tipo, bool value) async {
    try {
      await _supabase
          .from('tipos_invasion')
          .update({'activo': value})
          .eq('id', tipo['id']);
      _cargarTipos();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al actualizar: $e', AppConfig.rojo);
    }
  }

  Future<void> _eliminarTipo(Map<String, dynamic> tipo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar tipo',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
            '¿Eliminar "${tipo['nombre']}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.rojo),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _supabase.from('tipos_invasion').delete().eq('id', tipo['id']);
      if (!mounted) return;
      _showSnack('"${tipo['nombre']}" eliminado', AppConfig.verde);
      _cargarTipos();
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al eliminar: $e', AppConfig.rojo);
    }
  }

  void _mostrarDialogoNuevoTipo() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
                bottom: Radius.circular(18),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 46,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppConfig.grisMedio,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Text(
                    'Nuevo tipo de invasión',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppConfig.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aparecerá automáticamente en el formulario de reportes del ciudadano.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppConfig.grisOscuro,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nombreCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Nombre del tipo *',
                      hintText: 'Ej: Invasión vehicular',
                      prefixIcon: const Icon(Icons.label_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Breve descripción del tipo de invasión',
                      prefixIcon: const Icon(Icons.description_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final nombre = nombreCtrl.text.trim();
                        if (nombre.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('El nombre es requerido'),
                              backgroundColor: AppConfig.rojo,
                            ),
                          );
                          return;
                        }
                        try {
                          await _supabase.from('tipos_invasion').insert({
                            'nombre': nombre,
                            'descripcion': descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            'activo': true,
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _cargarTipos();
                          _showSnack(
                            'Tipo "$nombre" creado y disponible para ciudadanos',
                            AppConfig.verde,
                          );
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppConfig.rojo,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar tipo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.rojo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Info del sistema ──────────────────────────────────────────────────────
  Future<void> _cargarInfoSistema() async {
    setState(() => _cargandoInfo = true);
    try {
      final res = await _supabase
          .from('configuracion')
          .select()
          .inFilter('clave', ['nombre_sistema', 'municipio']);
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(res);
      for (final item in list) {
        if (item['clave'] == 'nombre_sistema') {
          _nombreSistema = item['valor']?.toString() ?? '—';
        }
        if (item['clave'] == 'municipio') {
          _municipio = item['valor']?.toString() ?? '—';
        }
      }
      setState(() => _cargandoInfo = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nombreSistema = 'No disponible';
        _municipio = 'No disponible';
        _cargandoInfo = false;
      });
    }
  }

  // ── Notificaciones ────────────────────────────────────────────────────────
  Future<void> _cargarPreferenciasNotif() async {
    setState(() => _cargandoNotif = true);
    if (_adminAuthUserId == null) {
      setState(() => _cargandoNotif = false);
      return;
    }
    try {
      final res = await _supabase
          .from('admin_preferencias')
          .select()
          .eq('auth_user_id', _adminAuthUserId!)
          .maybeSingle();
      if (!mounted) return;
      if (res != null) {
        setState(() {
          _notifFuncionariosPendientes = res['notif_funcionarios'] == true;
          _notifReportesPendientes = res['notif_reportes'] == true;
          _notifResumenDiario = res['notif_resumen_diario'] == true;
        });
      }
      setState(() => _cargandoNotif = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cargandoNotif = false);
    }
  }

  Future<void> _guardarNotificaciones() async {
    if (_adminAuthUserId == null) return;
    setState(() => _guardandoNotif = true);
    try {
      await _supabase.from('admin_preferencias').upsert({
        'auth_user_id': _adminAuthUserId,
        'notif_funcionarios': _notifFuncionariosPendientes,
        'notif_reportes': _notifReportesPendientes,
        'notif_resumen_diario': _notifResumenDiario,
        'actualizado_en': DateTime.now().toIso8601String(),
      }, onConflict: 'auth_user_id');
      if (!mounted) return;
      _showSnack('Preferencias guardadas', AppConfig.verde);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al guardar preferencias: $e', AppConfig.rojo);
    } finally {
      if (mounted) setState(() => _guardandoNotif = false);
    }
  }

  // ── Seguridad ─────────────────────────────────────────────────────────────
  Future<void> _cambiarPassword() async {
    final nuevo = _passwordNuevoCtrl.text.trim();
    final confirmar = _passwordConfirmCtrl.text.trim();

    if (nuevo.isEmpty || confirmar.isEmpty) {
      _showSnack('Completa los campos de contraseña', AppConfig.rojo);
      return;
    }
    if (nuevo.length < 8) {
      _showSnack(
        'La contraseña debe tener al menos 8 caracteres',
        AppConfig.rojo,
      );
      return;
    }
    if (nuevo != confirmar) {
      _showSnack('Las contraseñas no coinciden', AppConfig.rojo);
      return;
    }

    setState(() => _guardandoPassword = true);
    try {
      await _supabase.auth.updateUser(UserAttributes(password: nuevo));
      if (!mounted) return;
      _passwordNuevoCtrl.clear();
      _passwordConfirmCtrl.clear();
      _showSnack('Contraseña actualizada correctamente', AppConfig.verde);
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error al cambiar contraseña: $e', AppConfig.rojo);
    } finally {
      if (mounted) setState(() => _guardandoPassword = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

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
                      _buildTiposCard(),
                      const SizedBox(height: 18),
                      _buildSeguridadCard(),
                      const SizedBox(height: 18),
                      _buildNotificacionesCard(),
                      const SizedBox(height: 18),
                      _buildInfoSistemaCard(),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: _buildTiposCard()),
                          const SizedBox(width: 22),
                          Expanded(
                            flex: 4,
                            child: Column(
                              children: [
                                _buildInfoSistemaCard(),
                                const SizedBox(height: 18),
                                _buildSeguridadCard(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _buildNotificacionesCard(),
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
      padding: EdgeInsets.all(isMobile ? 22 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConfig.azulOscuro, AppConfig.rojo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
        boxShadow: [
          BoxShadow(
            color: AppConfig.rojo.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -8,
            child: Icon(
              Icons.settings_rounded,
              size: isMobile ? 80 : 110,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.tune_rounded,
                text: 'Parámetros del sistema',
              ),
              const SizedBox(height: 14),
              Text(
                'Configuración',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestiona tipos de invasión, seguridad y preferencias del sistema.',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14.5,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
              const SizedBox(height: 16),
              const Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _HeroChip(
                    icon: Icons.report_problem_rounded,
                    text: 'Tipos de invasión',
                  ),
                  _HeroChip(
                    icon: Icons.lock_rounded,
                    text: 'Seguridad',
                  ),
                  _HeroChip(
                    icon: Icons.notifications_rounded,
                    text: 'Notificaciones',
                  ),
                  _HeroChip(
                    icon: Icons.info_rounded,
                    text: 'Sistema',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tarjeta: Tipos de invasión ────────────────────────────────────────────
  Widget _buildTiposCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _CardHeading(
                  icon: Icons.report_problem_rounded,
                  title: 'Tipos de invasión',
                  subtitle:
                      'Se muestran dinámicamente al ciudadano al reportar.',
                  color: AppConfig.azulClaro,
                ),
              ),
              IconButton(
                onPressed: _mostrarDialogoNuevoTipo,
                icon: const Icon(
                  Icons.add_circle_rounded,
                  color: AppConfig.rojo,
                  size: 30,
                ),
                tooltip: 'Agregar tipo',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_cargandoTipos)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_tipos.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConfig.grisMedio.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.report_problem_rounded,
                    size: 40,
                    color: AppConfig.grisOscuro,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No hay tipos aún. Presiona + para agregar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppConfig.grisOscuro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_tipos.length, (i) {
              final t = _tipos[i];
              final activo = t['activo'] == true;
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: activo
                            ? AppConfig.azulClaro.withOpacity(0.1)
                            : AppConfig.grisMedio.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.label_rounded,
                        color: activo
                            ? AppConfig.azulClaro
                            : AppConfig.grisOscuro,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      t['nombre']?.toString() ?? '—',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: activo
                            ? AppConfig.azulOscuro
                            : AppConfig.grisOscuro,
                      ),
                    ),
                    subtitle: t['descripcion'] != null &&
                            t['descripcion'].toString().isNotEmpty
                        ? Text(
                            t['descripcion'].toString(),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConfig.grisOscuro,
                            ),
                          )
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: activo,
                          activeColor: AppConfig.azulClaro,
                          onChanged: (val) => _toggleTipo(t, val),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: AppConfig.rojo.withOpacity(0.7),
                            size: 20,
                          ),
                          tooltip: 'Eliminar',
                          onPressed: () => _eliminarTipo(t),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppConfig.azulClaro.withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: AppConfig.azulClaro,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Los tipos activos aparecen en el formulario de reporte del ciudadano en tiempo real.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppConfig.grisOscuro,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta: Info del sistema ─────────────────────────────────────────────
  Widget _buildInfoSistemaCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.info_rounded,
            title: 'Información del sistema',
            subtitle: 'Datos reales de la plataforma.',
            color: AppConfig.verde,
          ),
          const SizedBox(height: 16),
          if (_cargandoInfo)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _InfoRow(
              label: 'Sistema',
              value: _nombreSistema,
              icon: Icons.badge_rounded,
            ),
            const Divider(height: 20),
            _InfoRow(
              label: 'Municipio',
              value: _municipio,
              icon: Icons.location_city_rounded,
            ),
            const Divider(height: 20),
          ],
          _InfoRow(
            label: 'Versión',
            value: '1.0.0',
            icon: Icons.tag_rounded,
          ),
          const Divider(height: 20),
          _InfoRow(
            label: 'Base de datos',
            value: 'Supabase',
            icon: Icons.storage_rounded,
          ),
          const Divider(height: 20),
          _InfoRow(
            label: 'Plataforma',
            value: 'Flutter Web',
            icon: Icons.web_rounded,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConfig.verde.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppConfig.verde,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sistema operando con normalidad',
                  style: TextStyle(
                    color: AppConfig.verde,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta: Seguridad ────────────────────────────────────────────────────
  Widget _buildSeguridadCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.lock_rounded,
            title: 'Seguridad de la cuenta',
            subtitle: 'Cambia la contraseña de acceso al panel.',
            color: AppConfig.naranja,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _passwordNuevoCtrl,
            obscureText: _obscureNuevo,
            decoration: InputDecoration(
              labelText: 'Nueva contraseña',
              hintText: 'Mínimo 8 caracteres',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNuevo
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                onPressed: () => setState(() => _obscureNuevo = !_obscureNuevo),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _passwordConfirmCtrl,
            obscureText: _obscureConfirm,
            decoration: InputDecoration(
              labelText: 'Confirmar nueva contraseña',
              prefixIcon: const Icon(Icons.lock_reset_rounded),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppConfig.naranja.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppConfig.naranja,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Usa mínimo 8 caracteres combinando letras y números.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConfig.naranja,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _guardandoPassword ? null : _cambiarPassword,
              icon: _guardandoPassword
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_rounded),
              label: Text(
                _guardandoPassword
                    ? 'Actualizando...'
                    : 'Actualizar contraseña',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.naranja,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tarjeta: Notificaciones ───────────────────────────────────────────────
  Widget _buildNotificacionesCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.notifications_rounded,
            title: 'Notificaciones',
            subtitle:
                'Preferencias guardadas en tu perfil de administrador.',
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 16),
          if (_cargandoNotif)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else ...[
            _NotifTile(
              icon: Icons.person_add_rounded,
              title: 'Funcionarios pendientes',
              subtitle: 'Alerta cuando hay nuevos registros por aprobar.',
              value: _notifFuncionariosPendientes,
              color: AppConfig.naranja,
              onChanged: (v) =>
                  setState(() => _notifFuncionariosPendientes = v),
            ),
            const Divider(height: 1),
            _NotifTile(
              icon: Icons.fact_check_rounded,
              title: 'Reportes por validar',
              subtitle: 'Alerta cuando un reporte pasa a revisión.',
              value: _notifReportesPendientes,
              color: AppConfig.rojo,
              onChanged: (v) => setState(() => _notifReportesPendientes = v),
            ),
            const Divider(height: 1),
            _NotifTile(
              icon: Icons.summarize_rounded,
              title: 'Resumen diario',
              subtitle: 'Recibe un resumen de actividad cada día.',
              value: _notifResumenDiario,
              color: AppConfig.verde,
              onChanged: (v) => setState(() => _notifResumenDiario = v),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _guardandoNotif ? null : _guardarNotificaciones,
                icon: _guardandoNotif
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label:
                    Text(_guardandoNotif ? 'Guardando...' : 'Guardar preferencias'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.azulClaro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Widgets privados ──────────────────────────────────────────────────────────

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
  const _HeroBadge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _NotifTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro),
      ),
      trailing: Switch(value: value, activeColor: color, onChanged: onChanged),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConfig.grisOscuro),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppConfig.grisOscuro, fontSize: 13.5),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            color: valueColor ?? AppConfig.azulOscuro,
          ),
        ),
      ],
    );
  }
}