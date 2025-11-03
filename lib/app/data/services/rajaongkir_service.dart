import 'dart:convert';
import 'package:duniakopi_project/app/data/models/rajaongkir_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class RajaOngkirService {
  final String _baseUrl = "https://dunia-kopi-backend.vercel.app/api";

  Future<List<Province>> getProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/provinces'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Province.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load provinces: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching provinces: $e');
    }
  }

  Future<List<City>> getCities(String provinceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cities/$provinceId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => City.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching cities: $e');
    }
  }

  // NEW: Get Shipping Cost
  Future<ShippingCostResponse> getShippingCost({
    required String destinationCityId,
    required int weight,
    String courier = 'jne:tiki:pos',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/shipping-cost'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'destination': destinationCityId,
          'weight': weight,
          'courier': courier,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ShippingCostResponse.fromJson(data);
      } else {
        throw Exception('Failed to calculate shipping cost: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error calculating shipping cost: $e');
    }
  }
}

final rajaOngkirServiceProvider = Provider<RajaOngkirService>((ref) => RajaOngkirService());

final provincesProvider = FutureProvider<List<Province>>((ref) async {
  return ref.read(rajaOngkirServiceProvider).getProvinces();
});

final citiesProvider = FutureProvider.family<List<City>, String>((ref, provinceId) async {
  return ref.read(rajaOngkirServiceProvider).getCities(provinceId);
});