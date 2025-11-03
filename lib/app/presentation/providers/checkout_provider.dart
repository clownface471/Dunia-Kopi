import 'package:duniakopi_project/app/data/models/address_model.dart';
import 'package:duniakopi_project/app/data/models/rajaongkir_model.dart';
import 'package:duniakopi_project/app/data/services/rajaongkir_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutState {
  final AddressModel? selectedAddress;
  final List<ShippingCourier> availableCouriers;
  final ShippingService? selectedShippingService;
  final String? selectedCourierCode;
  final bool isLoadingShipping;
  final String? shippingError;

  CheckoutState({
    this.selectedAddress,
    this.availableCouriers = const [],
    this.selectedShippingService,
    this.selectedCourierCode,
    this.isLoadingShipping = false,
    this.shippingError,
  });

  double get shippingCost => selectedShippingService?.cost.toDouble() ?? 0.0;

  CheckoutState copyWith({
    AddressModel? selectedAddress,
    List<ShippingCourier>? availableCouriers,
    ShippingService? selectedShippingService,
    String? selectedCourierCode,
    bool? isLoadingShipping,
    String? shippingError,
  }) {
    return CheckoutState(
      selectedAddress: selectedAddress ?? this.selectedAddress,
      availableCouriers: availableCouriers ?? this.availableCouriers,
      selectedShippingService: selectedShippingService ?? this.selectedShippingService,
      selectedCourierCode: selectedCourierCode ?? this.selectedCourierCode,
      isLoadingShipping: isLoadingShipping ?? this.isLoadingShipping,
      shippingError: shippingError ?? this.shippingError,
    );
  }

  CheckoutState clearShipping() {
    return CheckoutState(
      selectedAddress: selectedAddress,
      availableCouriers: const [],
      selectedShippingService: null,
      selectedCourierCode: null,
      isLoadingShipping: false,
      shippingError: null,
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
    // Clear shipping selection when address changes
    state = state.clearShipping();
  }

  Future<void> calculateShippingCost() async {
    if (state.selectedAddress == null) {
      state = state.copyWith(
        shippingError: 'Silakan pilih alamat pengiriman terlebih dahulu',
      );
      return;
    }

    // Check if address has cityId (new format)
    if (state.selectedAddress!.cityId.isEmpty) {
      state = state.copyWith(
        shippingError: 'Alamat ini belum memiliki data kota. Silakan edit dan simpan ulang alamat.',
      );
      return;
    }

    final cartItems = _ref.read(cartProvider).value ?? [];
    if (cartItems.isEmpty) {
      state = state.copyWith(
        shippingError: 'Keranjang belanja kosong',
      );
      return;
    }

    // Calculate total weight from cart
    final totalWeight = cartItems.fold<int>(0, (sum, item) {
      final weightInt = int.tryParse(item.selectedVariant.weight) ?? 0;
      return sum + (weightInt * item.quantity);
    });

    if (totalWeight <= 0) {
      state = state.copyWith(
        shippingError: 'Berat pesanan tidak valid',
      );
      return;
    }

    // Set loading state
    state = state.copyWith(
      isLoadingShipping: true,
      shippingError: null,
    );

    try {
      final rajaOngkirService = _ref.read(rajaOngkirServiceProvider);
      final couriers = await rajaOngkirService.getShippingCost(
        destinationCityId: state.selectedAddress!.cityId,
        weightInGrams: totalWeight,
      );

      state = state.copyWith(
        availableCouriers: couriers,
        isLoadingShipping: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingShipping: false,
        shippingError: 'Gagal menghitung ongkos kirim: ${e.toString()}',
      );
    }
  }

  void selectShippingService({
    required ShippingService service,
    required String courierCode,
  }) {
    state = state.copyWith(
      selectedShippingService: service,
      selectedCourierCode: courierCode,
    );
  }

  void reset() {
    state = CheckoutState();
  }
}

final finalTotalPriceProvider = Provider<double>((ref) {
  final cartTotal = ref.watch(cartTotalPriceProvider);
  final shippingCost = ref.watch(checkoutProvider).shippingCost;
  return cartTotal + shippingCost;
});