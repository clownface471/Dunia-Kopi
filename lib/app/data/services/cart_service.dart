import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duniakopi_project/app/data/models/cart_item_model.dart';
import 'package:duniakopi_project/app/data/models/product_model.dart';

class CartService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<CartItemModel> _cartCollection(String userId) {
    return _db.collection('users').doc(userId).collection('cart').withConverter<CartItemModel>(
          fromFirestore: (snapshot, _) => CartItemModel.fromFirestore(snapshot),
          toFirestore: (cartItem, _) => cartItem.toMap(),
        );
  }

  Stream<List<CartItemModel>> getCart(String userId) {
    return _cartCollection(userId).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addItem(String userId, ProductModel product, ProductVariant variant) async {
    final cartItemRef = _cartCollection(userId);
    final query = await cartItemRef
        .where('productId', isEqualTo: product.id)
        .where('selectedVariant.weight', isEqualTo: variant.weight)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      await doc.reference.update({'quantity': doc.data().quantity + 1});
    } else {
      final newCartItem = CartItemModel(
        id: '',
        productId: product.id!,
        productName: product.name,
        imageUrl: product.imageUrl,
        selectedVariant: variant,
      );
      await cartItemRef.add(newCartItem);
    }
  }

  Future<void> removeItem(String userId, String cartItemId) async {
    await _cartCollection(userId).doc(cartItemId).delete();
  }

  Future<void> updateQuantity(String userId, String cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(userId, cartItemId);
    } else {
      await _cartCollection(userId).doc(cartItemId).update({'quantity': newQuantity});
    }
  }
}
