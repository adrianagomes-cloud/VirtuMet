/// Precio de las disciplinas (en USD).
///
/// Regla del proyecto: cada disciplina cuesta como mínimo 50 USD.
/// Se guarda en Firestore en `deportes.precio` (número). Las disciplinas
/// creadas antes de existir este campo se consideran de 50 USD.
const double kPrecioMinimo = 50;

/// Precio de una disciplina a partir de su documento de Firestore.
double precioDeDisciplina(Map<String, dynamic> data) {
  final p = data['precio'];
  if (p is num) return p.toDouble();
  return kPrecioMinimo;
}

/// "50" o "52.50" (sin símbolo), para usar en campos de texto.
String precioATexto(double valor) =>
    valor % 1 == 0 ? valor.toInt().toString() : valor.toStringAsFixed(2);

/// "$50" o "$52.50", para mostrar en pantalla.
String formatPrecio(double valor) => '\$${precioATexto(valor)}';
