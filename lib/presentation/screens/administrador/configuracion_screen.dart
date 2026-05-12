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

  // ── Categorías ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _categorias = [];
  bool _cargandoCategorias = true;

  // ── Datos institucionales ─────────────────────────────────────────────────
  final _nombreSistemaController = TextEditingController();
  final _municipioController = TextEditingController();
  bool _cargandoConfig = true;
  bool _guardandoConfig = false;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _cargarConfiguracion();
  }

  @override
  void dispose() {
    _nombreSistemaController.dispose();
    _municipioController.dispose();
    super.dispose();
  }

  // ── Cargar categorías ─────────────────────────────────────────────────────
  Future<void> _cargarCategorias() async {
    setState(() => _cargandoCategorias = true);
    try {
      final response = await _supabase
          .from('categorias')
          .select()
          .order('nombre', ascending: true);
      if (!mounted) return;
      setState(() {
        _categorias = List<Map<String, dynamic>>.from(response);
        _cargandoCategorias = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoCategorias = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar categorías: $e'),
        backgroundColor: AppConfig.rojo,
      ));
    }
  }

  Future<void> _toggleCategoria(Map<String, dynamic> cat, bool value) async {
    try {
      await _supabase.from('categorias').update({
        'activa': value,
      }).eq('id', cat['id']);
      _cargarCategorias();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al actualizar categoría: $e'),
        backgroundColor: AppConfig.rojo,
      ));
    }
  }

  void _mostrarDialogoNuevaCategoria() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                      width: 46, height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppConfig.grisMedio,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const Text('Nueva categoría',
                    style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
                    )),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nombreCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre de la categoría',
                      hintText: 'Ej: Ocupación comercial',
                      prefixIcon: const Icon(Icons.category_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Descripción (opcional)',
                      hintText: 'Breve descripción de la categoría',
                      prefixIcon: const Icon(Icons.description_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                            content: Text('El nombre es requerido'),
                            backgroundColor: AppConfig.rojo,
                          ));
                          return;
                        }
                        try {
                          await _supabase.from('categorias').insert({
                            'nombre': nombre,
                            'descripcion': descCtrl.text.trim().isEmpty
                                ? null
                                : descCtrl.text.trim(),
                            'activa': true,
                          });
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          _cargarCategorias();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Categoría "$nombre" creada'),
                            backgroundColor: AppConfig.verde,
                          ));
                        } catch (e) {
                          if (!ctx.mounted) return;
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                            content: Text('Error al crear categoría: $e'),
                            backgroundColor: AppConfig.rojo,
                          ));
                        }
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar categoría'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.rojo,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

  // ── Cargar configuración institucional ────────────────────────────────────
  Future<void> _cargarConfiguracion() async {
    setState(() => _cargandoConfig = true);
    try {
      final response = await _supabase
          .from('configuracion')
          .select()
          .inFilter('clave', ['nombre_sistema', 'municipio']);
      if (!mounted) return;
      final list = List<Map<String, dynamic>>.from(response);
      for (final item in list) {
        if (item['clave'] == 'nombre_sistema') {
          _nombreSistemaController.text = item['valor']?.toString() ?? '';
        }
        if (item['clave'] == 'municipio') {
          _municipioController.text = item['valor']?.toString() ?? '';
        }
      }
      setState(() => _cargandoConfig = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargandoConfig = false);
      // No mostramos error si la tabla no tiene registros aún
    }
  }

  Future<void> _guardarConfiguracion() async {
    setState(() => _guardandoConfig = true);
    try {
      await _supabase.from('configuracion').upsert([
        {'clave': 'nombre_sistema', 'valor': _nombreSistemaController.text.trim()},
        {'clave': 'municipio', 'valor': _municipioController.text.trim()},
      ], onConflict: 'clave');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Configuración guardada correctamente'),
        backgroundColor: AppConfig.verde,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al guardar configuración: $e'),
        backgroundColor: AppConfig.rojo,
      ));
    } finally {
      if (mounted) setState(() => _guardandoConfig = false);
    }
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
                      _buildCategoriasCard(),
                      const SizedBox(height: 18),
                      _buildDatosInstitucionales(),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: _buildCategoriasCard(),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        flex: 4,
                        child: _buildDatosInstitucionales(),
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
            right: -14, bottom: -24,
            child: Icon(Icons.settings_rounded,
              size: isMobile ? 90 : 130, color: Colors.white.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(icon: Icons.tune_rounded, text: 'Parámetros del sistema'),
              const SizedBox(height: 18),
              Text('Configuración',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36, height: 1.08,
                  fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6,
                )),
              const SizedBox(height: 10),
              Text('Gestiona categorías de denuncia y datos institucionales del sistema.',
                style: TextStyle(
                  fontSize: isMobile ? 13.5 : 15.5, height: 1.4,
                  color: Colors.white.withOpacity(0.84),
                )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriasCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _CardHeading(
                  icon: Icons.category_rounded,
                  title: 'Categorías de denuncia',
                  subtitle: 'Administra las categorías disponibles para ciudadanos.',
                  color: AppConfig.azulClaro,
                ),
              ),
              IconButton(
                onPressed: _mostrarDialogoNuevaCategoria,
                icon: const Icon(Icons.add_circle_rounded, color: AppConfig.rojo, size: 30),
                tooltip: 'Agregar categoría',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_cargandoCategorias)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_categorias.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConfig.grisMedio.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.category_rounded, size: 40, color: AppConfig.grisOscuro),
                  const SizedBox(height: 10),
                  Text(
                    'No hay categorías aún. Presiona + para agregar.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppConfig.grisOscuro, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            ...List.generate(_categorias.length, (i) {
              final cat = _categorias[i];
              final activa = cat['activa'] == true;
              return Column(
                children: [
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: activa
                            ? AppConfig.azulClaro.withOpacity(0.1)
                            : AppConfig.grisMedio.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.label_rounded,
                        color: activa ? AppConfig.azulClaro : AppConfig.grisOscuro,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      cat['nombre']?.toString() ?? '—',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: activa ? AppConfig.azulOscuro : AppConfig.grisOscuro,
                      ),
                    ),
                    subtitle: cat['descripcion'] != null &&
                            cat['descripcion'].toString().isNotEmpty
                        ? Text(
                            cat['descripcion'].toString(),
                            style: TextStyle(fontSize: 12, color: AppConfig.grisOscuro),
                          )
                        : null,
                    trailing: Switch(
                      value: activa,
                      activeColor: AppConfig.azulClaro,
                      onChanged: (val) => _toggleCategoria(cat, val),
                    ),
                  ),
                ],
              );
            }),
          const SizedBox(height: 8),
          Text(
            'Las categorías desactivadas no aparecen en el formulario del ciudadano.',
            style: TextStyle(fontSize: 11.5, color: AppConfig.grisOscuro, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosInstitucionales() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeading(
            icon: Icons.business_rounded,
            title: 'Datos institucionales',
            subtitle: 'Información básica del sistema.',
            color: AppConfig.rojo,
          ),
          const SizedBox(height: 20),
          if (_cargandoConfig)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else ...[
            TextField(
              controller: _nombreSistemaController,
              decoration: InputDecoration(
                labelText: 'Nombre del sistema',
                hintText: 'Ej: Sistema de Reportes Municipales',
                prefixIcon: const Icon(Icons.badge_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _municipioController,
              decoration: InputDecoration(
                labelText: 'Municipio',
                hintText: 'Ej: San Juan de Pasto',
                prefixIcon: const Icon(Icons.location_city_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _guardandoConfig ? null : _guardarConfiguracion,
                icon: _guardandoConfig
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(_guardandoConfig ? 'Guardando...' : 'Guardar cambios'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.rojo,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
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
  final Color color;
  const _CardHeading({
    required this.icon, required this.title,
    required this.subtitle, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46, width: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
              )),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(fontSize: 12.5, color: AppConfig.grisOscuro)),
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
        color: Colors.white.withOpacity(0.16), borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800,
          )),
        ],
      ),
    );
  }
}