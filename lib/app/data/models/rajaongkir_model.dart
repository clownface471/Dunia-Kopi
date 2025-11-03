class Province {
  final String provinceId;
  final String provinceName;

  Province({required this.provinceId, required this.provinceName});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      // PERBAIKAN: Tambahkan null check dan fallback ke string kosong
      provinceId: json['province_id'] as String? ?? '',
      provinceName: json['province'] as String? ?? '',
    );
  }
}

class City {
  final String cityId;
  final String cityName;

  City({required this.cityId, required this.cityName});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      // PERBAIKAN: Tambahkan null check dan fallback ke string kosong
      cityId: json['city_id'] as String? ?? '',
      cityName: json['city_name'] as String? ?? '',
    );
  }
}

// NEW: Shipping Cost Models
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
    required this.note,
  });

  factory ShippingService.fromJson(Map<String, dynamic> json) {
    final costValue = (json['cost'] is int) 
      ? json['cost'] 
      : (json['cost'] as num?)?.toInt() ?? 0;

    return ShippingService(
      service: json['service'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cost: costValue,
      etd: json['etd'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }
}

class CourierOption {
  final String code;
  final String name;
  final List<ShippingService> services;

  CourierOption({
    required this.code,
    required this.name,
    required this.services,
  });

  factory CourierOption.fromJson(Map<String, dynamic> json) {
    return CourierOption(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      services: (json['services'] as List<dynamic>?)
              ?.map((s) => ShippingService.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ShippingCostResponse {
  final bool success;
  final int weight;
  final List<CourierOption> results;

  ShippingCostResponse({
    required this.success,
    required this.weight,
    required this.results,
  });

  factory ShippingCostResponse.fromJson(Map<String, dynamic> json) {
    return ShippingCostResponse(
      success: json['success'] as bool? ?? false,
      weight: (json['weight'] as num?)?.toInt() ?? 0,
      results: (json['results'] as List<dynamic>?)
              ?.map((r) => CourierOption.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}