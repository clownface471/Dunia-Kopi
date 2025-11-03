import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duniakopi_project/app/data/models/cart_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double subtotal; // Renamed from totalPrice
  final double shippingCost; // NEW
  final double totalPrice; // NEW: subtotal + shippingCost
  final String status;
  final Timestamp createdAt;
  
  // NEW: Shipping details
  final ShippingAddress? shippingAddress;
  final String? courierCode;
  final String? courierName;
  final String? courierService;
  final String? courierServiceDescription;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    this.shippingCost = 0.0,
    required this.totalPrice,
    this.status = 'Pending',
    required this.createdAt,
    this.shippingAddress,
    this.courierCode,
    this.courierName,
    this.courierService,
    this.courierServiceDescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt,
      'shippingAddress': shippingAddress?.toMap(),
      'courierCode': courierCode,
      'courierName': courierName,
      'courierService': courierService,
      'courierServiceDescription': courierServiceDescription,
    };
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>)
          .map((itemData) => CartItemModel.fromMap(itemData))
          .toList(),
      subtotal: (data['subtotal'] ?? data['totalPrice'] ?? 0.0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0.0).toDouble(),
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Unknown',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      shippingAddress: data['shippingAddress'] != null 
          ? ShippingAddress.fromMap(data['shippingAddress']) 
          : null,
      courierCode: data['courierCode'],
      courierName: data['courierName'],
      courierService: data['courierService'],
      courierServiceDescription: data['courierServiceDescription'],
    );
  }
}

// NEW: Embedded shipping address in order
class ShippingAddress {
  final String recipientName;
  final String phoneNumber;
  final String fullAddress;
  final String city;
  final String province;
  final String postalCode;

  ShippingAddress({
    required this.recipientName,
    required this.phoneNumber,
    required this.fullAddress,
    required this.city,
    required this.province,
    required this.postalCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'fullAddress': fullAddress,
      'city': city,
      'province': province,
      'postalCode': postalCode,
    };
  }

  factory ShippingAddress.fromMap(Map<String, dynamic> map) {
    return ShippingAddress(
      recipientName: map['recipientName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      fullAddress: map['fullAddress'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      postalCode: map['postalCode'] ?? '',
    );
  }

  String get formatted {
    return '$fullAddress, $city, $province $postalCode';
  }
}