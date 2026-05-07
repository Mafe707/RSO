import 'dart:typed_data';
import '../../domain/entities/denuncia.dart';
import '../../domain/repositories/denuncia_repository.dart';
import '../datasources/supabase/denuncia_supabase_ds.dart';

class DenunciaRepositoryImpl implements DenunciaRepository {
  final DenunciaSupabaseDs _ds;

  DenunciaRepositoryImpl(this._ds);

  @override
  Future<Denuncia?> crearDenuncia({
    required String ubicacion,
    double? latitud,
    double? longitud,
    required String categoria,
    required String descripcion,
    List<Uint8List>? imagenesBytes,
  }) {
    return _ds.crearDenuncia(
      ubicacion: ubicacion,
      latitud: latitud,
      longitud: longitud,
      categoria: categoria,
      descripcion: descripcion,
      imagenesBytes: imagenesBytes,
    );
  }

  @override
  Future<Denuncia?> obtenerPorCodigo(String codigo) =>
      _ds.obtenerPorCodigo(codigo);

  @override
  Future<List<Denuncia>> obtenerTodas() => _ds.obtenerTodas();

  @override
  Future<List<Denuncia>> obtenerPorFuncionario(int funcionarioId) async {
    final todas = await _ds.obtenerTodas();
    return todas
        .where((d) => d.funcionarioId == funcionarioId)
        .toList();
  }

  @override
  Future<bool> actualizarEstado(int id, String nuevoEstado) =>
      _ds.actualizarEstado(id, nuevoEstado);

  @override
  Future<bool> asignarFuncionario(int denunciaId, int funcionarioId) =>
      _ds.asignarFuncionario(denunciaId, funcionarioId);

  @override
  Future<bool> agregarRespuestaOficial(int id, String respuesta) =>
      _ds.agregarRespuestaOficial(id, respuesta);
}