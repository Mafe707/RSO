import 'dart:typed_data';
import '../../domain/entities/evidencia.dart';
import '../../domain/repositories/evidencia_repository.dart';
import '../datasources/supabase/evidencia_supabase_ds.dart';

class EvidenciaRepositoryImpl implements EvidenciaRepository {
  final EvidenciaSupabaseDs _ds;

  EvidenciaRepositoryImpl(this._ds);

  @override
  Future<List<Evidencia>> obtenerPorDenuncia(int denunciaId) =>
      _ds.obtenerPorDenuncia(denunciaId);

  @override
  Future<Evidencia?> agregarEvidencia({
    required int denunciaId,
    required Uint8List archivoBytes,
    String tipo = 'imagen',
  }) {
    return _ds.agregarEvidencia(
      denunciaId: denunciaId,
      archivoBytes: archivoBytes,
      tipo: tipo,
    );
  }

  @override
  Future<bool> eliminarEvidencia(int evidenciaId) =>
      _ds.eliminarEvidencia(evidenciaId);
}