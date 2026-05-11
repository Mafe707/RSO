import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/app_config.dart';
import '../../../services/auth_service.dart';
import '../../../services/denuncia_service.dart';
import '../../../core/supabase/supabase_config.dart';

import 'funcionario_bottom_nav.dart';
import 'funcionario_drawer.dart';
import 'login_screen.dart';

class MisCasosScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const MisCasosScreen({super.key, required this.userData});

  @override
  State<MisCasosScreen> createState() => _MisCasosScreenState();
}

class _MisCasosScreenState extends State<MisCasosScreen> {
  final SupabaseClient _supabase = SupabaseConfig.client;

  List<Map<String, dynamic>> _casos = [];
  bool _loading = true;
  String? _errorMsg;
  String _filtroEstado = '';
  String _buscarTexto = '';

  @override
  void initState() {
    super.initState();
    _cargarCasos();
  }

  Future<void> _cargarCasos() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final funcionarioId = authService.funcionarioData?['id'];

      if (funcionarioId == null) {
        setState(() {
          _errorMsg = 'No se pudo obtener tu ID de funcionario';
          _loading = false;
        });
        return;
      }

      final response = await _supabase
          .from('denuncias')
          .select(
            'id, codigo_unico, ubicacion, categoria, estado, descripcion, respuesta_oficial, imagen_url, creado_en, actualizado_en',
          )
          .eq('funcionario_id', funcionarioId)
          .order('creado_en', ascending: false);

      setState(() {
        _casos = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = 'Error al cargar casos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _cambiarEstado(int id, String nuevoEstado) async {
    try {
      await _supabase.from('denuncias').update({
        'estado': nuevoEstado,
        'actualizado_en': DateTime.now().toIso8601String(),
      }).eq('id', id);

      setState(() {
        final index = _casos.indexWhere((c) => c['id'] == id);
        if (index != -1) {
          _casos[index]['estado'] = nuevoEstado;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Estado actualizado a ${_getEstadoText(nuevoEstado)}',
            ),
            backgroundColor: AppConfig.verde,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConfig.rojo,
          ),
        );
      }
    }
  }

