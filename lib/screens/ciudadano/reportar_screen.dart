import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_config.dart';
import '../../services/denuncia_service.dart';

class ReportarScreen extends StatefulWidget {
  const ReportarScreen({super.key});

  @override
  State<ReportarScreen> createState() => _ReportarScreenState();
}

class _ReportarScreenState extends State<ReportarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ubicacionController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  String? _categoriaSeleccionada;
  File? _imagenSeleccionada;
  bool _enviando = false;
  bool _reporteEnviado = false;
  String _codigoGenerado = '';
  String? _errorMessage;
  
  final List<String> _categorias = [
    'Ocupación comercial',
    'Invasión vehicular',
    'Venta informal',
    'Publicidad no autorizada',
    'Otro',
  ];
  
  final DenunciaService _denunciaService = DenunciaService();
  
  @override
  void dispose() {
    _ubicacionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }
  
  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (pickedFile != null && mounted) {
      setState(() {
        _imagenSeleccionada = File(pickedFile.path);
        _errorMessage = null;
      });
    }
  }
  
  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () {
                Navigator.pop(context);
                _seleccionarImagen();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () {
                Navigator.pop(context);
                // Por ahora solo galería
                _seleccionarImagen();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _enviarReporte() async {
    // Validar formulario
    if (!_formKey.currentState!.validate()) return;
    
    if (_categoriaSeleccionada == null) {
      _showError('Seleccione una categoría');
      return;
    }
    
    if (_imagenSeleccionada == null) {
      _showError('Seleccione una imagen de evidencia');
      return;
    }
    
    setState(() {
      _enviando = true;
      _errorMessage = null;
    });
    
    try {
      final resultado = await _denunciaService.crearDenuncia(
        ubicacion: _ubicacionController.text.trim(),
        categoria: _categoriaSeleccionada!,
        descripcion: _descripcionController.text.trim(),
        imagen: _imagenSeleccionada!,
      );
      
      if (mounted) {
        setState(() {
          _enviando = false;
          _reporteEnviado = true;
          _codigoGenerado = resultado['codigo_unico'];
        });
      }
    } catch (e) {
      setState(() {
        _enviando = false;
        _errorMessage = e.toString();
      });
      _showError(e.toString());
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConfig.rojo,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConfig.verde,
      ),
    );
  }
  
  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _categoriaSeleccionada = null;
      _imagenSeleccionada = null;
      _descripcionController.clear();
      _ubicacionController.clear();
      _reporteEnviado = false;
      _codigoGenerado = '';
      _errorMessage = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportar Invasión'),
        backgroundColor: AppConfig.azulOscuro,
      ),
      body: _reporteEnviado ? _buildSuccessScreen() : _buildFormScreen(),
    );
  }
  
  Widget _buildFormScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportar Invasión al Espacio Público',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete el siguiente formulario. Todos los campos son obligatorios.',
              style: TextStyle(color: AppConfig.grisOscuro),
            ),
            const SizedBox(height: 24),
            
            // ========== UBICACIÓN ==========
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 8),
                        Text(
                          'Ubicación',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ubicacionController,
                      decoration: const InputDecoration(
                        hintText: 'Ej: Calle 17 #20-69, Barrio Centro',
                        prefixIcon: Icon(Icons.location_searching),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La ubicación es requerida';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ========== CATEGORÍA ==========
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.category),
                        SizedBox(width: 8),
                        Text(
                          'Categoría',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      hint: const Text('Seleccione una categoría'),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.list),
                        border: OutlineInputBorder(),
                      ),
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _categoriaSeleccionada = value),
                      validator: (value) {
                        if (value == null) return 'Seleccione una categoría';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ========== DESCRIPCIÓN ==========
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description),
                        SizedBox(width: 8),
                        Text(
                          'Descripción',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describa detalladamente la situación...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'La descripción es requerida';
                        }
                        if (value.length < 10) {
                          return 'Describa con más detalle (mínimo 10 caracteres)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // ========== EVIDENCIA (IMAGEN) ==========
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.image),
                        SizedBox(width: 8),
                        Text(
                          'Evidencia fotográfica',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Suba una foto clara del problema (máx. 5MB)',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _mostrarOpcionesImagen,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppConfig.grisMedio, width: 2),
                          borderRadius: BorderRadius.circular(12),
                          color: AppConfig.grisClaro,
                        ),
                        child: _imagenSeleccionada != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      _imagenSeleccionada!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 20, color: Colors.white),
                                        onPressed: () {
                                          setState(() => _imagenSeleccionada = null);
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate,
                                    size: 56,
                                    color: AppConfig.grisOscuro,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Tocar para subir imagen',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'JPG, PNG (máx. 5MB)',
                                    style: TextStyle(fontSize: 11, color: AppConfig.grisOscuro),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // ========== BOTÓN ENVIAR ==========
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviarReporte,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.azulOscuro,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('ENVIAR REPORTE', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuccessScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConfig.verde.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check_circle, size: 64, color: AppConfig.verde),
                ),
                const SizedBox(height: 16),
                const Text(
                  '¡Reporte enviado con éxito!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Su reporte ha sido registrado. Guarde el siguiente código:'),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppConfig.azulOscuro,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    _codigoGenerado,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _resetForm,
                        style: ElevatedButton.styleFrom(backgroundColor: AppConfig.azulOscuro),
                        child: const Text('NUEVO REPORTE'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('VOLVER'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}