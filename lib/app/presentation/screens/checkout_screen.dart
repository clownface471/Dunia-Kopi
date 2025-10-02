import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/data/services/order_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:duniakopi_project/app/presentation/screens/order_success_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _isLoading = false;

  Future<void> _processOrder() async {
    final userId = ref.read(authStateProvider).value?.uid;
    final cartItems = ref.read(cartProvider).value ?? [];
    final totalPrice = ref.read(cartTotalPriceProvider);

    if (userId != null && cartItems.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        await ref.read(orderServiceProvider).createOrder(
              userId: userId,
              items: cartItems,
              totalPrice: totalPrice,
            );
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
            (route) => route.isFirst,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal membuat pesanan: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
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
                onPressed: _processOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("Bayar Sekarang (Simulasi)",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
      ),
    );
  }
}

