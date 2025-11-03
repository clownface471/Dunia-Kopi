import 'dart:convert';
import 'package:duniakopi_project/app/data/models/rajaongkir_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class RajaOngkirService {
  final String _baseUrl = "https://dunia-kopi-backend.vercel.app/api";

  Future<List<Province>> getProvinces() async {
    final response = await http.get(Uri.parse('$_baseUrl/provinces'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Province.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat provinsi');
    }
  }

  Future<List<City>> getCities(String provinceId) async {
    final response = await http.get(Uri.parse('$_baseUrl/cities/$provinceId'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => City.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat kota');
    }
  }

  // NEW: Calculate shipping cost
  Future<List<ShippingCourier>> getShippingCost({
    required String destinationCityId,
    required int weightInGrams,
    String courier = 'jne,tiki,pos',
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/shipping-cost'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'destination': destinationCityId,
        'weight': weightInGrams,
        'courier': courier,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        List<dynamic> results = data['results'] ?? [];
        return results.map((json) => ShippingCourier.fromJson(json)).toList();
      } else {
        throw Exception('Gagal mendapatkan ongkos kirim: ${data['error']}');
      }
    } else {
      final errorData = json.decode(response.body);
      throw Exception('Gagal mendapatkan ongkos kirim: ${errorData['error'] ?? 'Unknown error'}');
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