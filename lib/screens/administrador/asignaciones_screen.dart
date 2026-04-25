import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class AsignacionesScreen extends StatefulWidget {
  const AsignacionesScreen({super.key});

  @override
  State<AsignacionesScreen> createState() => _AsignacionesScreenState();
}

class _AsignacionesScreenState extends State<AsignacionesScreen> {
  final List<Map<String, dynamic>> _asignaciones = [
    {'id': '1', 'reporte': 'PSJ-8A4B2C9D', 'funcionario': 'Carlos Rodríguez', 'fecha': '05/09/2025', 'estado': 'proceso'},
    {'id': '2', 'reporte': 'PSJ-123ABC', 'funcionario': 'No asignado', 'fecha': '-', 'estado': 'pendiente'},
    {'id': '3', 'reporte': 'PSJ-456DEF', 'funcionario': 'María González', 'fecha': '01/09/2025', 'estado': 'completada'},
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignaciones'), automaticallyImplyLeading: false, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () {}, tooltip: 'Nueva asignación'),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _asignaciones.length,
        itemBuilder: (context, index) {
          final asignacion = _asignaciones[index];
          Color estadoColor = asignacion['estado'] == 'proceso' ? AppConfig.azulClaro : 
                              (asignacion['estado'] == 'completada' ? AppConfig.verde : AppConfig.naranja);
          String estadoText = asignacion['estado'] == 'proceso' ? 'En proceso' : 
                              (asignacion['estado'] == 'completada' ? 'Completada' : 'Pendiente');
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: estadoColor.withOpacity(0.2),
                child: Icon(Icons.assignment, color: estadoColor),
              ),
              title: Text(asignacion['reporte'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Funcionario: ${asignacion['funcionario']} • Fecha: ${asignacion['fecha']}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: estadoColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(estadoText, style: TextStyle(fontSize: 11, color: estadoColor)),
              ),
            ),
          );
        },
      ),
    );
  }
}