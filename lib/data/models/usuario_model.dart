import '../../domain/entities/usuario.dart';

class UsuarioModel extends Usuario {
  const UsuarioModel({
    required super.id,
    super.authUserId,
    required super.nombre,
    required super.correo,
    required super.rol,
    super.cargo,
    super.departamento,
    super.fotoUrl,
    required super.activo,
    required super.creadoEn,
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> json) {
    return UsuarioModel(
      id: json['id'] as int,
      authUserId: json['auth_user_id'] as String?,
      nombre: json['nombre'] as String,
      correo: json['correo'] as String,
      rol: json['rol'] as String? ?? 'funcionario',
      cargo: json['cargo'] as String?,
      departamento: json['departamento'] as String?,
      fotoUrl: json['foto_url'] as String?,
      activo: json['activo'] as bool? ?? true,
      creadoEn: DateTime.parse(json['creado_en'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'cargo': cargo,
      'departamento': departamento,
      'foto_url': fotoUrl,
      'activo': activo,
    };
  }
}