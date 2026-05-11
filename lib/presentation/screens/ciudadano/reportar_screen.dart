import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../config/app_config.dart';
import '../../../services/ciudadano_auth_service.dart';
import '../../../services/denuncia_service.dart';
import 'ciudadano_bottom_nav.dart';
import 'ciudadano_drawer.dart';
import 'ciudadano_home_screen.dart';
import 'ciudadano_login_screen.dart';

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
  final List<Uint8List> _imagenesBytes = [];

  static const int _maxImagenes = 5;
  static const int _maxSizeBytes = 5 * 1024 * 1024;

  bool _enviando = false;
  bool _reporteEnviado = false;
  String _codigoGenerado = '';

  LatLng? _ubicacionMapa;
  bool _esAnonima = true;
  bool _consultandoDireccion = false;

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

  Future<String> _obtenerDireccionDesdeNominatim(LatLng latlng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2'
        '&lat=${latlng.latitude}'
        '&lon=${latlng.longitude}'
        '&zoom=18'
        '&addressdetails=1'
        '&accept-language=es',
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'com.rso.app/1.0 (ciudadano-reportes)',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return _fallbackDireccion(latlng);
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = (data['address'] as Map<String, dynamic>?) ?? {};

      final barrio = _firstNotEmpty([
        address['neighbourhood'],
        address['suburb'],
        address['quarter'],
        address['city_district'],
        address['residential'],
      ]);

      final via = _firstNotEmpty([
        address['road'],
        address['pedestrian'],
        address['footway'],
        address['path'],
        address['cycleway'],
      ]);

      final numero = _firstNotEmpty([
        address['house_number'],
      ]);

      final ciudad = _firstNotEmpty([
        address['city'],
        address['town'],
        address['municipality'],
        address['county'],
      ]);

      final estado = _firstNotEmpty([
        address['state'],
        address['region'],
      ]);

      final partes = <String>[];

      if (via != null && numero != null) {
        partes.add('$via $numero');
      } else if (via != null) {
        partes.add(via);
      }

      if (barrio != null) {
        partes.add(barrio);
      }

      if (ciudad != null) {
        partes.add(ciudad);
      }

      if (estado != null) {
        partes.add(estado);
      }

      if (partes.isNotEmpty) {
        return partes.join(', ');
      }

      final displayName = data['display_name']?.toString().trim();
      if (displayName != null && displayName.isNotEmpty) {
        return displayName;
      }

      return _fallbackDireccion(latlng);
    } catch (_) {
      return _fallbackDireccion(latlng);
    }
  }

  String? _firstNotEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  String _fallbackDireccion(LatLng latlng) {
    return 'Ubicación marcada en mapa (${latlng.latitude.toStringAsFixed(6)}, '
        '${latlng.longitude.toStringAsFixed(6)})';
  }

  Future<void> _tomarFoto() async {
    if (_imagenesBytes.length >= _maxImagenes) {
      _showError('Máximo $_maxImagenes imágenes por reporte');
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxSizeBytes) {
        _showError('La imagen no puede superar los 5MB');
        return;
      }
      setState(() => _imagenesBytes.add(bytes));
    } catch (e) {
      _showError('Error al tomar foto: ${e.toString()}');
    }
  }

  Future<void> _seleccionarDeGaleria() async {
    if (_imagenesBytes.length >= _maxImagenes) {
      _showError('Máximo $_maxImagenes imágenes por reporte');
      return;
    }
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > _maxSizeBytes) {
        _showError('La imagen no puede superar los 5MB');
        return;
      }
      setState(() => _imagenesBytes.add(bytes));
    } catch (e) {
      _showError('Error al seleccionar imagen: ${e.toString()}');
    }
  }

  void _eliminarImagen(int index) {
    setState(() => _imagenesBytes.removeAt(index));
  }

  void _mostrarOpcionesImagen() {
    if (_imagenesBytes.length >= _maxImagenes) {
      _showError('Máximo $_maxImagenes imágenes por reporte');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              Row(
                children: [
                  const Icon(Icons.add_photo_alternate_rounded,
                      color: AppConfig.azulOscuro),
                  const SizedBox(width: 10),
                  Text(
                    'Agregar evidencia (${_imagenesBytes.length}/$_maxImagenes)',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppConfig.azulOscuro,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!kIsWeb)
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: const Color(0xFFF8FAFC),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConfig.azulOscuro.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.camera_alt_rounded,
                        color: AppConfig.azulOscuro),
                  ),
                  title: const Text(
                    'Tomar foto ahora',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Captura inmediata con la cámara'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _tomarFoto();
                  },
                ),
              if (!kIsWeb) const SizedBox(height: 10),
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
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppConfig.azulClaro),
                ),
                title: const Text(
                  'Seleccionar desde galería',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('JPG o PNG, máximo 5MB por imagen'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarDeGaleria();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirSelectorMapa() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MapPickerSheet(
        initialLocation: _ubicacionMapa ?? const LatLng(1.2136, -77.2811),
        onLocationSelected: (latlng) async {
          setState(() {
            _ubicacionMapa = latlng;
            _consultandoDireccion = true;
          });

          final direccion = await _obtenerDireccionDesdeNominatim(latlng);

          if (!mounted) return;

          setState(() {
            _ubicacionController.text = direccion;
            _consultandoDireccion = false;
          });
        },
      ),
    );
  }

  bool _validarUbicacion() {
    final textoVacio = _ubicacionController.text.trim().isEmpty;
    final sinMapa = _ubicacionMapa == null;
    return !(textoVacio && sinMapa);
  }

  Future<void> _enviarReporte() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      _showError('Seleccione un tipo de invasión');
      return;
    }
    if (!_validarUbicacion()) {
      _showError(
          'Indique la ubicación: escríbala en texto o márcala en el mapa');
      return;
    }

    setState(() => _enviando = true);

    try {
      final denunciaService =
          Provider.of<DenunciaService>(context, listen: false);
      final ciudadanoSvc =
          Provider.of<CiudadanoAuthService>(context, listen: false);
      final ciudadano = ciudadanoSvc.ciudadanoData;

      double? lat = _ubicacionMapa?.latitude;
      double? lng = _ubicacionMapa?.longitude;

      final ubicacionTexto = _ubicacionController.text.trim().isNotEmpty
          ? _ubicacionController.text.trim()
          : 'Marcado en mapa: ${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}';

      final resultado = await denunciaService.crearDenuncia(
        ubicacion: ubicacionTexto,
        latitud: lat,
        longitud: lng,
        categoria: _categoriaSeleccionada!,
        descripcion: _descripcionController.text.trim(),
        imagenesBytes: _imagenesBytes.isEmpty ? null : _imagenesBytes,
        esAnonima: _esAnonima,
        ciudadanoNombre: _esAnonima
            ? null
            : '${ciudadano?['nombre']} ${ciudadano?['apellido']}',
        ciudadanoApellido: _esAnonima ? null : ciudadano?['apellido'],
        ciudadanoCorreo: _esAnonima ? null : ciudadano?['correo'],
        ciudadanoTelefono: _esAnonima ? null : ciudadano?['telefono'],
        ciudadanoId: _esAnonima ? null : ciudadano?['id'],
      );

      if (!mounted) return;

      if (resultado != null) {
        setState(() {
          _enviando = false;
          _reporteEnviado = true;
          _codigoGenerado = resultado['codigo_unico']?.toString() ?? '';
        });
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

  void _volverAlHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const CiudadanoHomeScreen()),
      (route) => false,
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppConfig.rojo),
    );
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _categoriaSeleccionada = null;
      _imagenesBytes.clear();
      _descripcionController.clear();
      _ubicacionController.clear();
      _reporteEnviado = false;
      _codigoGenerado = '';
      _ubicacionMapa = null;
      _esAnonima = true;
      _consultandoDireccion = false;
    });
  }

  void _copiarCodigo() {
    Clipboard.setData(ClipboardData(text: _codigoGenerado));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado al portapapeles'),
        backgroundColor: AppConfig.verde,
      ),
    );
  }

  bool _isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 780;

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Reportar Invasión'),
        backgroundColor: AppConfig.azulOscuro,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              final svc = Provider.of<CiudadanoAuthService>(context, listen: false);
              await svc.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const CiudadanoLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: CiudadanoDrawer.maybe(context, currentIndex: 1),
      bottomNavigationBar: CiudadanoBottomNav.maybe(context, currentIndex: 1),
      body: _reporteEnviado
          ? _buildSuccessView(isMobile)
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 32),
                  child: isMobile
                      ? _buildMobileLayout(isMobile)
                      : _buildWebLayout(),
                ),
              ),
            ),
    );
  }

  Widget _buildMobileLayout(bool isMobile) {
    return Column(
      children: [
        _buildHeroBanner(isMobile: true),
        const SizedBox(height: 18),
        _buildFormCard(),
      ],
    );
  }

  Widget _buildWebLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildHeroBanner(isMobile: false),
              const SizedBox(height: 20),
              _buildTipsCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Expanded(flex: 6, child: _buildFormCard()),
      ],
    );
  }

  Widget _buildHeroBanner({required bool isMobile}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 22 : 28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConfig.azulOscuro,
            Color.fromARGB(255, 12, 47, 82),
            Color.fromARGB(255, 13, 70, 98),
          ],
          stops: [0.0, 0.68, 1.0],
        ),
        borderRadius: BorderRadius.circular(isMobile ? 22 : 28),
        boxShadow: [
          BoxShadow(
            color: AppConfig.azulOscuro.withOpacity(0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -6,
            bottom: 6,
            child: Icon(
              Icons.add_location_alt_rounded,
              size: isMobile ? 86 : 112,
              color: Colors.white.withOpacity(0.07),
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
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.report_rounded, size: 15, color: Colors.white),
                    SizedBox(width: 7),
                    Text(
                      'Nueva denuncia',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: isMobile ? 14 : 18),
              Text(
                'Reportar invasión',
                style: TextStyle(
                  fontSize: isMobile ? 26 : 34,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Completa el formulario con la información del lugar afectado.',
                style: TextStyle(
                  fontSize: isMobile ? 13.5 : 15,
                  height: 1.45,
                  color: Colors.white.withOpacity(0.84),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: const [
                  _HeroChip(
                    icon: Icons.location_on_rounded,
                    text: 'Ubicación obligatoria',
                  ),
                  _HeroChip(
                    icon: Icons.photo_camera_rounded,
                    text: 'Foto opcional',
                  ),
                  _HeroChip(
                    icon: Icons.visibility_off_rounded,
                    text: 'Puede ser anónima',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return _SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _PanelHeading(
            icon: Icons.lightbulb_outline_rounded,
            title: 'Consejos',
            subtitle: 'Para un reporte más efectivo.',
          ),
          SizedBox(height: 16),
          _TipItem(
            icon: Icons.location_on_rounded,
            text: 'Indica la dirección exacta o márcala en el mapa.',
          ),
          _TipItem(
            icon: Icons.photo_rounded,
            text: 'Las fotos ayudan a verificar la invasión más rápido.',
          ),
          _TipItem(
            icon: Icons.description_rounded,
            text: 'Describe claramente el tipo de invasión observada.',
            isLast: true,
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
            const SizedBox(height: 24),
            const _PanelHeading(
              icon: Icons.category_rounded,
              title: 'Tipo de invasión',
              subtitle: 'Selecciona la categoría del reporte.',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _categoriaSeleccionada,
              decoration: InputDecoration(
                hintText: 'Elige una categoría',
                prefixIcon: const Icon(Icons.list_rounded),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: _categorias
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoriaSeleccionada = v),
              validator: (v) =>
                  v == null ? 'Seleccione una categoría' : null,
            ),
            const SizedBox(height: 22),
            const _PanelHeading(
              icon: Icons.location_on_rounded,
              title: 'Ubicación *',
              subtitle: 'Escribe la dirección o márcala en el mapa interactivo.',
            ),
            const SizedBox(height: 14),
            if (_ubicacionMapa != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppConfig.azulClaro.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppConfig.azulClaro.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_rounded,
                        color: AppConfig.azulClaro, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _consultandoDireccion
                            ? 'Consultando dirección del punto marcado...'
                            : 'Marcado en mapa:\n${_ubicacionMapa!.latitude.toStringAsFixed(5)}, ${_ubicacionMapa!.longitude.toStringAsFixed(5)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppConfig.azulClaro,
                          height: 1.3,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _ubicacionMapa = null;
                        _ubicacionController.clear();
                        _consultandoDireccion = false;
                      }),
                      child: const Text(
                        'Quitar',
                        style: TextStyle(color: AppConfig.rojo),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _ubicacionController,
              decoration: InputDecoration(
                labelText: 'Dirección en texto',
                hintText: 'Ej: Cra 25 #18-35, Barrio X, Pasto',
                prefixIcon: const Icon(Icons.edit_location_alt_rounded),
                suffixIcon: _consultandoDireccion
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _abrirSelectorMapa,
                icon: const Icon(Icons.map_rounded),
                label: Text(
                  _ubicacionMapa == null
                      ? 'Marcar en el mapa'
                      : 'Cambiar ubicación en mapa',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: AppConfig.azulClaro),
                  foregroundColor: AppConfig.azulClaro,
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _PanelHeading(
              icon: Icons.description_rounded,
              title: 'Descripción *',
              subtitle: 'Explica qué está ocurriendo.',
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descripcionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Describe el tipo de invasión, qué ocupa el espacio y cómo afecta el paso peatonal...',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Mínimo 10 caracteres'
                  : null,
            ),
            const SizedBox(height: 22),
            const _PanelHeading(
              icon: Icons.photo_library_rounded,
              title: 'Evidencia fotográfica',
              subtitle: 'Opcional. Máximo 5 fotos, 5MB cada una.',
            ),
            const SizedBox(height: 14),
            if (_imagenesBytes.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagenesBytes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _imagenesBytes[i],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _eliminarImagen(i),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_imagenesBytes.isNotEmpty) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _mostrarOpcionesImagen,
                icon: const Icon(Icons.add_photo_alternate_rounded),
                label: Text(
                  '${_imagenesBytes.isEmpty ? 'Agregar' : 'Agregar más'} fotos (${_imagenesBytes.length}/$_maxImagenes)',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const _PanelHeading(
              icon: Icons.privacy_tip_rounded,
              title: 'Privacidad del reporte',
              subtitle: 'Elige si deseas identificarte o ser anónimo.',
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppConfig.grisMedio),
              ),
              child: Column(
                children: [
                  RadioListTile<bool>(
                    value: true,
                    groupValue: _esAnonima,
                    onChanged: (v) => setState(() => _esAnonima = v!),
                    title: const Text(
                      'Reporte anónimo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'No se guardarán tus datos en la denuncia',
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConfig.azulOscuro.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.visibility_off_rounded,
                        color: AppConfig.azulOscuro,
                        size: 22,
                      ),
                    ),
                    activeColor: AppConfig.azulOscuro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<bool>(
                    value: false,
                    groupValue: _esAnonima,
                    onChanged: (v) => setState(() => _esAnonima = v!),
                    title: const Text(
                      'Compartir mis datos',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Tu nombre y contacto se adjuntarán a la denuncia',
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppConfig.azulClaro.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppConfig.azulClaro,
                        size: 22,
                      ),
                    ),
                    activeColor: AppConfig.azulClaro,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
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
                label: Text(_enviando ? 'Enviando...' : 'Enviar reporte'),
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

  Widget _buildSuccessView(bool isMobile) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 40),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(28),
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
              const SizedBox(height: 24),
              const Text(
                '¡Reporte enviado!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppConfig.azulOscuro,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tu denuncia fue registrada exitosamente. Guarda el código de seguimiento — es la única forma de consultar el estado de tu reporte.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppConfig.grisOscuro,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppConfig.azulOscuro, AppConfig.azulClaro],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Código de seguimiento',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _codigoGenerado,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _copiarCodigo,
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copiar código'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppConfig.azulOscuro,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle:
                            const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConfig.naranja.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AppConfig.naranja.withOpacity(0.3)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppConfig.naranja,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '⚠️ Guarda este código OBLIGATORIAMENTE. Sin él no podrás consultar ni hacer seguimiento a tu denuncia. No se puede recuperar.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppConfig.naranja,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
                            onPressed: _volverAlHome,
                            icon: const Icon(Icons.home_rounded),
                            label: const Text('Ir al inicio'),
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
                            onPressed: _volverAlHome,
                            icon: const Icon(Icons.home_rounded),
                            label: const Text('Ir al inicio'),
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
    );
  }
}

class _MapPickerSheet extends StatefulWidget {
  final LatLng initialLocation;
  final void Function(LatLng) onLocationSelected;

  const _MapPickerSheet({
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  LatLng? _selected;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height * 0.80;

    return Container(
      height: h,
      margin: const EdgeInsets.only(top: 60),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppConfig.grisMedio,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.map_rounded, color: AppConfig.azulOscuro),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Marca el punto exacto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppConfig.azulOscuro,
                        ),
                      ),
                      Text(
                        'Toca el mapa para fijar la ubicación',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: widget.initialLocation,
                initialZoom: 15,
                onTap: (tapPos, latlng) {
                  setState(() => _selected = latlng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.rso.app',
                ),
                if (_selected != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _selected!,
                        width: 48,
                        height: 48,
                        child: const Icon(
                          Icons.location_pin,
                          color: AppConfig.rojo,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _selected == null
                    ? null
                    : () {
                        widget.onLocationSelected(_selected!);
                        Navigator.pop(context);
                      },
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  _selected == null
                      ? 'Toca el mapa para seleccionar'
                      : 'Confirmar ubicación',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConfig.azulOscuro,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
        ],
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
          child: const Icon(Icons.assignment_rounded,
              color: AppConfig.azulOscuro),
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
                'La ubicación, tipo y descripción son obligatorios.',
                style: TextStyle(fontSize: 13, color: AppConfig.grisOscuro),
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
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
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