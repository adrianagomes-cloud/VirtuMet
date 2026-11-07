// Fachada del pago con PayPal.
//
// En web usa paypal_checkout_web.dart (llama a web/paypal_checkout.js).
// En cualquier otra plataforma usa el "stub", que avisa que no está disponible.
export 'paypal_models.dart';
export 'paypal_checkout_stub.dart'
    if (dart.library.js_interop) 'paypal_checkout_web.dart';
