import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String? id;
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final String city;
  final String cityId; // NEW: Store city ID for shipping calculation
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
    required this.cityId,
    required this.province,
    required this.provinceId,
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
      cityId: data['cityId'] ?? '',
      province: data['province'] ?? '',
      provinceId: data['provinceId'] ?? '',
      postalCode: data['postalCode'] ?? '',
      isPrimary: data['isPrimary'] ?? false,
    );
  }
}