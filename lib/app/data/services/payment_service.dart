import 'dart:js' as js;

class PaymentService {
  void startMidtransPayment(String token, Function(String) onFinished) {
    js.context['snap'].callMethod('pay', [
      token,
      js.JsObject.jsify({
        'onSuccess': (result) {
          onFinished('success');
        },
        'onPending': (result) {
          onFinished('pending');
        },
        'onError': (result) {
          onFinished('error');
        },
        'onClose': () {
          onFinished('closed');
        }
      })
    ]);
  }
}
