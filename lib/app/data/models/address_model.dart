import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String? id;
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final String city;
  final String cityId; // NEW: Store city ID for shipping calculations
  final String province;
  final String provinceId; // NEW: Store province ID
  final String postalCode;
  final bool isPrimary;

  AddressModel({
    this.id,
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    required this.city,
    this.cityId = '', // Default value
    required this.province,
    this.provinceId = '', // Default value
    required this.postalCode,
    this.isPrimary = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'fullAddress': fullAddress,
      'city': city,
      'cityId': cityId,
      'province': province,
      'provinceId': provinceId,
      'postalCode': postalCode,
      'isPrimary': isPrimary,
    };
  }

  factory AddressModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AddressModel(
      id: doc.id,
      recipientName: data['recipientName'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      fullAddress: data['fullAddress'] ?? '',
      city: data['city'] ?? '',
      cityId: data['cityId'] ?? '', // Provide default for old data
      province: data['province'] ?? '',
      provinceId: data['provinceId'] ?? '', // Provide default for old data
      postalCode: data['postalCode'] ?? '',
      isPrimary: data['isPrimary'] ?? false,
    );
  }

  // Helper method to get formatted full address
  String get formattedAddress {
    return '$fullAddress, $city, $province $postalCode';
  }

  // Helper to check if address has shipping data
  bool get hasShippingData => cityId.isNotEmpty;
}