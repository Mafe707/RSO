import 'dart:math';
import '../models/reporte_sintetico_model.dart';

class SyntheticReportsService {
  static const int _seed = 42;

  static const List<_Hotspot> _hotspots = [
    _Hotspot(1.2136, -77.2811, 'Centro Histórico', 0.30),
    _Hotspot(1.2180, -77.2760, 'La Empieza', 0.15),
    _Hotspot(1.2080, -77.2870, 'Lorenzo', 0.12),
    _Hotspot(1.2200, -77.2900, 'Obrero', 0.10),
    _Hotspot(1.2050, -77.2750, 'Mercado Potrerillo', 0.13),
    _Hotspot(1.2250, -77.2800, 'Mijitayo', 0.08),
    _Hotspot(1.2100, -77.2950, 'Jongovito', 0.07),
    _Hotspot(1.2300, -77.2700, 'Villa Flor', 0.05),
  ];

  static const List<String> _categorias = [
    'Venta informal',
    'Invasión vehicular',
    'Ocupación comercial',
    'Publicidad no autorizada',
    'Materiales de construcción',
    'Otro',
  ];

  static const List<String> _estados = [
    'pendiente',
    'en_revision',
    'resuelto_pendiente_validacion',
    'devuelto',
    'resuelto_publicado',
  ];

  static const Map<String, List<double>> _pesosCategoriaZona = {
    'Centro Histórico': [0.35, 0.15, 0.25, 0.15, 0.05, 0.05],
    'La Empieza': [0.40, 0.20, 0.15, 0.10, 0.10, 0.05],
    'Lorenzo': [0.20, 0.30, 0.15, 0.10, 0.15, 0.10],
    'Obrero': [0.25, 0.25, 0.20, 0.10, 0.10, 0.10],
    'Mercado Potrerillo': [0.45, 0.10, 0.20, 0.05, 0.15, 0.05],
    'Mijitayo': [0.15, 0.25, 0.20, 0.15, 0.15, 0.10],
    'Jongovito': [0.20, 0.20, 0.15, 0.10, 0.20, 0.15],
    'Villa Flor': [0.20, 0.15, 0.15, 0.15, 0.20, 0.15],
  };

  static const Map<String, List<String>> _descripcionesPorCategoria = {
    'Venta informal': [
      'Vendedores informales obstruyen el paso peatonal con puestos de comida.',
      'Comerciantes sin permiso ocupan la acera con mercancía.',
      'Venta ambulante bloquea el acceso a locales comerciales.',
      'Puesto de frutas invade zona peatonal frente a banco.',
    ],
    'Invasión vehicular': [
      'Vehículo abandonado obstruyendo la acera hace más de 24 horas.',
      'Moto parqueada en zona peatonal restringida.',
      'Camión de carga descargando mercancía en vía peatonal.',
      'Vehículo particular estacionado sobre el andén.',
    ],
    'Ocupación comercial': [
      'Restaurante ocupa parte de la vía pública con mesas y sillas.',
      'Local comercial instala vitrinas invadiendo el espacio público.',
      'Negocio coloca exhibidores en zona peatonal sin autorización.',
      'Heladería instala sombrillas en andén estrecho.',
    ],
    'Publicidad no autorizada': [
      'Valla publicitaria en espacio público sin permiso de la alcaldía.',
      'Carteles pegados en postes del alumbrado público.',
      'Pendones de propaganda comercial obstruyen visibilidad.',
      'Pintada publicitaria sobre fachada de bien público.',
    ],
    'Materiales de construcción': [
      'Materiales de construcción obstruyendo la vía peatonal.',
      'Escombros sin señalizar bloqueando andén.',
      'Arena y grava depositadas en espacio público sin permiso.',
      'Andamios invaden la acera sin señalización de seguridad.',
    ],
    'Otro': [
      'Invasión del espacio público no categorizada.',
      'Obstáculo no identificado en zona peatonal.',
      'Ocupación irregular de espacio público.',
    ],
  };

