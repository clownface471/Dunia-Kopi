import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duniakopi_project/app/data/models/cart_item_model.dart';
import 'package:duniakopi_project/app/data/models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createOrder({
    required String userId,
    required List<CartItemModel> items,
    required double totalPrice,
  }) async {
    final newOrder = OrderModel(
      id: '', // Firestore akan generate ID
      userId: userId,
      items: items,
      totalPrice: totalPrice,
      createdAt: Timestamp.now(),
    );
    await _db.collection('orders').add(newOrder.toMap());

    final cartCollection = _db.collection('users').doc(userId).collection('cart');
    final cartSnapshot = await cartCollection.get();
    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }
  }

  Stream<List<OrderModel>> getOrders() {
    return _db.collection('orders').orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
        );
  }
}

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

final ordersProvider = StreamProvider<List<OrderModel>>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getOrders();
});

