import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class CasosAsignadosScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const CasosAsignadosScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Casos Asignados')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in, size: 80, color: AppConfig.azulClaro),
            const SizedBox(height: 16),
            const Text('Lista de casos asignados por el administrador', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Funcionalidad en desarrollo', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}