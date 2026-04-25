import 'package:flutter/material.dart';
import '../../config/app_config.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  bool _notificacionesEmail = true;
  bool _notificacionesPush = false;
  String _temaSeleccionado = 'claro';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración'), automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notificaciones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Notificaciones por email'),
                    value: _notificacionesEmail,
                    onChanged: (value) => setState(() => _notificacionesEmail = value),
                    activeColor: AppConfig.azulClaro,
                  ),
                  SwitchListTile(
                    title: const Text('Notificaciones push'),
                    value: _notificacionesPush,
                    onChanged: (value) => setState(() => _notificacionesPush = value),
                    activeColor: AppConfig.azulClaro,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Apariencia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Tema claro'),
                    leading: Radio<String>(
                      value: 'claro',
                      groupValue: _temaSeleccionado,
                      onChanged: (value) => setState(() => _temaSeleccionado = value!),
                      activeColor: AppConfig.azulClaro,
                    ),
                  ),
                  ListTile(
                    title: const Text('Tema oscuro'),
                    leading: Radio<String>(
                      value: 'oscuro',
                      groupValue: _temaSeleccionado,
                      onChanged: (value) => setState(() => _temaSeleccionado = value!),
                      activeColor: AppConfig.azulClaro,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Seguridad', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Cambiar contraseña'),
                    leading: const Icon(Icons.lock),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    title: const Text('Respaldar datos'),
                    leading: const Icon(Icons.backup),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: AppConfig.rojo.withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Zona peligrosa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConfig.rojo)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(foregroundColor: AppConfig.rojo, side: const BorderSide(color: AppConfig.rojo)),
                      child: const Text('ELIMINAR TODOS LOS DATOS'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}