import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'paypal_config.dart';
import 'paypal_models.dart';

@JS('virtumetPaypalCheckout')
external void _virtumetPaypalCheckout(
  JSString clientId,
  JSString currency,
  JSString amount,
  JSString description,
  JSFunction onSuccess,
  JSFunction onError,
  JSFunction onCancel,
);

/// Abre la ventana de PayPal (sandbox) y devuelve el pago ya capturado.
/// Lanza [PaypalCancelado] si el usuario cancela y [PaypalError] si falla.
Future<PaypalPago> pagarConPaypal({
  required double monto,
  required String descripcion,
}) {
  final completer = Completer<PaypalPago>();

  void onSuccess(JSString raw) {
    if (completer.isCompleted) return;
    try {
      final json = jsonDecode(raw.toDart) as Map<String, dynamic>;
      completer.complete(PaypalPago.fromJson(json));
    } catch (e) {
      completer.completeError(PaypalError('Respuesta de PayPal inválida: $e'));
    }
  }

  void onError(JSString mensaje) {
    if (!completer.isCompleted) {
      completer.completeError(PaypalError(mensaje.toDart));
    }
  }

  void onCancel() {
    if (!completer.isCompleted) {
      completer.completeError(const PaypalCancelado());
    }
  }

  try {
    _virtumetPaypalCheckout(
      kPaypalClientId.toJS,
      kPaypalMoneda.toJS,
      monto.toStringAsFixed(2).toJS,
      descripcion.toJS,
      onSuccess.toJS,
      onError.toJS,
      onCancel.toJS,
    );
  } catch (e) {
    if (!completer.isCompleted) {
      completer.completeError(PaypalError('No se pudo iniciar PayPal: $e'));
    }
  }

  return completer.future;
}
