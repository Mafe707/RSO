import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class MiPerfilScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const MiPerfilScreen({super.key, required this.userData});

  @override
  State<MiPerfilScreen> createState() => _MiPerfilScreenState();
}

class _MiPerfilScreenState extends State<MiPerfilScreen> {
  late TextEditingController _nombreController;
  late TextEditingController _emailController;
  late TextEditingController _cargoController;
  late TextEditingController _telefonoController;
  
  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.userData['nombre']);
    _emailController = TextEditingController(text: widget.userData['correo']);
    _cargoController = TextEditingController(text: widget.userData['cargo']);
    _telefonoController = TextEditingController(text: '3123456789');
  }
  
  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _cargoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }
  
  void _guardarCambios() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil actualizado correctamente'), backgroundColor: AppConfig.verde),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppConfig.azulClaro,
                    child: Text(
                      widget.userData['nombre'][0],
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cambiar foto'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.azulClaro),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Formulario
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Correo electrónico', prefixIcon: Icon(Icons.email)),
                      enabled: false,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cargoController,
                      decoration: const InputDecoration(labelText: 'Cargo', prefixIcon: Icon(Icons.business)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _guardarCambios,
                        style: ElevatedButton.styleFrom(backgroundColor: AppConfig.verde),
                        child: const Text('GUARDAR CAMBIOS'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Cambiar contraseña
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cambiar contraseña', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Contraseña actual', prefixIcon: Icon(Icons.lock)),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Nueva contraseña', prefixIcon: Icon(Icons.lock_outline)),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña', prefixIcon: Icon(Icons.lock_outline)),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(backgroundColor: AppConfig.azulClaro),
                        child: const Text('ACTUALIZAR CONTRASEÑA'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}