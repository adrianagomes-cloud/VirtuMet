// Pago con PayPal (modo SANDBOX / pruebas) para VirtuMet.
//
// Muestra una ventana encima de la app con los botones de PayPal. Solo usa el
// Client ID (público); el Client Secret NUNCA va aquí.
//
// Flutter lo llama así (ver lib/paypal_checkout_web.dart):
//   virtumetPaypalCheckout(clientId, currency, amount, description,
//                          onSuccess(json), onError(mensaje), onCancel())
(function () {
  var sdkPromise = null;

  function loadSdk(clientId, currency) {
    if (window.paypal && window.paypal.Buttons) return Promise.resolve(window.paypal);
    if (sdkPromise) return sdkPromise;
    sdkPromise = new Promise(function (resolve, reject) {
      var s = document.createElement('script');
      s.src =
        'https://www.paypal.com/sdk/js?client-id=' +
        encodeURIComponent(clientId) +
        '&currency=' + encodeURIComponent(currency) +
        '&intent=capture';
      s.onload = function () {
        if (window.paypal && window.paypal.Buttons) resolve(window.paypal);
        else { sdkPromise = null; reject(new Error('El SDK de PayPal no se inicializó.')); }
      };
      s.onerror = function () {
        sdkPromise = null;
        reject(new Error('No se pudo cargar PayPal. Revisa tu conexión y el Client ID.'));
      };
      document.head.appendChild(s);
    });
    return sdkPromise;
  }

  window.virtumetPaypalCheckout = function (
    clientId, currency, amount, description, onSuccess, onError, onCancel
  ) {
    var finished = false;

    var overlay = document.createElement('div');
    overlay.style.cssText =
      'position:fixed;top:0;left:0;right:0;bottom:0;z-index:2147483647;' +
      'background:rgba(15,44,89,0.65);display:flex;align-items:center;' +
      'justify-content:center;font-family:Roboto,Arial,sans-serif;';

    var box = document.createElement('div');
    box.style.cssText =
      'background:#fff;border-radius:16px;padding:24px;width:min(420px,92vw);' +
      'max-height:92vh;overflow:auto;box-shadow:0 10px 40px rgba(0,0,0,0.35);';

    var title = document.createElement('div');
    title.textContent = 'Pago de inscripción';
    title.style.cssText = 'font-size:18px;font-weight:700;color:#0F2C59;';

    var detail = document.createElement('div');
    detail.textContent = description + ' — Total: $' + amount + ' ' + currency;
    detail.style.cssText = 'font-size:14px;color:#333;margin:8px 0 4px;';

    var badge = document.createElement('div');
    badge.textContent = 'Modo de pruebas (sandbox): no se cobra dinero real.';
    badge.style.cssText = 'font-size:12px;color:#8a5a00;margin-bottom:16px;';

    var status = document.createElement('div');
    status.textContent = 'Cargando PayPal...';
    status.style.cssText = 'font-size:13px;color:#555;margin-bottom:8px;';

    var container = document.createElement('div');

    var cancel = document.createElement('button');
    cancel.textContent = 'Cancelar';
    cancel.style.cssText =
      'margin-top:14px;width:100%;padding:10px;border:1px solid #cbd5e1;' +
      'border-radius:8px;background:#fff;color:#0F2C59;font-weight:700;cursor:pointer;';

    box.appendChild(title);
    box.appendChild(detail);
    box.appendChild(badge);
    box.appendChild(status);
    box.appendChild(container);
    box.appendChild(cancel);
    overlay.appendChild(box);
    document.body.appendChild(overlay);

    function close() {
      if (overlay.parentNode) overlay.parentNode.removeChild(overlay);
    }
    function done(fn, arg) {
      if (finished) return;
      finished = true;
      close();
      if (arg === undefined) fn(); else fn(arg);
    }

    cancel.onclick = function () { done(onCancel); };

    loadSdk(clientId, currency).then(function (paypal) {
      if (finished) return;
      status.textContent = '';
      paypal.Buttons({
        style: { layout: 'vertical', shape: 'rect', label: 'pay' },
        createOrder: function (data, actions) {
          return actions.order.create({
            purchase_units: [{
              description: description,
              amount: { currency_code: currency, value: amount }
            }]
          });
        },
        onApprove: function (data, actions) {
          return actions.order.capture().then(function (details) {
            var cap = null;
            try {
              cap = details.purchase_units[0].payments.captures[0];
            } catch (e) { cap = null; }
            var payer = details.payer || {};
            var name = payer.name
              ? ((payer.name.given_name || '') + ' ' + (payer.name.surname || '')).trim()
              : '';
            done(onSuccess, JSON.stringify({
              orderId: details.id,
              estado: details.status,
              captureId: cap ? cap.id : null,
              correoPagador: payer.email_address || null,
              nombrePagador: name || null,
              monto: cap && cap.amount ? cap.amount.value : amount,
              moneda: cap && cap.amount ? cap.amount.currency_code : currency
            }));
          });
        },
        onCancel: function () { done(onCancel); },
        onError: function (err) {
          done(onError, String((err && err.message) || err || 'Error de PayPal'));
        }
      }).render(container);
    }).catch(function (err) {
      done(onError, String((err && err.message) || err));
    });
  };
})();
