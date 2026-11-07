import 'paypal_models.dart';

/// Versión para plataformas que no son web.
Future<PaypalPago> pagarConPaypal({
  required double monto,
  required String descripcion,
}) async {
  throw const PaypalError(
      'El pago con PayPal solo está disponible en la versión web.');
}
