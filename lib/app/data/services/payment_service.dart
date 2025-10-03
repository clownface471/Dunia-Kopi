// ignore_for_file: avoid_web_libraries_in_flutter

@JS()
library midtrans;

import 'package:js/js.dart';

@JS('snap.pay')
external void _pay(String token, MidtransOptions options);

@JS()
@anonymous
class MidtransOptions {
  external factory MidtransOptions({
    Function(dynamic result) onSuccess,
    Function(dynamic result) onPending,
    Function(dynamic result) onError,
    Function() onClose,
  });
}

class PaymentService {
  void startMidtransPayment(String token, Function(String) onFinished) {
    _pay(
      token,
      MidtransOptions(
        onSuccess: allowInterop((result) => onFinished('success')),
        onPending: allowInterop((result) => onFinished('pending')),
        onError: allowInterop((result) => onFinished('error')),
        onClose: allowInterop(() => onFinished('closed')),
      ),
    );
  }
}