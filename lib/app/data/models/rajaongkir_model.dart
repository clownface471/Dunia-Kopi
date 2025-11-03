class Province {
  final String provinceId;
  final String provinceName;

  Province({required this.provinceId, required this.provinceName});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      provinceId: json['province_id'],
      provinceName: json['province'],
    );
  }
}

class City {
  final String cityId;
  final String cityName;

  City({required this.cityId, required this.cityName});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      cityId: json['city_id'],
      cityName: json['city_name'],
    );
  }
}

// NEW: Shipping Cost Models
class ShippingCourier {
  final String code;
  final String name;
  final List<ShippingService> services;

  ShippingCourier({
    required this.code,
    required this.name,
    required this.services,
  });

  factory ShippingCourier.fromJson(Map<String, dynamic> json) {
    return ShippingCourier(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      services: (json['services'] as List<dynamic>?)
              ?.map((s) => ShippingService.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class ShippingService {
  final String service;
  final String description;
  final int cost;
  final String etd;
  final String note;

  ShippingService({
    required this.service,
    required this.description,
    required this.cost,
    required this.etd,
    this.note = '',
  });

  factory ShippingService.fromJson(Map<String, dynamic> json) {
    return ShippingService(
      service: json['service'] ?? '',
      description: json['description'] ?? '',
      cost: json['cost'] ?? 0,
      etd: json['etd'] ?? '',
      note: json['note'] ?? '',
    );
  }

  String get displayName => '$service - $description';
  String get displayEtd => etd.contains('HARI') ? etd : '$etd hari';
}