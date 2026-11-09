/// Audiencias posibles de un aviso (campo `audiencia` en la colección `avisos`).
///  - 'Todos'        → lo ven estudiantes y entrenadores
///  - 'Estudiantes'  → solo estudiantes
///  - 'Entrenadores' → solo entrenadores
const List<String> kAudiencias = ['Todos', 'Estudiantes', 'Entrenadores'];

/// Indica si un aviso debe mostrarse a [audiencia] ('Estudiantes' o
/// 'Entrenadores'). Los avisos antiguos, que no tienen el campo `audiencia`,
/// se consideran dirigidos a 'Todos'.
bool avisoDirigidoA(Map<String, dynamic> aviso, String audiencia) {
  final String a = (aviso['audiencia'] ?? 'Todos').toString();
  return a == 'Todos' || a == audiencia;
}
