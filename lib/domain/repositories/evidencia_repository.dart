import 'dart:typed_data';
import '../entities/evidencia.dart';

abstract class EvidenciaRepository {
  // Obtener todas las evidencias de una denuncia
  Future<List<Evidencia>> obtenerPorDenuncia(int denunciaId);

  // Funcionario agrega evidencia adicional a una denuncia existente
  Future<Evidencia?> agregarEvidencia({
    required int denunciaId,
    required Uint8List archivoBytes,
    String tipo = 'imagen',
  });

  // Eliminar evidencia (solo admin)
  Future<bool> eliminarEvidencia(int evidenciaId);
}