import 'package:duniakopi_project/app/data/models/address_model.dart';
import 'package:duniakopi_project/app/data/models/rajaongkir_model.dart';
import 'package:duniakopi_project/app/data/services/rajaongkir_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutState {
  final AddressModel? selectedAddress;
  final ShippingCostResponse? shippingOptions;
  final CourierOption? selectedCourier;
  final ShippingService? selectedService;
  final bool isLoadingShipping;
  final String? shippingError;

  CheckoutState({
    this.selectedAddress,
    this.shippingOptions,
    this.selectedCourier,
    this.selectedService,
    this.isLoadingShipping = false,
    this.shippingError,
  });

  // Get the shipping cost (0 if no service selected)
  int get shippingCost => selectedService?.cost ?? 0;

  CheckoutState copyWith({
    AddressModel? selectedAddress,
    ShippingCostResponse? shippingOptions,
    CourierOption? selectedCourier,
    ShippingService? selectedService,
    bool? isLoadingShipping,
    String? shippingError,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      shippingOptions: shippingOptions ?? this.shippingOptions,
      selectedCourier: selectedCourier ?? this.selectedCourier,
      selectedService: selectedService ?? this.selectedService,
      isLoadingShipping: isLoadingShipping ?? this.isLoadingShipping,
      shippingError: shippingError,
    );
  }

  CheckoutState clearShipping() {
    return CheckoutState(
      selectedAddress: selectedAddress,
      isLoadingShipping: false,
    );
  }
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref);
});

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final Ref _ref;
  
  CheckoutNotifier(this._ref) : super(CheckoutState());

  // Select address and automatically fetch shipping costs
  Future<void> selectAddress(AddressModel address) async {
    state = state.copyWith(selectedAddress: address);
    await calculateShippingCost();
  }

  // Calculate shipping cost based on selected address and cart weight
  Future<void> calculateShippingCost() async {
    if (state.selectedAddress == null) {
      state = state.copyWith(shippingError: 'Pilih alamat pengiriman terlebih dahulu');
      return;
    }

    final cartItems = _ref.read(cartProvider).value ?? [];
    if (cartItems.isEmpty) {
      state = state.copyWith(shippingError: 'Keranjang belanja kosong');
      return;
    }

    // Set loading state
    state = state.copyWith(isLoadingShipping: true, shippingError: null);

    try {
      // Calculate total weight from cart items (weight in grams)
      final totalWeight = cartItems.fold<int>(0, (sum, item) {
        final weightInt = int.tryParse(item.selectedVariant.weight) ?? 0;
        return sum + (weightInt * item.quantity);
      });

      if (totalWeight <= 0) {
        state = state.copyWith(
          isLoadingShipping: false,
          shippingError: 'Berat total pesanan tidak valid',
        );
        return;
      }

      // Call RajaOngkir API through our backend
      final rajaOngkirService = _ref.read(rajaOngkirServiceProvider);
      final shippingResponse = await rajaOngkirService.getShippingCost(
        destinationCityId: state.selectedAddress!.cityId,
        weight: totalWeight,
        courier: 'jne:tiki:pos', // Check JNE, TIKI, and POS
      );

      // Update state with shipping options
      state = state.copyWith(
        shippingOptions: shippingResponse,
        isLoadingShipping: false,
        shippingError: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingShipping: false,
        shippingError: 'Gagal menghitung ongkos kirim: $e',
      );
    }
  }

  // Select a courier (e.g., JNE)
  void selectCourier(CourierOption courier) {
    state = state.copyWith(
      selectedCourier: courier,
      selectedService: null, // Reset service when courier changes
    );
  }

  // Select a specific service (e.g., JNE REG)
  void selectService(ShippingService service) {
    state = state.copyWith(selectedService: service);
  }

  // Reset checkout state
  void reset() {
    state = CheckoutState();
  }
}

// Provider to get the final total (subtotal + shipping)
final finalTotalPriceProvider = Provider<double>((ref) {
  final cartTotal = ref.watch(cartTotalPriceProvider);
  final shippingCost = ref.watch(checkoutProvider).shippingCost;
  return cartTotal + shippingCost;
});