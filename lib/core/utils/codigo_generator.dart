import 'dart:math';

class CodigoGenerator {
  static const String _prefijo = 'PSJ';
  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static const int _longitud = 8;

  /// Genera un código tipo: PSJ-A3K9XZ12
  static String generar() {
    final random = Random.secure();
    final codigo = List.generate(
      _longitud,
      (_) => _chars[random.nextInt(_chars.length)],
    ).join();
    return '$_prefijo-$codigo';
  }
}