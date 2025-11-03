import 'dart:convert';
import 'package:duniakopi_project/app/data/models/address_model.dart';
import 'package:duniakopi_project/app/data/models/rajaongkir_model.dart';
import 'package:duniakopi_project/app/data/services/address_service.dart';
import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/data/services/order_service.dart';
import 'package:duniakopi_project/app/data/services/payment_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:duniakopi_project/app/presentation/providers/checkout_provider.dart';
import 'package:duniakopi_project/app/presentation/screens/add_edit_address_screen.dart';
import 'package:duniakopi_project/app/presentation/screens/order_success_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

final addressesProvider = StreamProvider.autoDispose((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId != null) {
    return ref.watch(addressServiceProvider).getAddresses(userId);
  }
  return Stream.value([]);
});

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isProcessingPayment = false;
  final String _backendUrl = "https://dunia-kopi-backend.vercel.app/api/create-transaction";
  final PaymentService _paymentService = PaymentService();

  Future<void> _processPayment() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran saat ini hanya didukung di versi website.")),
      );
      return;
    }

    final checkoutState = ref.read(checkoutProvider);
    
    // Validation
    if (checkoutState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih alamat pengiriman terlebih dahulu.")),
      );
      return;
    }

    if (checkoutState.selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih layanan pengiriman terlebih dahulu.")),
      );
      return;
    }

    final userValue = ref.read(authStateProvider).value;
    final cartItems = ref.read(cartProvider).value ?? [];
    final finalTotal = ref.read(finalTotalPriceProvider);

    if (userValue == null || cartItems.isEmpty) return;
    final user = userValue;

    setState(() => _isProcessingPayment = true);

    try {
      final orderId = 'duniakopi-${DateTime.now().millisecondsSinceEpoch}';
      final String customerEmail = user.email ?? 'guest@duniakopi.com';
      final String customerName = user.displayName ?? customerEmail.split('@').first;

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'transaction_details': {
            'order_id': orderId,
            'gross_amount': finalTotal.toInt(),
          },
          'customer_details': {
            'first_name': customerName,
            'email': customerEmail,
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal mendapatkan token transaksi: ${response.body}');
      }

      final responseBody = json.decode(response.body);
      final transactionToken = responseBody['token'];

      if (transactionToken == null) {
        throw Exception('Token transaksi tidak ditemukan.');
      }

      _paymentService.startMidtransPayment(transactionToken, (result) async {
        if (result == 'success' || result == 'pending') {
          // Create order with shipping details
          final address = checkoutState.selectedAddress!;
          final courier = checkoutState.selectedCourier!;
          final service = checkoutState.selectedService!;
          
          await ref.read(orderServiceProvider).createOrder(
            userId: user.uid,
            items: cartItems,
            totalPrice: finalTotal,
            shippingAddress: '${address.fullAddress}, ${address.city}, ${address.province} ${address.postalCode}',
            recipientName: address.recipientName,
            recipientPhone: address.phoneNumber,
            courierCode: courier.code,
            courierService: '${courier.name} - ${service.service}',
            shippingCost: service.cost,
          );

          // Reset checkout state
          ref.read(checkoutProvider.notifier).reset();

          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
              (route) => route.isFirst,
            );
          }
        } else if (result == 'closed') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Anda menutup jendela pembayaran.")),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pembayaran gagal atau error.")),
            );
          }
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Terjadi kesalahan: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider).value ?? [];
    final subtotal = ref.watch(cartTotalPriceProvider);
    final checkoutState = ref.watch(checkoutProvider);
    final finalTotal = ref.watch(finalTotalPriceProvider);
    final addressesAsync = ref.watch(addressesProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Selection Section
            Text("Alamat Pengiriman", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            addressesAsync.when(
              data: (addresses) {
                if (addresses.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text("Anda belum memiliki alamat."),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text("Tambah Alamat"),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const AddEditAddressScreen(),
                              ));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return Column(
                  children: addresses.map((address) {
                    final isSelected = checkoutState.selectedAddress?.id == address.id;
                    return Card(
                      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
                      child: RadioListTile<AddressModel>(
                        value: address,
                        groupValue: checkoutState.selectedAddress,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(checkoutProvider.notifier).selectAddress(value);
                          }
                        },
                        title: Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${address.fullAddress}\n${address.city}, ${address.province} ${address.postalCode}\n${address.phoneNumber}"),
                        isThreeLine: true,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text("Error: $e"),
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Shipping Options Section
            Text("Pilih Kurir & Layanan", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            
            if (checkoutState.isLoadingShipping)
              const Center(child: CircularProgressIndicator())
            else if (checkoutState.shippingError != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(checkoutState.shippingError!, style: const TextStyle(color: Colors.red)),
                ),
              )
            else if (checkoutState.shippingOptions != null)
              ...checkoutState.shippingOptions!.results.map((courier) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: Text(courier.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    children: courier.services.map((service) {
                      final isSelected = checkoutState.selectedService == service &&
                                        checkoutState.selectedCourier == courier;
                      return RadioListTile<ShippingService>(
                        value: service,
                        groupValue: checkoutState.selectedService,
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(checkoutProvider.notifier).selectCourier(courier);
                            ref.read(checkoutProvider.notifier).selectService(value);
                          }
                        },
                        title: Text("${service.service} - ${service.description}"),
                        subtitle: Text("Estimasi: ${service.etd} hari"),
                        secondary: Text(
                          currencyFormatter.format(service.cost),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        selected: isSelected,
                      );
                    }).toList(),
                  ),
                );
              }).toList()
            else
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text("Pilih alamat untuk melihat opsi pengiriman."),
                ),
              ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Order Summary Section
Text("Ringkasan Pesanan", style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...cartItems.map((item) => ListTile(
                  leading: Image.network(item.imageUrl, width: 50),
                  title: Text("${item.productName} (${item.selectedVariant.weight}gr)"),
                  subtitle: Text("${item.quantity} x ${currencyFormatter.format(item.selectedVariant.price)}"),
                  trailing: Text(currencyFormatter.format(item.quantity * item.selectedVariant.price)),
                )),
            const Divider(height: 32),
            
            // Price Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Subtotal", style: TextStyle(fontSize: 16)),
                Text(currencyFormatter.format(subtotal), style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Ongkos Kirim", style: TextStyle(fontSize: 16)),
                Text(
                  checkoutState.shippingCost > 0 
                    ? currencyFormatter.format(checkoutState.shippingCost)
                    : "-",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  currencyFormatter.format(finalTotal),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isProcessingPayment
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: checkoutState.selectedAddress != null && 
                         checkoutState.selectedService != null
                    ? _processPayment
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: Text(
                  "Bayar ${currencyFormatter.format(finalTotal)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
      ),
    );
  }
}