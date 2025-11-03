import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duniakopi_project/app/data/models/address_model.dart';
import 'package:duniakopi_project/app/data/models/cart_item_model.dart';
import 'package:duniakopi_project/app/data/models/order_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> createOrder({
    required String userId,
    required List<CartItemModel> items,
    required double subtotal,
    required double shippingCost,
    required AddressModel shippingAddress,
    required String courierCode,
    required String courierName,
    required String courierService,
    required String courierServiceDescription,
  }) async {
    final totalPrice = subtotal + shippingCost;

    final newOrder = OrderModel(
      id: '',
      userId: userId,
      items: items,
      subtotal: subtotal,
      shippingCost: shippingCost,
      totalPrice: totalPrice,
      createdAt: Timestamp.now(),
      shippingAddress: ShippingAddress(
        recipientName: shippingAddress.recipientName,
        phoneNumber: shippingAddress.phoneNumber,
        fullAddress: shippingAddress.fullAddress,
        city: shippingAddress.city,
        province: shippingAddress.province,
        postalCode: shippingAddress.postalCode,
      ),
      courierCode: courierCode,
      courierName: courierName,
      courierService: courierService,
      courierServiceDescription: courierServiceDescription,
    );

    await _db.collection('orders').add(newOrder.toMap());

    // Clear the cart
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

  Stream<List<OrderModel>> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) => OrderModel.fromFirestore(doc)).toList(),
        );
  }
}

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

final ordersProvider = StreamProvider<List<OrderModel>>((ref) {
  final orderService = ref.watch(orderServiceProvider);
  return orderService.getOrders();
});