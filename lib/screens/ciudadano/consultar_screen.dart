import 'package:flutter/material.dart';

import '../../config/app_config.dart';
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

  final Map<String, Map<String, dynamic>> _mockDenuncias = {
    'PSJ-8A4B2C9D': {
      'codigo': 'PSJ-8A4B2C9D',
      'ubicacion': 'Cra 25 #18-35, Centro, San Juan de Pasto',
      'categoria': 'Venta informal',
      'fecha': '05/09/2025 14:23',
      'estado': 'revision',
      'descripcion':
          'Vendedores informales obstruyen el paso peatonal con puestos de comida.',
      'respuesta':
          'El caso ha sido asignado a un inspector municipal para su verificación y gestión.',
      'actualizacion': '06/09/2025 09:15',
    },
    'PSJ-123ABC': {
      'codigo': 'PSJ-123ABC',
      'ubicacion': 'Calle 19 #24-50, Barrio La Enerría',
      'categoria': 'Invasión vehicular',
      'fecha': '10/09/2025 08:30',
      'estado': 'pendiente',
      'descripcion': 'Vehículo abandonado obstruyendo la acera.',
      'respuesta': 'Se ha notificado a tránsito municipal.',
      'actualizacion': '10/09/2025 10:00',
    },
    'PSJ-456DEF': {
      'codigo': 'PSJ-456DEF',
      'ubicacion': 'Av. Los Estudiantes #12-08',
      'categoria': 'Ocupación comercial',
      'fecha': '01/09/2025 11:45',
      'estado': 'resuelta',
      'descripcion': 'Restaurante ocupa parte de la vía pública con mesas.',
      'respuesta':
          'Se realizó visita de inspección y se notificó al propietario. El espacio fue despejado.',
      'actualizacion': '08/09/2025 14:30',
    },
  };

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  void _consultar() async {
    if (_codigoController.text.trim().isEmpty) {
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

    await Future.delayed(const Duration(seconds: 1));

    final codigo = _codigoController.text.trim().toUpperCase();
    final encontrada = _mockDenuncias[codigo];

    if (!mounted) return;

    setState(() {
      _denunciaEncontrada = encontrada;
      _consultando = false;
    });
  }

  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'revision':
        return 'En revisión';
      case 'resuelta':
        return 'Resuelta';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFFFFF3CD);
      case 'revision':
        return const Color(0xFFCCE5FF);
      case 'resuelta':
        return const Color(0xFFD4EDDA);
      default:
        return Colors.grey[200]!;
    }
  }

  Color _getEstadoTextColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return const Color(0xFF856404);
      case 'revision':
        return const Color(0xFF004085);
      case 'resuelta':
        return const Color(0xFF155724);
      default:
        return Colors.grey[800]!;
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 700;
  }

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
      drawer: CiudadanoDrawer.maybe(
        context,
        currentIndex: 2,
      ),
      bottomNavigationBar: CiudadanoBottomNav.maybe(
        context,
        currentIndex: 2,
      ),
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
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
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
              style: TextStyle(
                fontSize: 14,
                color: AppConfig.grisOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultadoCard() {
    final denuncia = _denunciaEncontrada!;

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
          _buildDetailRow('Código', denuncia['codigo']),
          _buildDetailRow('Ubicación', denuncia['ubicacion']),
          _buildDetailRow('Categoría', denuncia['categoria']),
          _buildDetailRow('Fecha', denuncia['fecha']),
          _buildEstadoRow(denuncia['estado']),
          _buildDetailRow('Descripción', denuncia['descripcion']),
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
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 19,
                      color: AppConfig.azulClaro,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        denuncia['respuesta'],
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Última actualización: ${denuncia['actualizacion']}',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppConfig.grisOscuro,
                  ),
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
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
              ),
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

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TipItem({
    required this.icon,
    required this.text,
  });

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