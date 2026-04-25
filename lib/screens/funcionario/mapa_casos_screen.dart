import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class MapaCasosScreen extends StatelessWidget {
  const MapaCasosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa de Casos')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: AppConfig.azulClaro),
            const SizedBox(height: 16),
            const Text('Mapa interactivo con los casos geolocalizados', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Próximamente: Integración con Google Maps', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}