import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/data/services/firestore_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:duniakopi_project/app/presentation/screens/cart_screen.dart';
import 'package:duniakopi_project/app/presentation/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsyncValue = ref.watch(productsProvider);
    final totalCartItems = ref.watch(cartTotalItemsProvider);
    final userRole = ref.watch(userRoleProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dunia Kopi"),
        centerTitle: true,
        actions: [
          if (userRole != 'admin')
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CartScreen()),
                    );
                  },
                ),
                if (totalCartItems > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$totalCartItems',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            )
        ],
      ),
      body: productsAsyncValue.when(
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text("Produk akan segera hadir."));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(product: product);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Terjadi kesalahan: $err")),
      ),
    );
  }
}

