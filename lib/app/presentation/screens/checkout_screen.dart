import 'dart:convert';
import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/data/services/order_service.dart';
import 'package:duniakopi_project/app/data/services/payment_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:duniakopi_project/app/presentation/screens/order_success_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;
  final String _backendUrl =
      "https://dunia-kopi-backend.vercel.app/create-transaction";
  final PaymentService _paymentService = PaymentService();

  Future<void> _processPayment() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                "Pembayaran saat ini hanya didukung di versi website.")),
      );
      return;
    }

    final userValue = ref.read(authStateProvider).value;
    final cartItems = ref.read(cartProvider).value ?? [];
    final totalPrice = ref.read(cartTotalPriceProvider);

    if (userValue == null || cartItems.isEmpty) return;
    final user = userValue;

    setState(() => _isLoading = true);

    try {
      final orderId = 'duniakopi-${DateTime.now().millisecondsSinceEpoch}';
      final String customerEmail = user.email ?? 'guest@duniakopi.com';
      final String customerName = user.displayName ?? customerEmail.split('@').first;

      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'orderId': orderId,
          'amount': totalPrice,
          'customerDetails': {
            'first_name': customerName,
            'email': customerEmail,
          },
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Gagal mendapatkan token transaksi: ${response.body}');
      }

      final responseBody = json.decode(response.body);
      final transactionToken = responseBody['token'];

      if (transactionToken == null) {
        throw Exception('Token transaksi tidak ditemukan.');
      }

      _paymentService.startMidtransPayment(transactionToken, (result) async {
        if (result == 'success' || result == 'pending') {
          await ref.read(orderServiceProvider).createOrder(
                userId: user.uid,
                items: cartItems,
                totalPrice: totalPrice,
              );
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
              (route) => route.isFirst,
            );
          }
        } else if (result == 'closed') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text("Anda menutup jendela pembayaran.")),
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider).value ?? [];
    final totalPrice = ref.watch(cartTotalPriceProvider);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ringkasan Pesanan",
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            ...cartItems.map((item) => ListTile(
                  leading: Image.network(item.imageUrl, width: 50),
                  title: Text(
                      "${item.productName} (${item.selectedVariant.weight}gr)"),
                  subtitle: Text(
                      "${item.quantity} x ${currencyFormatter.format(item.selectedVariant.price)}"),
                  trailing: Text(currencyFormatter
                      .format(item.quantity * item.selectedVariant.price)),
                )),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  currencyFormatter.format(totalPrice),
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Bayar Sekarang",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
      ),
    );
  }
}

