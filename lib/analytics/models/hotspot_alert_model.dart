// Representa una alerta generada cuando una zona supera el umbral
// de reportes en una ventana temporal determinada.
class HotspotAlert {
  final String zonaId;
  final String zonaNombre;
  final String mensaje;
  final String nivel; // 'warning' o 'critical'
  final int reportesEnVentana;
  final int ventanaHoras;
  final DateTime generadaEn;

  const HotspotAlert({
    required this.zonaId,
    required this.zonaNombre,
    required this.mensaje,
    required this.nivel,
    required this.reportesEnVentana,
    required this.ventanaHoras,
    required this.generadaEn,
  });

  bool get esCritica => nivel == 'critical';

  factory HotspotAlert.fromZona({
    required String zonaId,
    required String zonaNombre,
    required int reportes,
    required int ventanaHoras,
  }) {
    final esCritica = reportes >= 8;
    return HotspotAlert(
      zonaId: zonaId,
      zonaNombre: zonaNombre,
      nivel: esCritica ? 'critical' : 'warning',
      reportesEnVentana: reportes,
      ventanaHoras: ventanaHoras,
      generadaEn: DateTime.now(),
      mensaje: esCritica
          ? 'CRÍTICO: $reportes denuncias en $zonaNombre en ${ventanaHoras}h'
          : 'ALERTA: $reportes denuncias en $zonaNombre en ${ventanaHoras}h',
    );
  }
}