/// Resultado de un pago aprobado y capturado en PayPal.
class PaypalPago {
  final String orderId;
  final String estado;
  final String? captureId;
  final String? correoPagador;
  final String? nombrePagador;
  final double monto;
  final String moneda;

  const PaypalPago({
    required this.orderId,
    required this.estado,
    required this.monto,
    required this.moneda,
    this.captureId,
    this.correoPagador,
    this.nombrePagador,
  });

  factory PaypalPago.fromJson(Map<String, dynamic> j) {
    return PaypalPago(
      orderId: (j['orderId'] ?? '').toString(),
      estado: (j['estado'] ?? '').toString(),
      captureId: j['captureId']?.toString(),
      correoPagador: j['correoPagador']?.toString(),
      nombrePagador: j['nombrePagador']?.toString(),
      monto: double.tryParse((j['monto'] ?? '0').toString()) ?? 0,
      moneda: (j['moneda'] ?? 'USD').toString(),
    );
  }
}

/// El usuario cerró o canceló la ventana de pago.
class PaypalCancelado implements Exception {
  const PaypalCancelado();
}

/// PayPal no pudo cargar o rechazó el pago.
class PaypalError implements Exception {
  final String mensaje;
  const PaypalError(this.mensaje);

  @override
  String toString() => mensaje;
}
