class Evidencia {
  final int id;
  final int denunciaId;
  final String? archivoUrl;
  final String tipo;        
  final DateTime subidoEn;

  const Evidencia({
    required this.id,
    required this.denunciaId,
    this.archivoUrl,
    required this.tipo,
    required this.subidoEn,
  });
}