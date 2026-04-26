import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/denuncia_service.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';

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
  Uint8List? _imagenBytes;

  bool _enviando = false;
  bool _reporteEnviado = false;

  String _codigoGenerado = '';

  final List<String> _categorias = [
    'Ocupación comercial',
    'Invasión vehicular',
    'Venta informal',
    'Publicidad no autorizada',
    'Otro',
  ];

  @override
  void dispose() {
    _ubicacionController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      const maxSizeInBytes = 5 * 1024 * 1024;

      if (bytes.length > maxSizeInBytes) {
        _showError('La imagen no puede superar los 5MB');
        return;
      }

      setState(() {
        _imagenBytes = bytes;
      });
    } catch (e) {
      _showError('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
              bottom: Radius.circular(18),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppConfig.grisMedio,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const Row(
                  children: [
                    Icon(
                      Icons.add_photo_alternate_rounded,
                      color: AppConfig.azulOscuro,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Agregar evidencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConfig.azulOscuro,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: const Color(0xFFF8FAFC),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConfig.azulClaro.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppConfig.azulClaro,
                    ),
                  ),
                  title: const Text(
                    'Seleccionar desde galería',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('JPG o PNG, máximo 5MB'),
                  onTap: () {
                    Navigator.pop(context);
                    _seleccionarImagen();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _enviarReporte() async {
    if (!_formKey.currentState!.validate()) return;

    if (_categoriaSeleccionada == null) {
      _showError('Seleccione una categoría');
      return;
    }

    if (_imagenBytes == null) {
      _showError('Seleccione una imagen de evidencia');
      return;
    }

    setState(() => _enviando = true);

    try {
      final denunciaService = Provider.of<DenunciaService>(
        context,
        listen: false,
      );

      final resultado = await denunciaService.crearDenuncia(
        ubicacion: _ubicacionController.text.trim(),
        latitud: null,
        longitud: null,
        categoria: _categoriaSeleccionada!,
        descripcion: _descripcionController.text.trim(),
        imagenBytes: _imagenBytes!,
      );

      if (!mounted) return;

      if (resultado != null) {
        setState(() {
          _enviando = false;
          _reporteEnviado = true;
          _codigoGenerado = resultado['codigo_unico']?.toString() ?? '';
        });

        _showSuccess('¡Reporte enviado con éxito!');
      } else {
        setState(() => _enviando = false);
        _showError('No se pudo enviar el reporte');
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _enviando = false);
      _showError('Error al enviar: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppConfig.rojo,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

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
      _imagenBytes = null;
      _descripcionController.clear();
      _ubicacionController.clear();
      _reporteEnviado = false;
      _codigoGenerado = '';
    });
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 780;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Reportar Invasión'),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
      ),
      drawer: CiudadanoDrawer.maybe(
        context,
        currentIndex: 1,
      ),
      bottomNavigationBar: CiudadanoBottomNav.maybe(
        context,
        currentIndex: 1,
      ),
      body: _reporteEnviado ? _buildSuccessScreen() : _buildFormScreen(),
    );
  }

  Widget _buildFormScreen() {
    final isMobile = _isMobile(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: isMobile ? _buildMobileForm() : _buildWebForm(),
        ),
      ),
    );
  }

  Widget _buildMobileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHero(isMobile: true),
        const SizedBox(height: 18),
        _buildFormCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildWebForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHero(isMobile: false),
              const SizedBox(height: 22),
              _buildTipsPanel(),
            ],
          ),
        ),
        const SizedBox(width: 26),
        Expanded(
          flex: 6,
          child: _buildFormCard(),
        ),
      ],
    );
  }

  Widget _buildHero({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 24 : 30),
        boxShadow: [
          BoxShadow(
            color: AppConfig.azulOscuro.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -14,
            bottom: -20,
            child: Icon(
              Icons.report_problem_rounded,
              size: isMobile ? 105 : 145,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 7),
                    Text(
                      'Reporte ciudadano',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Reporta una invasión al espacio público',
                style: TextStyle(
                  fontSize: isMobile ? 27 : 38,
                  height: 1.08,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Completa la información del lugar, describe la situación y adjunta una evidencia fotográfica clara.',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroChip(
                    icon: Icons.lock_outline_rounded,
                    text: 'Reporte seguro',
                  ),
                  _HeroChip(
                    icon: Icons.photo_camera_rounded,
                    text: 'Evidencia requerida',
                  ),
                  _HeroChip(
                    icon: Icons.confirmation_number_rounded,
                    text: 'Código de seguimiento',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return _SoftCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FormHeader(),
            const SizedBox(height: 22),
            _buildSectionLabel(
              icon: Icons.location_on_rounded,
              title: 'Ubicación',
              subtitle: 'Escribe la dirección o una referencia clara del lugar.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ubicacionController,
              decoration: InputDecoration(
                hintText: 'Ej: Calle 17 #20-69, Barrio Centro',
                prefixIcon: const Icon(Icons.location_searching_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                helperText:
                    'No se completa automáticamente. Escribe la ubicación real del caso.',
                helperMaxLines: 2,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La ubicación es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildSectionLabel(
              icon: Icons.category_rounded,
              title: 'Categoría',
              subtitle: 'Selecciona el tipo de invasión que deseas reportar.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoriaSeleccionada,
              hint: const Text('Seleccione una categoría'),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.list_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: _categorias.map((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria,
                  child: Text(categoria),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _categoriaSeleccionada = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Seleccione una categoría';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildSectionLabel(
              icon: Icons.description_rounded,
              title: 'Descripción',
              subtitle: 'Explica brevemente qué está ocurriendo.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descripcionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describa detalladamente la situación...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La descripción es requerida';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildSectionLabel(
              icon: Icons.image_rounded,
              title: 'Evidencia fotográfica',
              subtitle: 'Sube una foto clara del problema. Máximo 5MB.',
            ),
            const SizedBox(height: 12),
            _buildImagePicker(),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _enviarReporte,
                icon: _enviando
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label:
                    Text(_enviando ? 'Enviando reporte...' : 'Enviar reporte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.azulOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppConfig.azulOscuro.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: AppConfig.azulOscuro,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _mostrarOpcionesImagen,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: _imagenBytes != null ? 260 : 210,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: _imagenBytes != null
                ? AppConfig.azulClaro.withOpacity(0.45)
                : AppConfig.grisMedio,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFFF8FAFC),
        ),
        child: _imagenBytes != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.memory(
                      _imagenBytes!,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 14,
                    top: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.54),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Imagen cargada',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() => _imagenBytes = null);
                        },
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppConfig.azulClaro.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_rounded,
                      size: 38,
                      color: AppConfig.azulClaro,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tocar para subir imagen',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppConfig.azulOscuro,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'JPG o PNG · máximo 5MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConfig.grisOscuro,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTipsPanel() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeading(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Consejos para un buen reporte',
            subtitle: 'Estos detalles ayudan a gestionar mejor la denuncia.',
          ),
          const SizedBox(height: 18),
          _TipItem(
            icon: Icons.location_on_outlined,
            text:
                'Escribe una ubicación clara: calle, carrera, barrio o punto de referencia.',
          ),
          _TipItem(
            icon: Icons.photo_camera_outlined,
            text: 'Adjunta una foto donde se vea claramente la invasión.',
          ),
          _TipItem(
            icon: Icons.description_outlined,
            text:
                'Describe qué obstaculiza el espacio público y desde cuándo ocurre.',
          ),
          _TipItem(
            icon: Icons.confirmation_number_outlined,
            text:
                'Guarda el código generado para consultar el estado del reporte.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final isMobile = _isMobile(context);

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 24 : 34),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppConfig.grisMedio),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppConfig.verde.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 72,
                    color: AppConfig.verde,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  '¡Reporte enviado con éxito!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppConfig.azulOscuro,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Tu reporte ha sido registrado correctamente. Guarda este código para consultar el estado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppConfig.grisOscuro,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: SelectableText(
                    _codigoGenerado,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'monospace',
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                isMobile
                    ? Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _resetForm,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Nuevo reporte'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.azulOscuro,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Volver'),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _resetForm,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Nuevo reporte'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConfig.azulOscuro,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Volver'),
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
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

class _FormHeader extends StatelessWidget {
  const _FormHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 50,
          width: 50,
          decoration: BoxDecoration(
            color: AppConfig.azulOscuro.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.assignment_rounded,
            color: AppConfig.azulOscuro,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos del reporte',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Todos los campos son obligatorios.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;

  const _SoftCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppConfig.grisMedio),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PanelHeading extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PanelHeading({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            color: AppConfig.azulOscuro.withOpacity(0.08),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: AppConfig.azulOscuro),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TipItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLast;

  const _TipItem({
    required this.icon,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppConfig.azulClaro, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppConfig.grisOscuro,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 22),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 11.5,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}