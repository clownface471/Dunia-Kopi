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
  final String _backendUrl =
      "https://dunia-kopi-backend.vercel.app/api/create-transaction";
  final PaymentService _paymentService = PaymentService();

  @override
  void initState() {
    super.initState();
    // Reset checkout state when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(checkoutProvider.notifier).reset();
    });
  }

  void _showAddressSelector() {
    final addressesAsync = ref.read(addressesProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Pilih Alamat Pengiriman",
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const AddEditAddressScreen(),
                          ));
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: addressesAsync.when(
                    data: (addresses) {
                      if (addresses.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_off, size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              const Text("Belum ada alamat tersimpan"),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text("Tambah Alamat"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const AddEditAddressScreen(),
                                  ));
                                },
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                address.recipientName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${address.phoneNumber}\n${address.formattedAddress}',
                              ),
                              isThreeLine: true,
                              onTap: () {
                                ref.read(checkoutProvider.notifier).selectAddress(address);
                                Navigator.of(context).pop();
                                // Auto-calculate shipping
                                ref.read(checkoutProvider.notifier).calculateShippingCost();
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, st) => Center(child: Text("Error: $e")),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCourierSelector() {
    final checkoutState = ref.read(checkoutProvider);
    
    if (checkoutState.availableCouriers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada kurir tersedia")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final currencyFormatter = NumberFormat.currency(
              locale: 'id_ID',
              symbol: 'Rp ',
              decimalDigits: 0,
            );

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    "Pilih Kurir Pengiriman",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: checkoutState.availableCouriers.length,
                    itemBuilder: (context, courierIndex) {
                      final courier = checkoutState.availableCouriers[courierIndex];
                      return ExpansionTile(
                        title: Text(
                          courier.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        children: courier.services.map((service) {
                          return ListTile(
                            title: Text(service.displayName),
                            subtitle: Text("Estimasi: ${service.displayEtd}"),
                            trailing: Text(
                              currencyFormatter.format(service.cost),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            onTap: () {
                              ref.read(checkoutProvider.notifier).selectShippingService(
                                    service: service,
                                    courierCode: courier.code,
                                  );
                              Navigator.of(context).pop();
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _processPayment() async {
    final checkoutState = ref.read(checkoutProvider);
    
    // Validation
    if (checkoutState.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih alamat pengiriman")),
      );
      return;
    }

    if (checkoutState.selectedShippingService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan pilih kurir pengiriman")),
      );
      return;
    }

    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pembayaran saat ini hanya didukung di versi website."),
        ),
      );
      return;
    }

    final userValue = ref.read(authStateProvider).value;
    final cartItems = ref.read(cartProvider).value ?? [];
    final subtotal = ref.read(cartTotalPriceProvider);
    final finalTotal = ref.read(finalTotalPriceProvider);

    if (userValue == null || cartItems.isEmpty) return;
    final user = userValue;

    setState(() => _isProcessingPayment = true);

    try {
      final orderId = 'duniakopi-${DateTime.now().millisecondsSinceEpoch}';
      final String customerEmail = user.email ?? 'guest@duniakopi.com';
      final String customerName =
          user.displayName ?? customerEmail.split('@').first;

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
          // Find courier name from available couriers
          final selectedCourier = checkoutState.availableCouriers.firstWhere(
            (c) => c.code == checkoutState.selectedCourierCode,
            orElse: () => checkoutState.availableCouriers.first,
          );

          await ref.read(orderServiceProvider).createOrder(
                userId: user.uid,
                items: cartItems,
                subtotal: subtotal,
                shippingCost: checkoutState.shippingCost,
                shippingAddress: checkoutState.selectedAddress!,
                courierCode: checkoutState.selectedCourierCode!,
                courierName: selectedCourier.name,
                courierService: checkoutState.selectedShippingService!.service,
                courierServiceDescription:
                    checkoutState.selectedShippingService!.description,
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
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Address Section
            _buildSectionHeader("Alamat Pengiriman"),
            Card(
              child: InkWell(
                onTap: _showAddressSelector,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: checkoutState.selectedAddress == null
                      ? const Row(
                          children: [
                            Icon(Icons.add_location_alt_outlined),
                            SizedBox(width: 16),
                            Text("Pilih Alamat Pengiriman"),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              checkoutState.selectedAddress!.recipientName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(checkoutState.selectedAddress!.phoneNumber),
                            const SizedBox(height: 4),
                            Text(checkoutState.selectedAddress!.formattedAddress),
                            if (!checkoutState.selectedAddress!.hasShippingData)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  '⚠️ Alamat ini perlu diperbarui untuk menghitung ongkir',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Shipping Section
            _buildSectionHeader("Kurir Pengiriman"),
            if (checkoutState.isLoadingShipping)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (checkoutState.shippingError != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    checkoutState.shippingError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else if (checkoutState.availableCouriers.isEmpty &&
                checkoutState.selectedAddress != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text("Belum ada kurir dipilih"),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(checkoutProvider.notifier).calculateShippingCost();
                        },
                        child: const Text("Hitung Ongkir"),
                      ),
                    ],
                  ),
                ),
              )
            else if (checkoutState.selectedShippingService != null)
              Card(
                child: InkWell(
                  onTap: _showCourierSelector,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                checkoutState.selectedCourierCode!.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                checkoutState.selectedShippingService!.displayName,
                              ),
                              Text(
                                "Estimasi: ${checkoutState.selectedShippingService!.displayEtd}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currencyFormatter.format(checkoutState.shippingCost),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                child: InkWell(
                  onTap: checkoutState.availableCouriers.isNotEmpty
                      ? _showCourierSelector
                      : null,
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.local_shipping_outlined),
                        SizedBox(width: 16),
                        Text("Pilih Kurir Pengiriman"),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Order Summary
            _buildSectionHeader("Ringkasan Pesanan"),
            ...cartItems.map((item) => ListTile(
                  leading: Image.network(item.imageUrl, width: 50),
                  title: Text(
                    "${item.productName} (${item.selectedVariant.weight}gr)",
                  ),
                  subtitle: Text(
                    "${item.quantity} x ${currencyFormatter.format(item.selectedVariant.price)}",
                  ),
                  trailing: Text(
                    currencyFormatter.format(item.quantity * item.selectedVariant.price),
                  ),
                )),
            const Divider(height: 32),

            // Price Breakdown
            _buildPriceRow("Subtotal", subtotal, currencyFormatter),
            _buildPriceRow(
              "Ongkos Kirim",
              checkoutState.shippingCost,
              currencyFormatter,
            ),
            const Divider(),
            _buildPriceRow(
              "Total",
              finalTotal,
              currencyFormatter,
              isTotal: true,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isProcessingPayment
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  "Bayar ${currencyFormatter.format(finalTotal)}",
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount,
    NumberFormat formatter, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Theme.of(context).primaryColor : null,
            ),
          ),
        ],
      ),
    );
  }
}