  List<ReporteSintetico> generar(int n) {
    final rng = Random(_seed);
    final List<ReporteSintetico> reportes = [];

    final fechaFin = DateTime.now();
    final fechaBase = fechaFin.subtract(const Duration(days: 180));
    const int rangoDias = 180;

    for (int i = 0; i < n; i++) {
      final hs = _seleccionarHotspot(rng);

      final lat = hs.lat + _gaussiana(rng, 0, 0.004);
      final lng = hs.lng + _gaussiana(rng, 0, 0.004);

      final pesos = _pesosCategoriaZona[hs.nombre]!;
      final categoria = _seleccionarCategoria(rng, pesos);

      final diasOffset =
          _triangular(rng, 0, rangoDias * 0.7, rangoDias.toDouble()).toInt();
      final fechaBase2 = fechaBase.add(Duration(days: diasOffset));

      final hora = _seleccionarHora(rng);
      final fecha = DateTime(
        fechaBase2.year,
        fechaBase2.month,
        fechaBase2.day,
        hora,
        rng.nextInt(60),
      );

      final estado = _seleccionarEstado(rng);

      final descs = _descripcionesPorCategoria[categoria]!;
      final desc = descs[rng.nextInt(descs.length)];

      final ubicacion = _generarUbicacion(rng, hs.nombre);

      reportes.add(
        ReporteSintetico.fromSintetico({
          'codigo_unico': 'PSJ-SYN${i.toString().padLeft(5, '0')}',
          'ubicacion': ubicacion,
          'latitud': double.parse(lat.toStringAsFixed(6)),
          'longitud': double.parse(lng.toStringAsFixed(6)),
          'categoria': categoria,
          'descripcion': desc,
          'estado': estado,
          'creado_en': fecha,
        }),
      );
    }

    return reportes;
  }

  _Hotspot _seleccionarHotspot(Random rng) {
    final pesos = _hotspots.map((h) => h.peso).toList();
    final total = pesos.reduce((a, b) => a + b);
    double r = rng.nextDouble() * total;
    for (final hs in _hotspots) {
      r -= hs.peso;
      if (r <= 0) return hs;
    }
    return _hotspots.last;
  }

  String _seleccionarCategoria(Random rng, List<double> pesos) {
    final total = pesos.reduce((a, b) => a + b);
    double r = rng.nextDouble() * total;
    for (int i = 0; i < _categorias.length; i++) {
      r -= pesos[i];
      if (r <= 0) return _categorias[i];
    }
    return _categorias.last;
  }

  String _seleccionarEstado(Random rng) {
    final pesos = [0.30, 0.30, 0.20, 0.10, 0.10];
    double r = rng.nextDouble();
    for (int i = 0; i < _estados.length; i++) {
      r -= pesos[i];
      if (r <= 0) return _estados[i];
    }
    return _estados.first;
  }

  int _seleccionarHora(Random rng) {
    final horas = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20];
    final pesos = [
      0.04, 0.09, 0.09, 0.07, 0.04, 0.09, 0.09, 0.07,
      0.04, 0.04, 0.09, 0.09, 0.07, 0.09
    ];
    double r = rng.nextDouble();
    for (int i = 0; i < horas.length; i++) {
      r -= pesos[i];
      if (r <= 0) return horas[i];
    }
    return 12;
  }

  String _generarUbicacion(Random rng, String zona) {
    final Map<String, List<String>> callesBases = {
      'Centro Histórico': ['Cra 25 #18-', 'Calle 19 #24-', 'Calle 17 #20-', 'Cra 23 #16-'],
      'La Empieza': ['Cra 27 #12-', 'Calle 20 #27-', 'Av. Los Andes #'],
      'Lorenzo': ['Calle 22 #30-', 'Cra 30 #22-', 'Sector Lorenzo #'],
      'Obrero': ['Barrio Obrero Cra #', 'Calle 15 Obrero #', 'Tv. Obrero #'],
      'Mercado Potrerillo': ['Sector Potrerillo #', 'Calle Mercado #', 'Acceso Potrerillo '],
      'Mijitayo': ['Mijitayo Cra #', 'Calle Mijitayo #'],
      'Jongovito': ['Jongovito Sector #', 'Vía Jongovito km '],
      'Villa Flor': ['Villa Flor Cra #', 'Barrio Villa Flor '],
    };
    final base = callesBases[zona] ?? ['Calle #'];
    final calle = base[rng.nextInt(base.length)];
    final numero = 10 + rng.nextInt(90);
    return '$calle$numero, $zona, Pasto';
  }

  double _gaussiana(Random rng, double mean, double std) {
    double u1 = rng.nextDouble();
    double u2 = rng.nextDouble();
    if (u1 == 0) u1 = 0.0001;
    final z = sqrt(-2.0 * log(u1)) * cos(2 * pi * u2);
    return mean + z * std;
  }

  double _triangular(Random rng, double a, double c, double b) {
    final u = rng.nextDouble();
    final fc = (c - a) / (b - a);
    if (u < fc) {
      return a + sqrt(u * (b - a) * (c - a));
    } else {
      return b - sqrt((1 - u) * (b - a) * (b - c));
    }
  }
}

class _Hotspot {
  final double lat;
  final double lng;
  final String nombre;
  final double peso;

  const _Hotspot(this.lat, this.lng, this.nombre, this.peso);
}