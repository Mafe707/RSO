import 'package:flutter/material.dart';
import '../../config/app_config.dart';

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
  
  // Datos mock para simular respuesta
  final Map<String, Map<String, dynamic>> _mockDenuncias = {
    'PSJ-8A4B2C9D': {
      'codigo': 'PSJ-8A4B2C9D',
      'ubicacion': 'Cra 25 #18-35, Centro, San Juan de Pasto',
      'categoria': 'Venta informal',
      'fecha': '05/09/2025 14:23',
      'estado': 'revision',
      'descripcion': 'Vendedores informales obstruyen el paso peatonal con puestos de comida.',
      'respuesta': 'El caso ha sido asignado a un inspector municipal para su verificación y gestión.',
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
      'respuesta': 'Se realizó visita de inspección y se notificó al propietario. El espacio fue despejado.',
      'actualizacion': '08/09/2025 14:30',
    },
  };
  
  void _consultar() async {
    if (_codigoController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un código de seguimiento'), backgroundColor: AppConfig.rojo),
      );
      return;
    }
    
    setState(() {
      _consultando = true;
      _buscado = true;
      _denunciaEncontrada = null;
    });
    
    // Simular consulta
    await Future.delayed(const Duration(seconds: 1));
    
    final codigo = _codigoController.text.trim().toUpperCase();
    final encontrada = _mockDenuncias[codigo];
    
    setState(() {
      _denunciaEncontrada = encontrada;
      _consultando = false;
    });
  }
  
  String _getEstadoText(String estado) {
    switch (estado) {
      case 'pendiente': return 'Pendiente';
      case 'revision': return 'En revisión';
      case 'resuelta': return 'Resuelta';
      default: return estado;
    }
  }
  
  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente': return const Color(0xFFFFF3CD);
      case 'revision': return const Color(0xFFCCE5FF);
      case 'resuelta': return const Color(0xFFD4EDDA);
      default: return Colors.grey[200]!;
    }
  }
  
  Color _getEstadoTextColor(String estado) {
    switch (estado) {
      case 'pendiente': return const Color(0xFF856404);
      case 'revision': return const Color(0xFF004085);
      case 'resuelta': return const Color(0xFF155724);
      default: return Colors.grey[800]!;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultar Estado')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Código de seguimiento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConfig.azulOscuro)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _codigoController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(hintText: 'Ej: PSJ-8A4B2C9D', prefixIcon: Icon(Icons.key)),
                      onSubmitted: (_) => _consultar(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _consultando ? null : _consultar,
                        child: _consultando
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('CONSULTAR'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_buscado && !_consultando && _denunciaEncontrada != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildResultadoCard(),
              ),
              
            if (_buscado && !_consultando && _denunciaEncontrada == null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Card(
                  color: AppConfig.rojo.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 64, color: AppConfig.rojo),
                        const SizedBox(height: 16),
                        Text('No se encontró el reporte', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConfig.rojo)),
                        const SizedBox(height: 8),
                        Text('Verifique que el código sea correcto', style: TextStyle(fontSize: 14, color: AppConfig.grisOscuro)),
                        const SizedBox(height: 8),
                        Text('Códigos válidos para prueba: PSJ-8A4B2C9D, PSJ-123ABC, PSJ-456DEF',
                            style: TextStyle(fontSize: 12, color: AppConfig.azulClaro), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultadoCard() {
    final denuncia = _denunciaEncontrada!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppConfig.verde.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppConfig.verde),
                  const SizedBox(width: 12),
                  const Text('Reporte Encontrado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Detalles del Reporte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppConfig.azulOscuro)),
            const SizedBox(height: 16),
            _buildDetailRow('Código', denuncia['codigo']),
            const SizedBox(height: 12),
            _buildDetailRow('Ubicación', denuncia['ubicacion']),
            const SizedBox(height: 12),
            _buildDetailRow('Categoría', denuncia['categoria']),
            const SizedBox(height: 12),
            _buildDetailRow('Fecha de reporte', denuncia['fecha']),
            const SizedBox(height: 12),
            _buildEstadoRow(denuncia['estado']),
            const SizedBox(height: 12),
            _buildDetailRow('Descripción', denuncia['descripcion']),
            const Divider(height: 32),
            Text('Respuesta Oficial', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConfig.azulOscuro)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppConfig.grisClaro, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18, color: AppConfig.azulClaro),
                      const SizedBox(width: 8),
                      Expanded(child: Text(denuncia['respuesta'], style: const TextStyle(fontStyle: FontStyle.italic))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Última actualización: ${denuncia['actualizacion']}', style: TextStyle(fontSize: 11, color: AppConfig.grisOscuro)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 110, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
  
  Widget _buildEstadoRow(String estado) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 110, child: Text('Estado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(color: _getEstadoColor(estado), borderRadius: BorderRadius.circular(20)),
            child: Text(_getEstadoText(estado), style: TextStyle(color: _getEstadoTextColor(estado), fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ),
      ],
    );
  }
}