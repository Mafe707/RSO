abstract class Failure {
  final String message;
  const Failure(this.message);
}

// Errores de Supabase / red
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Errores de autenticación (login, registro)
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

// Errores de validación de datos
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Errores de subida de archivos al Storage
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

// Denuncia no encontrada por código
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}