import 'package:duniakopi_project/app/data/services/order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsyncValue = ref.watch(ordersProvider);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFormatter = DateFormat('d MMM yyyy, HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text("Manajemen Pesanan")),
      body: ordersAsyncValue.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text("Belum ada pesanan masuk."));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  title: Text("Order #${order.id.substring(0, 6).toUpperCase()}"),
                  subtitle: Text(dateFormatter.format(order.createdAt.toDate())),
                  children: [
                    ...order.items.map((item) => ListTile(
                          title: Text("${item.productName} (${item.selectedVariant.weight}gr)"),
                          trailing: Text("x${item.quantity}"),
                        )),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total", style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            currencyFormatter.format(order.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
    );
  }
}
