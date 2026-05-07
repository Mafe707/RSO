import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/denuncia_service.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';

class ConsultarScreen extends StatefulWidget {
  const ConsultarScreen({super.key});

  @override
  State<ConsultarScreen> createState() => _ConsultarScreenState();
}

class _ConsultarScreenState extends State<ConsultarScreen> {
  final _codigoController = TextEditingController();

  bool _consultando = false;
  bool _buscado = false;
  Map<String, dynamic>? _denunciaEncontrada;

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un código de seguimiento'),
          backgroundColor: AppConfig.rojo,
        ),
      );
      return;
    }

    setState(() {
      _consultando = true;
      _buscado = true;
      _denunciaEncontrada = null;
    });

    try {
      final denunciaService = Provider.of<DenunciaService>(
        context,
        listen: false,
      );

      final resultado = await denunciaService.obtenerDenunciaPorCodigo(codigo);

      if (!mounted) return;

      setState(() {
        _denunciaEncontrada = resultado;
        _consultando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _consultando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al consultar: ${e.toString()}'),
          backgroundColor: AppConfig.rojo,
        ),
      );
    }
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_revision':
        return 'En revisión';
      case 'resuelta':
        return 'Resuelta';
      case 'rechazada':
        return 'Rechazada';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFFFF3CD);
      case 'en_revision':
        return const Color(0xFFCCE5FF);
      case 'resuelta':
        return const Color(0xFFD4EDDA);
      case 'rechazada':
        return const Color(0xFFF8D7DA);
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getEstadoTextColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFF856404);
      case 'en_revision':
        return const Color(0xFF004085);
      case 'resuelta':
        return const Color(0xFF155724);
      case 'rechazada':
        return const Color(0xFF721C24);
      default:
        return Colors.grey[800]!;
    }
  }

  String _formatFecha(dynamic valor) {
    if (valor == null) return '—';
    try {
      final dt = DateTime.parse(valor.toString()).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final y = dt.year;
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y $h:$min';
    } catch (_) {
      return valor.toString();
    }
  }

  List<String> _extraerImagenes(Map<String, dynamic> denuncia) {
    final urls = <String>[];

    final imagenPrincipal = denuncia['imagen_url'];
    if (imagenPrincipal != null && imagenPrincipal.toString().trim().isNotEmpty) {
      urls.add(imagenPrincipal.toString().trim());
    }

    final imagenesUrls = denuncia['imagenes_urls'];
    if (imagenesUrls is List) {
      for (final item in imagenesUrls) {
        final url = item?.toString().trim() ?? '';
        if (url.isNotEmpty && !urls.contains(url)) {
          urls.add(url);
        }
      }
    }

    final evidencias = denuncia['evidencias'];
    if (evidencias is List) {
      for (final evidencia in evidencias) {
        if (evidencia is Map) {
          final posiblesCampos = [
            evidencia['imagen_url'],
            evidencia['url'],
            evidencia['archivo_url'],
            evidencia['evidencia_url'],
          ];

          for (final valor in posiblesCampos) {
            final url = valor?.toString().trim() ?? '';
            if (url.isNotEmpty && !urls.contains(url)) {
              urls.add(url);
            }
          }
        }
      }
    }

    return urls;
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 700;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Consultar Estado'),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
      ),
      drawer: CiudadanoDrawer.maybe(context, currentIndex: 2),
      bottomNavigationBar: CiudadanoBottomNav.maybe(context, currentIndex: 2),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 32),
            child: isMobile ? _buildMobileLayout() : _buildWebLayout(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(),
        const SizedBox(height: 18),
        _buildSearchCard(),
        _buildResultSection(),
      ],
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
              _buildHero(),
              const SizedBox(height: 20),
              _buildTipsCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _buildSearchCard(),
              _buildResultSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
        ),
        borderRadius: BorderRadius.circular(28),
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
            right: -10,
            bottom: -18,
            child: Icon(
              Icons.manage_search_rounded,
              size: 110,
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
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number_outlined,
                        size: 16, color: Colors.white),
                    SizedBox(width: 7),
                    Text(
                      'Seguimiento ciudadano',
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
              const Text(
                'Consulta el estado de tu reporte',
                style: TextStyle(
                  fontSize: 28,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ingresa el código único generado al enviar tu denuncia para conocer el avance del proceso.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white.withOpacity(0.82),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.key_rounded,
            title: 'Código de seguimiento',
            subtitle: 'Escribe el código tal como aparece en tu comprobante.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _codigoController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Ej: PSJ-8A4B2C9D',
              prefixIcon: const Icon(Icons.confirmation_number_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onSubmitted: (_) => _consultar(),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _consultando ? null : _consultar,
              icon: _consultando
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(_consultando ? 'Consultando...' : 'Consultar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConfig.azulOscuro,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    if (!_buscado) return const SizedBox.shrink();

    if (_consultando) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: _SoftCard(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_denunciaEncontrada != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: _buildResultadoCard(),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: _SoftCard(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConfig.rojo.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: AppConfig.rojo,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No se encontró el reporte',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppConfig.rojo,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique que el código sea correcto.',
              style: TextStyle(fontSize: 14, color: AppConfig.grisOscuro),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoCard() {
    final d = _denunciaEncontrada!;
    final estado = d['estado']?.toString() ?? '';
    final respuesta = d['respuesta_oficial']?.toString();
    final imagenes = _extraerImagenes(d);

    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppConfig.verde.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppConfig.verde),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reporte encontrado',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          const Text(
            'Detalles del reporte',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppConfig.azulOscuro,
            ),
          ),
          const SizedBox(height: 16),

          _buildDetailRow('Código', d['codigo_unico']?.toString() ?? '—'),
          _buildDetailRow('Ubicación', d['ubicacion']?.toString() ?? '—'),
          _buildDetailRow('Tipo', d['categoria']?.toString() ?? '—'),
          _buildDetailRow('Fecha', _formatFecha(d['creado_en'])),
          _buildEstadoRow(estado),
          _buildDetailRow('Descripción', d['descripcion']?.toString() ?? '—'),

          if (imagenes.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Evidencias fotográficas',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppConfig.azulOscuro,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagenes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final url = imagenes[index];
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: const EdgeInsets.all(16),
                          child: Stack(
                            children: [
                              InteractiveViewer(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: double.infinity,
                                      height: 300,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image_rounded,
                                        size: 56,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 220,
                        color: const Color(0xFFF3F6FB),
                        child: Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            alignment: Alignment.center,
                            color: const Color(0xFFF3F6FB),
                            child: const Icon(
                              Icons.broken_image_rounded,
                              size: 42,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          const Divider(height: 34),

          const Text(
            'Respuesta oficial',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppConfig.azulOscuro,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppConfig.grisMedio),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                      color: AppConfig.azulClaro,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        (respuesta != null && respuesta.isNotEmpty)
                            ? respuesta
                            : 'Aún no hay respuesta oficial para este reporte.',
                        style: TextStyle(
                          fontStyle: (respuesta != null && respuesta.isNotEmpty)
                              ? FontStyle.italic
                              : FontStyle.normal,
                          height: 1.35,
                          color: (respuesta != null && respuesta.isNotEmpty)
                              ? Colors.black87
                              : AppConfig.grisOscuro,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Última actualización: ${_formatFecha(d['actualizado_en'])}',
                  style: TextStyle(fontSize: 11, color: AppConfig.grisOscuro),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: AppConfig.grisOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoRow(String estado) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 112,
            child: Text(
              'Estado:',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _getEstadoColor(estado),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _getEstadoText(estado),
                  style: TextStyle(
                    color: _getEstadoTextColor(estado),
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardHeading(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Recomendaciones',
            subtitle: 'Ten en cuenta antes de consultar.',
          ),
          const SizedBox(height: 18),
          _TipItem(
            icon: Icons.check_circle_outline_rounded,
            text: 'Copia el código exactamente como fue generado.',
          ),
          _TipItem(
            icon: Icons.schedule_rounded,
            text: 'La actualización del estado puede tomar un tiempo.',
          ),
          _TipItem(
            icon: Icons.privacy_tip_outlined,
            text: 'El seguimiento no requiere datos personales.',
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
                style: TextStyle(fontSize: 12.5, color: AppConfig.grisOscuro),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConfig.azulClaro),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.3,
                color: AppConfig.grisOscuro,
              ),
            ),
          ),
        ],
      ),
    );
  }
}