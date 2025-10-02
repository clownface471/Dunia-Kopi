import 'package:duniakopi_project/app/data/models/cart_item_model.dart';
import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class CartListItem extends ConsumerWidget {
  final CartItemModel cartItem;
  const CartListItem({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final userId = ref.watch(authStateProvider).value?.uid;
    final cartService = ref.read(cartServiceProvider);

    return Dismissible(
      key: ValueKey(cartItem.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        if (userId != null) {
          cartService.removeItem(userId, cartItem.id);
        }
      },
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    cartItem.imageUrl, 
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      return progress == null ? child : const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.image_not_supported);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cartItem.productName, 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('${cartItem.selectedVariant.weight}gr'),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(cartItem.selectedVariant.price),
                      style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: userId == null ? null : () {
                      cartService.updateQuantity(userId, cartItem.id, cartItem.quantity - 1);
                    },
                  ),
                  Text(cartItem.quantity.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: userId == null ? null : () {
                      cartService.updateQuantity(userId, cartItem.id, cartItem.quantity + 1);
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

