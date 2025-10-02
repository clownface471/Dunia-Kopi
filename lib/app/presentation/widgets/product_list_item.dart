import 'package:duniakopi_project/app/data/models/product_model.dart';
import 'package:duniakopi_project/app/data/services/firestore_service.dart';
import 'package:duniakopi_project/app/presentation/screens/add_edit_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductListItem extends ConsumerWidget {
  final ProductModel product;

  const ProductListItem({super.key, required this.product});

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Hapus Produk",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: Text(
            "Apakah Anda yakin ingin menghapus produk '${product.name}'? Tindakan ini tidak dapat dibatalkan.",
          ),
          actions: [
            TextButton(
              child: const Text("Batal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                "Ya, Hapus",
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                try {
                  await ref
                      .read(firestoreServiceProvider)
                      .deleteProduct(product.id!);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal menghapus produk: $e")),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstVariant = product.variants.isNotEmpty
        ? product.variants.first
        : ProductVariant(weight: 'N/A', price: 0);

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              image: product.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(product.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: product.imageUrl.isEmpty
                ? Icon(
                    Icons.coffee,
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  )
                : null,
          ),
        ),
        title: Text(
          product.name,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontFamily: 'RobotoSlab',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          "Rp ${firstVariant.price} / ${firstVariant.weight}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.edit,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEditProductScreen(product: product),
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red.shade300),
              onPressed: () => _showDeleteDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}
