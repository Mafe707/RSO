// Cubre tanto funcionarios como administradores
class Usuario {
  final int id;
  final String? authUserId;    
  final String nombre;
  final String correo;
  final String rol;              
  final String? cargo;           
  final String? departamento;   
  final String? fotoUrl;
  final bool activo;
  final DateTime creadoEn;

  const Usuario({
    required this.id,
    this.authUserId,
    required this.nombre,
    required this.correo,
    required this.rol,
    this.cargo,
    this.departamento,
    this.fotoUrl,
    required this.activo,
    required this.creadoEn,
  });
}