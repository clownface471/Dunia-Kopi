import 'dart:convert';

class ShippingOption {
  final String code; // e.g., 'jne'
  final String service; // e.g., 'OKE'
  final String description; // e.g., 'Ongkos Kirim Ekonomis'
  final int value; // e.g., 18000
  final String etd; // e.g., '3-5' (estimasi hari)

  ShippingOption({
    required this.code,
    required this.service,
    required this.description,
    required this.value,
    required this.etd,
  });

  @override
  String toString() {
    return 'ShippingOption(code: $code, service: $service, value: $value)';
  }
}

List<ShippingOption> parseShippingOptions(String responseBody) {
  final parsed = json.decode(responseBody);
  final List results = parsed['rajaongkir']['results'];
  final List<ShippingOption> options = [];

  for (var courierResult in results) {
    final String code = courierResult['code'];
    final List costs = courierResult['costs'];
    for (var serviceCost in costs) {
      final String service = serviceCost['service'];
      final String description = serviceCost['description'];
      final List costDetails = serviceCost['cost'];
      if (costDetails.isNotEmpty) {
        final int value = costDetails[0]['value'];
        final String etd = costDetails[0]['etd'];
        options.add(
          ShippingOption(
            code: code.toUpperCase(),
            service: service,
            description: description,
            value: value,
            etd: etd,
          ),
        );
      }
    }
  }
  return options;
}