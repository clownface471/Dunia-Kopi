import 'package:duniakopi_project/app/presentation/screens/admin_orders_screen.dart';
import 'package:duniakopi_project/app/presentation/screens/admin_products_screen.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dasbor Admin"),
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(24.0),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            icon: Icons.coffee,
            label: "Manajemen Produk",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const AdminProductsScreen(),
              ));
            },
          ),
          _buildDashboardCard(
            context,
            icon: Icons.receipt_long,
            label: "Manajemen Pesanan",
            onTap: () {
               Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const AdminOrdersScreen(),
              ));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
