import 'package:duniakopi_project/app/data/models/product_model.dart';
import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/presentation/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductVariant? _selectedVariant;
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    if (widget.product.variants.isNotEmpty) {
      _selectedVariant = widget.product.variants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = ref.watch(userRoleProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Hero(
                tag: 'product_image_${widget.product.id}',
                child: Image.network(
                  widget.product.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontFamily: 'DancingScript',
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currencyFormatter.format(_selectedVariant?.price ?? 0),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontFamily: 'RobotoSlab',
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Pilih Varian",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    children: widget.product.variants.map((variant) {
                      final isSelected = _selectedVariant == variant;
                      return ChoiceChip(
                        label: Text('${variant.weight}gr'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedVariant = variant;
                            });
                          }
                        },
                        selectedColor: Theme.of(context).primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                        backgroundColor: Colors.grey.shade200,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoRow(context, Icons.public_outlined, "Asal",
                      widget.product.origin),
                  _buildInfoRow(context, Icons.whatshot_outlined, "Roasting",
                      widget.product.roastLevel),
                  _buildInfoRow(context, Icons.coffee_maker_outlined,
                      "Profil Rasa", widget.product.tastingNotes),
                  const SizedBox(height: 16),
                  Text(
                    widget.product.description.isNotEmpty
                        ? widget.product.description
                        : "Deskripsi produk belum tersedia.",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: userRole != 'admin'
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon:
                    const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                label: const Text("Tambah ke Keranjang"),
                onPressed: () {
                  final userId = ref.read(authStateProvider).value?.uid;
                  if (userId != null && _selectedVariant != null) {
                    ref.read(cartServiceProvider).addItem(
                        userId, widget.product, _selectedVariant!);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${widget.product.name} (${_selectedVariant!.weight}gr) ditambahkan ke keranjang.'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  } else if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Silakan login terlebih dahulu.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Silakan pilih varian terlebih dahulu.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          const SizedBox(width: 16),
          Text("$label: ",
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "N/A",
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

