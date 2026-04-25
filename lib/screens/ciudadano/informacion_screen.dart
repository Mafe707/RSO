import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class InformacionScreen extends StatelessWidget {
  const InformacionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Información')),
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
                    Text('¿Qué se considera invasión al espacio público?',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.azulOscuro)),
                    const SizedBox(height: 8),
                    const Text('El espacio público es de todos y debe mantenerse libre de obstáculos que impidan su uso y disfrute por parte de la comunidad.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Tipos de invasión al espacio público',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.azulOscuro)),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildTypeItem('Ocupación comercial', 'Establecimientos que expanden sus áreas hacia aceras y vías públicas.'),
                    const Divider(),
                    _buildTypeItem('Invasiones vehiculares', 'Vehículos estacionados en aceras, parques o espacios peatonales.'),
                    const Divider(),
                    _buildTypeItem('Venta informal', 'Puestos de venta no autorizados en espacio público.'),
                    const Divider(),
                    _buildTypeItem('Publicidad no autorizada', 'Vallas, avisos o propaganda en espacios no permitidos.'),
                    const Divider(),
                    _buildTypeItem('Obstrucciones varias', 'Materiales de construcción, mobiliario u otros objetos que obstruyan el paso.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Beneficios de reportar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.azulOscuro)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildBenefitCard(Icons.location_city, 'Mejora tu ciudad', 'Contribuye a mantener los espacios públicos libres')), // CAMBIADO: Icons.city → Icons.location_city
                const SizedBox(width: 12),
                Expanded(child: _buildBenefitCard(Icons.shield, 'Reporte seguro', 'Sistema anónimo que protege tu identidad')),
                const SizedBox(width: 12),
                Expanded(child: _buildBenefitCard(Icons.check_circle, 'Seguimiento', 'Cada reporte es gestionado')),
              ],
            ),
            const SizedBox(height: 16),
            Text('Preguntas frecuentes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.azulOscuro)),
            const SizedBox(height: 12),
            _buildFaqCard('¿Mi reporte es anónimo?', 'Sí, todos los reportes son completamente anónimos. El sistema no solicita ni almacena información personal.'),
            const SizedBox(height: 12),
            _buildFaqCard('¿Qué pasa después de hacer un reporte?', 'Tu reporte es enviado a las autoridades competentes para su verificación y gestión. Puedes seguir su estado con tu código de seguimiento.'),
            const SizedBox(height: 12),
            _buildFaqCard('¿En qué plazo se gestiona un reporte?', 'El tiempo de gestión depende de la complejidad del caso, pero generalmente se inicia el proceso en un plazo máximo de 72 horas.'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTypeItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 14, color: AppConfig.grisOscuro)),
        ],
      ),
    );
  }
  
  Widget _buildBenefitCard(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConfig.grisClaro,
        borderRadius: BorderRadius.circular(12),
        border: Border(top: BorderSide(color: AppConfig.azulOscuro, width: 4)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: AppConfig.azulOscuro),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 11, color: AppConfig.grisOscuro), textAlign: TextAlign.center),
        ],
      ),
    );
  }
  
  Widget _buildFaqCard(String question, String answer) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(answer, style: TextStyle(fontSize: 14, color: AppConfig.grisOscuro)),
          ],
        ),
      ),
    );
  }
}