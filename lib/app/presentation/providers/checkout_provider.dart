import 'package:duniakopi_project/app/data/models/address_model.dart';
import 'package:duniakopi_project/app/data/services/rajaongkir_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutState {
  final AddressModel? selectedAddress;
  final String? selectedCourier;
  final double shippingCost;

  CheckoutState({
    this.selectedAddress,
    this.selectedCourier,
    this.shippingCost = 0.0,
  });

  CheckoutState copyWith({
    AddressModel? selectedAddress,
    String? selectedCourier,
    double? shippingCost,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      selectedCourier: selectedCourier ?? this.selectedCourier,
      shippingCost: shippingCost ?? this.shippingCost,
    );
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;
  CheckoutNotifier(this._ref) : super(CheckoutState());

  void selectAddress(AddressModel address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<void> calculateShippingCost() async {
    final cartItems = _ref.read(cartProvider).value ?? [];
    if (state.selectedAddress == null || cartItems.isEmpty) {
      return;
    }
    
    final totalWeight = cartItems.fold(0, (sum, item) {
      final weightInt = int.tryParse(item.selectedVariant.weight) ?? 0;
      return sum + (weightInt * item.quantity);
    });

    print("Total weight is $totalWeight grams.");
  }
}

final finalTotalPriceProvider = Provider<double>((ref) {
  final cartTotal = ref.watch(cartTotalPriceProvider);
  final shippingCost = ref.watch(checkoutProvider).shippingCost;
  return cartTotal + shippingCost;
});