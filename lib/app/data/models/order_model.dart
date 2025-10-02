import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duniakopi_project/app/data/models/cart_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalPrice;
  final String status;
  final Timestamp createdAt;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
    this.status = 'Pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt,
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
      totalPrice: (data['totalPrice'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'Unknown',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}

