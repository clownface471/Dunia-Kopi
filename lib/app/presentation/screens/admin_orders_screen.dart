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
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dateFormatter.format(order.createdAt.toDate())),
                      Text("Status: ${order.status}", style: TextStyle(
                        color: order.status == 'Pending' ? Colors.orange : Colors.green,
                        fontWeight: FontWeight.bold,
                      )),
                    ],
                  ),
                  children: [
                    // Shipping Information
                    if (order.shippingAddress != null) ...[
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: const Text("Alamat Pengiriman", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.recipientName ?? '-'),
                            Text(order.recipientPhone ?? '-'),
                            Text(order.shippingAddress ?? '-'),
                          ],
                        ),
                      ),
                    ],
                    if (order.courierService != null) ...[
                      ListTile(
                        leading: const Icon(Icons.local_shipping_outlined),
                        title: const Text("Kurir", style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(order.courierService ?? '-'),
                        trailing: order.shippingCost != null 
                          ? Text(currencyFormatter.format(order.shippingCost))
                          : null,
                      ),
                    ],
                    const Divider(),
                    
                    // Order Items
                    ...order.items.map((item) => ListTile(
                          leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                          title: Text("${item.productName} (${item.selectedVariant.weight}gr)"),
                          subtitle: Text(currencyFormatter.format(item.selectedVariant.price)),
                          trailing: Text("x${item.quantity}"),
                        )),
                    
                    // Total
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            currencyFormatter.format(order.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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