import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String? id;
  final String name;
  final String description;
  final String imageUrl;
  final List<ProductVariant> variants;
  final String origin;
  final String roastLevel;
  final String tastingNotes;
  final int stock;

  ProductModel({
    this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.variants = const [],
    this.origin = '',
    this.roastLevel = '',
    this.tastingNotes = '',
    this.stock = 0,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      origin: data['origin'] ?? '',
      roastLevel: data['roastLevel'] ?? '',
      tastingNotes: data['tastingNotes'] ?? '',
      stock: data['stock'] ?? 0,
      variants: (data['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromMap(v))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'origin': origin,
      'roastLevel': roastLevel,
      'tastingNotes': tastingNotes,
      'stock': stock,
      'variants': variants.map((v) => v.toMap()).toList(),
    };
  }
}

class ProductVariant {
  final String weight;
  final int price;

  ProductVariant({
    required this.weight,
    required this.price,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      weight: map['weight'] ?? '',
      price: map['price'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'price': price,
    };
  }
}