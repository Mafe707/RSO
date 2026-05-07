import 'dart:typed_data';
import '../entities/denuncia.dart';

abstract class DenunciaRepository {
  // Ciudadano
  Future<Denuncia?> crearDenuncia({
    required String ubicacion,
    double? latitud,
    double? longitud,
    required String categoria,
    required String descripcion,
    List<Uint8List>? imagenesBytes,
  });

  Future<Denuncia?> obtenerPorCodigo(String codigo);

  // Funcionario / Admin
  Future<List<Denuncia>> obtenerTodas();
  Future<List<Denuncia>> obtenerPorFuncionario(int funcionarioId);
  Future<bool> actualizarEstado(int id, String nuevoEstado);
  Future<bool> asignarFuncionario(int denunciaId, int funcionarioId);
  Future<bool> agregarRespuestaOficial(int id, String respuesta);
}