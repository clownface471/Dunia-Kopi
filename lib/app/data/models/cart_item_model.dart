import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duniakopi_project/app/data/models/product_model.dart';

class CartItemModel {
  final String id; // ID unik untuk item di keranjang
  final String productId;
  final String productName;
  final String imageUrl;
  final ProductVariant selectedVariant;
  int quantity;

  CartItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.selectedVariant,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'selectedVariant': selectedVariant.toMap(),
      'quantity': quantity,
    };
  }

  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CartItemModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      selectedVariant: ProductVariant.fromMap(data['selectedVariant']),
      quantity: data['quantity'] ?? 0,
    );
  }
}

