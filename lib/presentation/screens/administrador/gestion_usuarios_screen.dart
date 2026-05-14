import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../core/supabase/supabase_config.dart';

class GestionFuncionariosScreen extends StatefulWidget {
  const GestionFuncionariosScreen({super.key});

  @override
  State<GestionFuncionariosScreen> createState() =>
      _GestionFuncionariosScreenState();
}

class _GestionFuncionariosScreenState extends State<GestionFuncionariosScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  String _filtroEstado = 'pendiente';
  String _buscarTexto = '';
  bool _cargando = true;
  bool _recargando = false;
  List<Map<String, dynamic>> _funcionarios = [];

  @override
  void initState() {
    super.initState();
    _cargarFuncionarios();
  }

  Future<void> _cargarFuncionarios({bool silencioso = false}) async {
    if (silencioso) {
      setState(() => _recargando = true);
    } else {
      setState(() => _cargando = true);
    }

    try {
      final response = await _supabase
          .from('funcionarios')
          .select()
          .order('creado_en', ascending: false);

      if (!mounted) return;

      setState(() {
        _funcionarios = List<Map<String, dynamic>>.from(response);
        _cargando = false;
        _recargando = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _cargando = false;
        _recargando = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar funcionarios: $e'),
          backgroundColor: AppConfig.rojo,
        ),
      );
    }
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  List<Map<String, dynamic>> get _filtrados {
    return _funcionarios.where((f) {
      if (_filtroEstado.isNotEmpty && f['estado'] != _filtroEstado) {
        return false;
      }
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${func['nombre']} aprobado correctamente'),
          backgroundColor: AppConfig.verde,
        ),
      );
      _cargarFuncionarios(silencioso: true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aprobar: $e'),
          backgroundColor: AppConfig.rojo,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${func['nombre']} rechazado'),
          backgroundColor: AppConfig.rojo,
        ),
      );
      _cargarFuncionarios(silencioso: true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al rechazar: $e'),
          backgroundColor: AppConfig.rojo,
        ),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoActivo
                ? '${func['nombre']} activado'
                : '${func['nombre']} desactivado',
          ),
          backgroundColor: nuevoActivo ? AppConfig.verde : AppConfig.naranja,
        ),
      );
      _cargarFuncionarios(silencioso: true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppConfig.rojo,
        ),
      );
    }
  }

  Future<int> _contarReportesAsignados(int funcionarioId) async {
    try {
      final response = await _supabase
          .from('denuncias')
          .select('id')
          .eq('funcionario_id', funcionarioId)
          .eq('estado', 'en_revision');
      return (response as List).length;
    } catch (_) {
      return 0;
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
        int? reportesAsignados;
        bool cargandoConteo = true;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (cargandoConteo) {
              cargandoConteo = false;
              Future.microtask(() async {
                final count = await _contarReportesAsignados(func['id'] as int);
                if (ctx.mounted) {
                  setModalState(() {
                    reportesAsignados = count;
                  });
                }
              });
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
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
                  child: SingleChildScrollView(
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
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  _estadoColor(estado).withOpacity(0.12),
                              child: Text(
                                (func['nombre']?.toString() ?? 'F')[0]
                                    .toUpperCase(),
                                style: TextStyle(
                                  color: _estadoColor(estado),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    func['nombre'] ?? '—',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: AppConfig.azulOscuro,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    func['correo'] ?? '—',
                                    style: TextStyle(
                                      color: AppConfig.grisOscuro,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        _buildInfoRow('Cargo', func['cargo'] ?? '—'),
                        _buildInfoRow(
                          'Departamento',
                          func['departamento'] ?? '—',
                        ),
                        _buildInfoRow('Estado', _estadoText(estado)),
                        _buildInfoRow('Activo', activo ? 'Sí' : 'No'),
                        _buildInfoRow(
                          'Fecha registro',
                          _formatFecha(func['creado_en']),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConfig.azulClaro.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.assignment_rounded,
                                color: AppConfig.azulClaro,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  reportesAsignados == null
                                      ? 'Cargando reportes asignados...'
                                      : 'Reportes en revisión actualmente: $reportesAsignados',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppConfig.azulClaro,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (estado == 'pendiente') ...[
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isNarrow = constraints.maxWidth < 430;

                              final aprobarBtn = ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _aprobar(func);
                                },
                                icon: const Icon(Icons.check_rounded),
                                label: const Text('Aprobar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.verde,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );

                              final rechazarBtn = ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  _rechazar(func);
                                },
                                icon: const Icon(Icons.close_rounded),
                                label: const Text('Rechazar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConfig.rojo,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              );

                              if (isNarrow) {
                                return Column(
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      child: aprobarBtn,
                                    ),
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: rechazarBtn,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: aprobarBtn),
                                  const SizedBox(width: 12),
                                  Expanded(child: rechazarBtn),
                                ],
                              );
                            },
                          ),
                        ] else if (estado == 'aprobado') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _toggleActivo(func);
                              },
                              icon: Icon(
                                activo
                                    ? Icons.block_rounded
                                    : Icons.check_circle_rounded,
                              ),
                              label: Text(
                                activo
                                    ? 'Desactivar funcionario'
                                    : 'Activar funcionario',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: activo
                                    ? AppConfig.naranja
                                    : AppConfig.verde,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatFecha(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      final dt = DateTime.parse(fecha.toString()).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return fecha.toString();
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppConfig.grisOscuro,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppConfig.naranja;
      case 'aprobado':
        return AppConfig.verde;
      case 'rechazado':
        return AppConfig.rojo;
      default:
        return AppConfig.grisOscuro;
    }
  }

  String _estadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'aprobado':
        return 'Aprobado';
      case 'rechazado':
        return 'Rechazado';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    if (isMobile) {
      return SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(isMobile: true),
              const SizedBox(height: 16),
              _buildResumen(),
              const SizedBox(height: 16),
              _buildFiltros(true),
              const SizedBox(height: 12),
              _buildLista(),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHero(isMobile: false),
                    const SizedBox(height: 20),
                    _buildResumen(),
                    const SizedBox(height: 20),
                    _buildFiltros(false),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: _buildLista(),
                ),
              ),
            ],
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
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
        boxShadow: [
          BoxShadow(
            color: AppConfig.azulClaro.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -5,
            bottom: -8,
            child: Icon(
              Icons.manage_accounts_rounded,
              size: isMobile ? 80 : 110,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Expanded(
                    child: _HeroBadge(
                      icon: Icons.manage_accounts_rounded,
                      text: 'Gestión de Funcionarios',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Gestión de Funcionarios',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Aprueba, rechaza o gestiona el estado de los funcionarios del sistema.',
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14.5,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumen() {
    final pendientes =
        _funcionarios.where((f) => f['estado'] == 'pendiente').length;
    final aprobados =
        _funcionarios.where((f) => f['estado'] == 'aprobado').length;
    final rechazados =
        _funcionarios.where((f) => f['estado'] == 'rechazado').length;

    final isMobile = _isMobile(context);

    final cards = [
      _SummaryRow(
        label: 'Pendientes',
        value: '$pendientes',
        color: AppConfig.naranja,
      ),
      _SummaryRow(
        label: 'Aprobados',
        value: '$aprobados',
        color: AppConfig.verde,
      ),
      _SummaryRow(
        label: 'Rechazados',
        value: '$rechazados',
        color: AppConfig.rojo,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            SizedBox(width: double.infinity, child: cards[i]),
            if (i != cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: cards[0]),
        const SizedBox(width: 12),
        Expanded(child: cards[1]),
        const SizedBox(width: 12),
        Expanded(child: cards[2]),
      ],
    );
  }

  Widget _buildFiltros(bool isMobile) {
    final filtros = [
      {'label': 'Todos', 'value': ''},
      {'label': 'Pendientes', 'value': 'pendiente'},
      {'label': 'Aprobados', 'value': 'aprobado'},
      {'label': 'Rechazados', 'value': 'rechazado'},
    ];

    Widget buscador = SizedBox(
      height: 44,
      child: TextField(
        onChanged: (v) => setState(() => _buscarTexto = v),
        decoration: InputDecoration(
          hintText: 'Buscar...',
          prefixIcon: const Icon(Icons.search_rounded, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConfig.grisMedio),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConfig.grisMedio),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppConfig.azulClaro),
          ),
          isDense: true,
        ),
      ),
    );

    Widget chipsWrap = Wrap(
      spacing: 6,
      runSpacing: 8,
      children: filtros.map((f) {
        final selected = _filtroEstado == f['value'];
        return FilterChip(
          label: Text(
            f['label']!,
            style: const TextStyle(fontSize: 12),
          ),
          selected: selected,
          onSelected: (_) => setState(() => _filtroEstado = f['value']!),
          selectedColor: AppConfig.azulClaro.withOpacity(0.15),
          checkmarkColor: AppConfig.azulClaro,
          visualDensity: VisualDensity.compact,
          labelStyle: TextStyle(
            color: selected ? AppConfig.azulClaro : AppConfig.grisOscuro,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          ),
        );
      }).toList(),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buscador,
          const SizedBox(height: 12),
          chipsWrap,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: buscador),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filtros.map((f) {
                final selected = _filtroEstado == f['value'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      f['label']!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _filtroEstado = f['value']!),
                    selectedColor: AppConfig.azulClaro.withOpacity(0.15),
                    checkmarkColor: AppConfig.azulClaro,
                    visualDensity: VisualDensity.compact,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppConfig.azulClaro
                          : AppConfig.grisOscuro,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLista() {
    if (_cargando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filtrados.isEmpty) {
      return _SoftCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.manage_accounts_rounded,
                  size: 54,
                  color: AppConfig.azulClaro,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Sin resultados',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: AppConfig.azulOscuro,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'No hay funcionarios que coincidan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppConfig.grisOscuro),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      primary: false,
      physics: _isMobile(context)
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
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
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            title: Text(
              f['nombre'] ?? '—',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppConfig.azulOscuro,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['correo'] ?? '—'),
                  const SizedBox(height: 4),
                  Text(
                    f['cargo'] ?? '—',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppConfig.grisOscuro,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _StatusChip(
                        label: _estadoText(estado),
                        color: color,
                      ),
                      if (estado == 'aprobado')
                        _StatusChip(
                          label: activo ? 'Activo' : 'Inactivo',
                          color: activo ? AppConfig.verde : AppConfig.rojo,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: _isMobile(context)
                ? Icon(
                    estado == 'pendiente'
                        ? Icons.manage_accounts_rounded
                        : Icons.chevron_right_rounded,
                    color: estado == 'pendiente'
                        ? AppConfig.naranja
                        : AppConfig.grisOscuro,
                  )
                : estado == 'pendiente'
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppConfig.naranja.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'REVISAR',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppConfig.naranja,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
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