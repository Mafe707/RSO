import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class GestionUsuariosScreen extends StatefulWidget {
  const GestionUsuariosScreen({super.key});

  @override
  State<GestionUsuariosScreen> createState() => _GestionUsuariosScreenState();
}

class _GestionUsuariosScreenState extends State<GestionUsuariosScreen> {
  final List<Map<String, dynamic>> _usuarios = [
    {'id': '1', 'nombre': 'Carlos Rodríguez', 'email': 'crodriguez@alcaldia.gov.co', 'rol': 'Funcionario', 'activo': true},
    {'id': '2', 'nombre': 'María González', 'email': 'mgonzalez@alcaldia.gov.co', 'rol': 'Funcionario', 'activo': true},
    {'id': '3', 'nombre': 'Javier López', 'email': 'jlopez@alcaldia.gov.co', 'rol': 'Funcionario', 'activo': false},
    {'id': '4', 'nombre': 'Ana Martínez', 'email': 'amartinez@alcaldia.gov.co', 'rol': 'Funcionario', 'activo': true},
  ];
  
  void _toggleActivo(int index) {
    setState(() {
      _usuarios[index]['activo'] = !_usuarios[index]['activo'];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Usuario ${_usuarios[index]['activo'] ? 'activado' : 'desactivado'}'), backgroundColor: AppConfig.verde),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Usuarios'), automaticallyImplyLeading: false, actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: () {}, tooltip: 'Nuevo usuario'),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _usuarios.length,
        itemBuilder: (context, index) {
          final usuario = _usuarios[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: usuario['activo'] ? AppConfig.verde : AppConfig.grisOscuro,
                child: Text(usuario['nombre'][0], style: const TextStyle(color: Colors.white)),
              ),
              title: Text(usuario['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(usuario['email']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: usuario['activo'] ? AppConfig.verde.withOpacity(0.2) : AppConfig.rojo.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(usuario['activo'] ? 'Activo' : 'Inactivo', style: TextStyle(fontSize: 11, color: usuario['activo'] ? AppConfig.verde : AppConfig.rojo)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(usuario['activo'] ? Icons.lock_open : Icons.lock, size: 20),
                    onPressed: () => _toggleActivo(index),
                    tooltip: usuario['activo'] ? 'Desactivar' : 'Activar',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {},
                    tooltip: 'Editar',
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