  Future<void> _enviarAValidacion(
    int id,
    String respuestaOficial,
  ) async {
    final service = Provider.of<DenunciaService>(context, listen: false);

    final ok = await service.agregarRespuestaOficial(id, respuestaOficial);

    if (!mounted) return;

    if (ok) {
      await _cargarCasos();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Caso enviado a validación del administrador'),
          backgroundColor: AppConfig.verde,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo enviar el caso a validación'),
          backgroundColor: AppConfig.rojo,
        ),
      );
    }
  }

  Future<void> _cerrarSesion() async {
  final authService = Provider.of<AuthService>(context, listen: false);
  await authService.logout();
  if (mounted) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const FuncionarioLoginScreen()),
      (route) => false,
    );
  }
}

  List<Map<String, dynamic>> get _casosFiltrados {
    return _casos.where((caso) {
      if (_filtroEstado.isNotEmpty && caso['estado'] != _filtroEstado) {
        return false;
      }
      if (_buscarTexto.isNotEmpty) {
        final texto = _buscarTexto.toLowerCase();
        return (caso['codigo_unico']
                    ?.toString()
                    .toLowerCase()
                    .contains(texto) ??
                false) ||
            (caso['ubicacion']?.toString().toLowerCase().contains(texto) ??
                false);
      }
      return true;
    }).toList();
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_revision':
        return 'En revisión';
      case 'resuelto_pendiente_validacion':
        return 'Pend. validación';
      case 'devuelto':
        return 'Devuelto';
      case 'resuelto_publicado':
        return 'Publicado';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return AppConfig.naranja;
      case 'en_revision':
        return AppConfig.azulClaro;
      case 'resuelto_pendiente_validacion':
        return AppConfig.rojo;
      case 'devuelto':
        return const Color(0xFF9C27B0);
      case 'resuelto_publicado':
        return AppConfig.verde;
      default:
        return AppConfig.grisOscuro;
    }
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  void _verDetalles(Map<String, dynamic> caso) {
    final codigo = caso['codigo_unico'] ?? '';
    final ubicacion = caso['ubicacion'] ?? '';
    final categoria = caso['categoria'] ?? '';
    final estado = caso['estado'] ?? 'pendiente';
    final descripcion = caso['descripcion'] ?? '';
    final respuestaActual = caso['respuesta_oficial']?.toString() ?? '';
    final imagenUrl = caso['imagen_url']?.toString();
    final id = caso['id'] as int;

    final respuestaController = TextEditingController(text: respuestaActual);

    void abrirImagenCompleta() {
      if (imagenUrl == null || imagenUrl.isEmpty) return;

      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Imagen completa',
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Stack(
                children: [
                  Center(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Image.network(
                        imagenUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: double.infinity,
                            height: double.infinity,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) {
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.black,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.white70,
                                size: 54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Material(
                      color: Colors.white.withOpacity(0.12),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Cerrar',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final yaCerrado = estado == 'resuelto_pendiente_validacion' ||
            estado == 'resuelto_publicado';

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
                      Container(
                        width: 8,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _getEstadoColor(estado),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              codigo,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppConfig.azulOscuro,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              ubicacion,
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
                  const SizedBox(height: 18),

                  if (imagenUrl != null && imagenUrl.isNotEmpty) ...[
                    GestureDetector(
                      onTap: abrirImagenCompleta,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          children: [
                            Image.network(
                              imagenUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: AppConfig.grisClaro,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stack) =>
                                  Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppConfig.grisClaro,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.45),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.zoom_in_rounded,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Ver completa',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.image_rounded,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Toca la imagen para verla completa',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppConfig.grisOscuro,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Divider(),
                  _buildInfoRow('Categoría', categoria),
                  _buildInfoRow('Ubicación', ubicacion),
                  _buildInfoRow('Estado', _getEstadoText(estado)),
                  if (descripcion.isNotEmpty)
                    _buildInfoRow('Descripción', descripcion),
                  if (estado == 'devuelto') ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Motivo devolución',
                      respuestaActual.isEmpty ? '—' : respuestaActual,
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Respuesta oficial',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: AppConfig.azulOscuro,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: respuestaController,
                    enabled: !yaCerrado,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'Redacta la respuesta oficial para enviar al administrador...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 420;

                      final btnRevision = ElevatedButton.icon(
                        onPressed: yaCerrado
                            ? null
                            : () {
                                Navigator.pop(context);
                                _cambiarEstado(id, 'en_revision');
                              },
                        icon: const Icon(Icons.pending_actions_rounded),
                        label: const Text('En revisión'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.azulClaro,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      );

                      final btnResolver = ElevatedButton.icon(
                        onPressed: yaCerrado
                            ? null
                            : () {
                                final respuesta =
                                    respuestaController.text.trim();
                                if (respuesta.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Debes escribir una respuesta oficial',
                                      ),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(context);
                                _enviarAValidacion(id, respuesta);
                              },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Enviar a validación'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConfig.verde,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      );

                      if (narrow) {
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: btnRevision,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: btnResolver,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: btnRevision),
                          const SizedBox(width: 12),
                          Expanded(child: btnResolver),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Cerrar'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppConfig.grisOscuro,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Mis Casos',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        centerTitle: isMobile,
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _cargarCasos,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      drawer: FuncionarioDrawer.maybe(
        context,
        currentIndex: 1,
        userData: widget.userData,
      ),
      bottomNavigationBar:
          FuncionarioBottomNav.maybe(context, currentIndex: 1),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: isMobile
                ? _buildMobileLayout()
                : Padding(
                    padding: const EdgeInsets.all(28),
                    child: _buildWebLayout(),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          color: const Color(0xFFF5F7FB),
          child: _buildMobileTopFilters(),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTopFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppConfig.grisMedio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.tune_rounded,
                color: AppConfig.azulOscuro,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Filtros de casos',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: AppConfig.azulOscuro,
                  ),
                ),
              ),
              if (_filtroEstado.isNotEmpty || _buscarTexto.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filtroEstado = '';
                      _buscarTexto = '';
                    });
                  },
                  child: const Text('Limpiar'),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _filtroEstado.isEmpty ? null : _filtroEstado,
                  hint: const Text('Estado'),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todos')),
                    DropdownMenuItem(
                      value: 'pendiente',
                      child: Text('Pendiente'),
                    ),
                    DropdownMenuItem(
                      value: 'en_revision',
                      child: Text('En revisión'),
                    ),
                    DropdownMenuItem(
                      value: 'resuelto_pendiente_validacion',
                      child: Text('Validación'),
                    ),
                    DropdownMenuItem(
                      value: 'resuelto_publicado',
                      child: Text('Publicado'),
                    ),
                    DropdownMenuItem(
                      value: 'devuelto',
                      child: Text('Devuelto'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _filtroEstado = value ?? ''),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 44,
                height: 44,
                child: Material(
                  color: AppConfig.azulOscuro.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _cargarCasos,
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppConfig.azulOscuro,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por código o ubicación...',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) => setState(() => _buscarTexto = value),
          ),
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHero(isMobile: false),
              const SizedBox(height: 20),
              _buildSummaryCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              _buildFilters(),
              const SizedBox(height: 14),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMsg != null) {
      return _EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Error',
        text: _errorMsg!,
      );
    }

    if (_casosFiltrados.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off_rounded,
        title: 'Sin casos',
        text: 'No tienes casos asignados que coincidan con los filtros.',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarCasos,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _casosFiltrados.length,
        itemBuilder: (context, index) {
          final caso = _casosFiltrados[index];
          final estado = caso['estado'] ?? 'pendiente';
          return _CaseCard(
            caso: caso,
            estadoText: _getEstadoText(estado),
            estadoColor: _getEstadoColor(estado),
            onTap: () => _verDetalles(caso),
          );
        },
      ),
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
            right: -14,
            bottom: -24,
            child: Icon(
              Icons.assignment_rounded,
              size: isMobile ? 90 : 130,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeroBadge(
                icon: Icons.assignment_turned_in_rounded,
                text: 'Gestión de casos',
              ),
              const SizedBox(height: 18),
              Text(
                'Mis casos asignados',
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
                'Consulta y actualiza los reportes que tienes asignados.',
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

  Widget _buildSummaryCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.insights_rounded,
            title: 'Resumen',
            subtitle: 'Vista rápida de tus casos.',
          ),
          const SizedBox(height: 18),
          _SummaryRow(
            label: 'Total',
            value: '${_casos.length}',
            color: AppConfig.azulOscuro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Pendientes',
            value:
                '${_casos.where((c) => c['estado'] == 'pendiente').length}',
            color: AppConfig.naranja,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'En revisión',
            value:
                '${_casos.where((c) => c['estado'] == 'en_revision').length}',
            color: AppConfig.azulClaro,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Pend. validación',
            value:
                '${_casos.where((c) => c['estado'] == 'resuelto_pendiente_validacion').length}',
            color: AppConfig.rojo,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Publicados',
            value:
                '${_casos.where((c) => c['estado'] == 'resuelto_publicado').length}',
            color: AppConfig.verde,
          ),
          const SizedBox(height: 10),
          _SummaryRow(
            label: 'Devueltos',
            value:
                '${_casos.where((c) => c['estado'] == 'devuelto').length}',
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return _SoftCard(
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.tune_rounded, color: AppConfig.azulOscuro),
              SizedBox(width: 8),
              Text(
                'Filtros',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _filtroEstado.isEmpty ? null : _filtroEstado,
            hint: const Text('Estado'),
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: '', child: Text('Todos')),
              DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
              DropdownMenuItem(
                value: 'en_revision',
                child: Text('En revisión'),
              ),
              DropdownMenuItem(
                value: 'resuelto_pendiente_validacion',
                child: Text('Pend. validación'),
              ),
              DropdownMenuItem(
                value: 'resuelto_publicado',
                child: Text('Publicado'),
              ),
              DropdownMenuItem(value: 'devuelto', child: Text('Devuelto')),
            ],
            onChanged: (value) => setState(() => _filtroEstado = value ?? ''),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar por código o ubicación...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onChanged: (value) => setState(() => _buscarTexto = value),
          ),
        ],
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  final Map<String, dynamic> caso;
  final String estadoText;
  final Color estadoColor;
  final VoidCallback onTap;

  const _CaseCard({
    required this.caso,
    required this.estadoText,
    required this.estadoColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final codigo = caso['codigo_unico'] ?? '';
    final ubicacion = caso['ubicacion'] ?? '';
    final categoria = caso['categoria'] ?? '';

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
          backgroundColor: estadoColor.withOpacity(0.12),
          child: Icon(Icons.assignment_rounded, color: estadoColor),
        ),
        title: Text(
          codigo,
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
              Text(ubicacion),
              const SizedBox(height: 7),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _StatusChip(label: estadoText, color: estadoColor),
                  Text(
                    categoria,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
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

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 54, color: AppConfig.azulClaro),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppConfig.grisOscuro),
              ),
            ],
          ),
        ),
      ),
    );
  }
}