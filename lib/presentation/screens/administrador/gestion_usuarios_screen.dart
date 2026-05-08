import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';

class AprobacionFuncionariosScreen extends StatefulWidget {
  const AprobacionFuncionariosScreen({super.key});

  @override
  State<AprobacionFuncionariosScreen> createState() =>
      _AprobacionFuncionariosScreenState();
}

class _AprobacionFuncionariosScreenState
    extends State<AprobacionFuncionariosScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  String _filtroEstado = 'pendiente';
  String _buscarTexto = '';
  bool _cargando = true;
  List<Map<String, dynamic>> _funcionarios = [];

  @override
  void initState() {
    super.initState();
    _cargarFuncionarios();
  }

  Future<void> _cargarFuncionarios() async {
    setState(() => _cargando = true);
    try {
      final response = await _supabase
          .from('funcionarios')
          .select()
          .order('creado_en', ascending: false);
      if (!mounted) return;
      setState(() {
        _funcionarios = List<Map<String, dynamic>>.from(response);
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
    }
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  List<Map<String, dynamic>> get _filtrados {
    return _funcionarios.where((f) {
      if (_filtroEstado.isNotEmpty && f['estado'] != _filtroEstado) return false;
      if (_buscarTexto.isNotEmpty) {
        final q = _buscarTexto.toLowerCase();
        return f['nombre'].toString().toLowerCase().contains(q) ||
            f['correo'].toString().toLowerCase().contains(q) ||
            (f['cargo'] ?? '').toString().toLowerCase().contains(q) ||
            (f['departamento'] ?? '').toString().toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }

  Future<void> _aprobar(Map<String, dynamic> func) async {
    try {
      await _supabase.from('funcionarios').update({
        'estado': 'aprobado',
        'activo': true,
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', func['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${func['nombre']} aprobado correctamente'),
        backgroundColor: AppConfig.verde,
      ));
      _cargarFuncionarios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al aprobar: $e'),
        backgroundColor: AppConfig.rojo,
      ));
    }
  }

  Future<void> _rechazar(Map<String, dynamic> func) async {
    try {
      await _supabase.from('funcionarios').update({
        'estado': 'rechazado',
        'activo': false,
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', func['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${func['nombre']} rechazado'),
        backgroundColor: AppConfig.rojo,
      ));
      _cargarFuncionarios();
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> _toggleActivo(Map<String, dynamic> func) async {
    final nuevoActivo = !(func['activo'] == true);
    try {
      await _supabase.from('funcionarios').update({
        'activo': nuevoActivo,
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', func['id']);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(nuevoActivo
            ? '${func['nombre']} activado'
            : '${func['nombre']} desactivado'),
        backgroundColor: nuevoActivo ? AppConfig.verde : AppConfig.naranja,
      ));
      _cargarFuncionarios();
    } catch (e) {
      if (!mounted) return;
    }
  }

  void _mostrarDetalle(Map<String, dynamic> func) {
    final estado = func['estado']?.toString() ?? 'pendiente';
    final activo = func['activo'] == true;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
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
            child: SingleChildScrollView(
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
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: _estadoColor(estado).withOpacity(0.12),
                        child: Text(
                          (func['nombre']?.toString() ?? 'F')[0].toUpperCase(),
                          style: TextStyle(
                            color: _estadoColor(estado),
                            fontWeight: FontWeight.w900, fontSize: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(func['nombre'] ?? '—', style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
                            )),
                            const SizedBox(height: 4),
                            Text(func['correo'] ?? '—',
                              style: TextStyle(color: AppConfig.grisOscuro, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  _buildInfoRow('Cargo', func['cargo'] ?? '—'),
                  _buildInfoRow('Departamento', func['departamento'] ?? '—'),
                  _buildInfoRow('Estado', _estadoText(estado)),
                  _buildInfoRow('Activo', activo ? 'Sí' : 'No'),
                  const SizedBox(height: 20),

                  if (estado == 'pendiente') ...[
                    LayoutBuilder(builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 430;
                      final aprobarBtn = ElevatedButton.icon(
                        onPressed: () { Navigator.pop(ctx); _aprobar(func); },
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('Aprobar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.verde,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                      final rechazarBtn = ElevatedButton.icon(
                        onPressed: () { Navigator.pop(ctx); _rechazar(func); },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Rechazar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.rojo,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      );
                      if (isNarrow) {
                        return Column(children: [
                          SizedBox(width: double.infinity, child: aprobarBtn),
                          const SizedBox(height: 12),
                          SizedBox(width: double.infinity, child: rechazarBtn),
                        ]);
                      }
                      return Row(children: [
                        Expanded(child: aprobarBtn),
                        const SizedBox(width: 12),
                        Expanded(child: rechazarBtn),
                      ]);
                    }),
                  ] else if (estado == 'aprobado') ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () { Navigator.pop(ctx); _toggleActivo(func); },
                        icon: Icon(activo ? Icons.block_rounded : Icons.check_circle_rounded),
                        label: Text(activo ? 'Desactivar' : 'Activar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: activo ? AppConfig.naranja : AppConfig.verde,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return AppConfig.naranja;
      case 'aprobado': return AppConfig.verde;
      case 'rechazado': return AppConfig.rojo;
      default: return AppConfig.grisOscuro;
    }
  }

  String _estadoText(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente aprobación';
      case 'aprobado': return 'Aprobado';
      case 'rechazado': return 'Rechazado';
      default: return estado;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 112, child: Text('$label:', style: const TextStyle(
            fontWeight: FontWeight.w800, color: Colors.black87,
          ))),
          Expanded(child: Text(value, style: TextStyle(
            color: AppConfig.grisOscuro, height: 1.35,
          ))),
        ],
      ),
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
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 16 : 28),
            child: isMobile ? _buildMobileLayout() : _buildWebLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildHero(isMobile: true),
        const SizedBox(height: 16),
        _buildFilters(),
        const SizedBox(height: 12),
        Expanded(child: _buildLista()),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 4, child: Column(children: [
          _buildHero(isMobile: false),
          const SizedBox(height: 20),
          _buildResumenCard(),
        ])),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: Column(children: [
          _buildFilters(),
          const SizedBox(height: 14),
          Expanded(child: _buildLista()),
        ])),
      ],
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(color: AppConfig.azulOscuro.withOpacity(0.18), blurRadius: 22, offset: const Offset(0, 12)),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14, bottom: -24,
            child: Icon(Icons.how_to_reg_rounded,
              size: isMobile ? 90 : 130, color: Colors.white.withOpacity(0.08)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroBadge(icon: Icons.manage_accounts_rounded, text: 'Aprobación de funcionarios'),
              const SizedBox(height: 18),
              Text(
                'Aprobación de funcionarios',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 36, height: 1.08,
                  fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Valida registros institucionales, aprueba o rechaza accesos al sistema.',
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

  Widget _buildResumenCard() {
    final pendientes = _funcionarios.where((f) => f['estado'] == 'pendiente').length;
    final aprobados = _funcionarios.where((f) => f['estado'] == 'aprobado').length;
    final rechazados = _funcionarios.where((f) => f['estado'] == 'rechazado').length;

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(icon: Icons.insights_rounded, title: 'Resumen', subtitle: 'Estado de funcionarios.'),
          const SizedBox(height: 18),
          _SummaryRow(label: 'Pendientes', value: '$pendientes', color: AppConfig.naranja),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Aprobados', value: '$aprobados', color: AppConfig.verde),
          const SizedBox(height: 10),
          _SummaryRow(label: 'Rechazados', value: '$rechazados', color: AppConfig.rojo),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return _SoftCard(
      child: Column(
        children: [
          Row(children: const [
            Icon(Icons.tune_rounded, color: AppConfig.azulOscuro),
            SizedBox(width: 8),
            Text('Filtros', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
            )),
          ]),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _filtroEstado.isEmpty ? null : _filtroEstado,
            hint: const Text('Estado'),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: '', child: Text('Todos')),
              DropdownMenuItem(value: 'pendiente', child: Text('Pendientes')),
              DropdownMenuItem(value: 'aprobado', child: Text('Aprobados')),
              DropdownMenuItem(value: 'rechazado', child: Text('Rechazados')),
            ],
            onChanged: (v) => setState(() => _filtroEstado = v ?? ''),
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por nombre, correo, cargo...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true, fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onChanged: (v) => setState(() => _buscarTexto = v),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_cargando) return const Center(child: CircularProgressIndicator());

    if (_filtrados.isEmpty) {
      return _SoftCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.how_to_reg_rounded, size: 54, color: AppConfig.azulClaro),
                const SizedBox(height: 12),
                const Text('Sin resultados', style: TextStyle(
                  fontSize: 19, fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
                )),
                const SizedBox(height: 6),
                Text('No hay funcionarios que coincidan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConfig.grisOscuro)),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filtrados.length,
      itemBuilder: (context, index) {
        final f = _filtrados[index];
        final estado = f['estado']?.toString() ?? 'pendiente';
        final activo = f['activo'] == true;
        final color = _estadoColor(estado);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppConfig.grisMedio),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Text(
                (f['nombre']?.toString() ?? 'F')[0].toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.w900),
              ),
            ),
            title: Text(f['nombre'] ?? '—', style: const TextStyle(
              fontWeight: FontWeight.w900, color: AppConfig.azulOscuro,
            )),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['correo'] ?? '—'),
                  const SizedBox(height: 4),
                  Text(f['cargo'] ?? '—', style: TextStyle(
                    fontSize: 12.5, color: AppConfig.grisOscuro,
                  )),
                  const SizedBox(height: 7),
                  Wrap(spacing: 8, runSpacing: 6, children: [
                    _StatusChip(label: _estadoText(estado), color: color),
                    if (estado == 'aprobado')
                      _StatusChip(
                        label: activo ? 'Activo' : 'Inactivo',
                        color: activo ? AppConfig.verde : AppConfig.rojo,
                      ),
                  ]),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: estado == 'pendiente'
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.naranja.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('REVISAR', style: TextStyle(
                      fontSize: 10, color: AppConfig.naranja, fontWeight: FontWeight.w900,
                    )),
                  )
                : const Icon(Icons.chevron_right_rounded),
            onTap: () => _mostrarDetalle(f),
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 10.5, color: color, fontWeight: FontWeight.w800,
      )),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
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
  const _CardHeading({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46, width: 46,
          decoration: BoxDecoration(
            color: AppConfig.azulClaro.withOpacity(0.1), borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.azulClaro),
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