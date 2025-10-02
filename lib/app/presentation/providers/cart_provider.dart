import 'package:duniakopi_project/app/data/models/cart_item_model.dart';
import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/data/services/cart_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());

final cartProvider = StreamProvider<List<CartItemModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user != null) {
    return ref.watch(cartServiceProvider).getCart(user.uid);
  }
  return Stream.value([]); 
});

final cartTotalItemsProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider).value ?? [];
  return cart.fold(0, (sum, item) => sum + item.quantity);
});

final cartTotalPriceProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider).value ?? [];
  return cart.fold(0, (sum, item) => sum + (item.selectedVariant.price * item.quantity));
});

