import 'dart:typed_data';
import '../../entities/denuncia.dart';
import '../../repositories/denuncia_repository.dart';

class CrearDenuncia {
  final DenunciaRepository repository;

  CrearDenuncia(this.repository);

  Future<Denuncia?> call({
    required String ubicacion,
    double? latitud,
    double? longitud,
    required String categoria,
    required String descripcion,
    List<Uint8List>? imagenesBytes,
  }) {
    return repository.crearDenuncia(
      ubicacion: ubicacion,
      latitud: latitud,
      longitud: longitud,
      categoria: categoria,
      descripcion: descripcion,
      imagenesBytes: imagenesBytes,
    );
  }
}