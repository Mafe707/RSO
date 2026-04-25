import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class GestionZonasScreen extends StatefulWidget {
  const GestionZonasScreen({super.key});

  @override
  State<GestionZonasScreen> createState() => _GestionZonasScreenState();
}

class _GestionZonasScreenState extends State<GestionZonasScreen> {
  final List<Map<String, dynamic>> _zonas = [
    {'id': '1', 'nombre': 'Centro Histórico', 'codigo': 'Z-CH-001', 'sector': 'Centro', 'activo': true},
    {'id': '2', 'nombre': 'La Enerría', 'codigo': 'Z-N-002', 'sector': 'Norte', 'activo': true},
    {'id': '3', 'nombre': 'El Ejido', 'codigo': 'Z-S-003', 'sector': 'Sur', 'activo': false},
    {'id': '4', 'nombre': 'San Felipe', 'codigo': 'Z-E-004', 'sector': 'Este', 'activo': true},
  ];
  
  void _toggleActivo(int index) {
    setState(() {
      _zonas[index]['activo'] = !_zonas[index]['activo'];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Zonas'), automaticallyImplyLeading: false, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () {}, tooltip: 'Nueva zona'),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _zonas.length,
        itemBuilder: (context, index) {
          final zona = _zonas[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: zona['activo'] ? AppConfig.verde : AppConfig.grisOscuro,
                child: Icon(Icons.map, color: Colors.white),
              ),
              title: Text(zona['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${zona['codigo']} - Sector ${zona['sector']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: zona['activo'] ? AppConfig.verde.withOpacity(0.2) : AppConfig.rojo.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(zona['activo'] ? 'Activo' : 'Inactivo', style: TextStyle(fontSize: 11, color: zona['activo'] ? AppConfig.verde : AppConfig.rojo)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(zona['activo'] ? Icons.visibility : Icons.visibility_off, size: 20),
                    onPressed: () => _toggleActivo(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}