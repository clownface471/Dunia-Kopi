import 'package:duniakopi_project/app/core/theme/app_colors.dart';
import 'package:duniakopi_project/app/core/utils/currency_input_formatter.dart';
import 'package:duniakopi_project/app/data/models/product_model.dart';
import 'package:duniakopi_project/app/data/services/firestore_service.dart';
import 'package:duniakopi_project/app/data/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AddEditProductScreen extends ConsumerStatefulWidget {
  final ProductModel? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  ConsumerState<AddEditProductScreen> createState() =>
      _AddEditProductScreenState();
}

class _AddEditProductScreenState extends ConsumerState<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _originController = TextEditingController();
  final _roastLevelController = TextEditingController();
  final _tastingNotesController = TextEditingController();
  final _stockController = TextEditingController();

  final _variantWeightController = TextEditingController();
  final _variantPriceController = TextEditingController();
  final List<ProductVariant> _variants = [];

  bool get _isEditing => widget.product != null;

  Uint8List? _selectedImageBytes;
  String? _networkImageUrl;
  bool _isUploading = false;

  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _originController.text = widget.product!.origin;
      _roastLevelController.text = widget.product!.roastLevel;
      _tastingNotesController.text = widget.product!.tastingNotes;
      _stockController.text = widget.product!.stock.toString();
      _networkImageUrl = widget.product!.imageUrl;
      setState(() {
        _variants.addAll(widget.product!.variants);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _originController.dispose();
    _roastLevelController.dispose();
    _tastingNotesController.dispose();
    _stockController.dispose();
    _variantWeightController.dispose();
    _variantPriceController.dispose();
    super.dispose();
  }

  void _addVariant() {
    if (_variantWeightController.text.isNotEmpty &&
        _variantPriceController.text.isNotEmpty) {
      final String priceText = _variantPriceController.text.replaceAll('.', '');
      setState(() {
        _variants.add(ProductVariant(
          weight: _variantWeightController.text,
          price: int.parse(priceText),
        ));
      });
      _variantWeightController.clear();
      _variantPriceController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _pickAndUploadImage() async {
    final imageService = ref.read(imageServiceProvider);
    final imageFile = await imageService.pickImage();

    if (imageFile != null) {
      final imageBytes = await imageFile.readAsBytes();
      setState(() {
        _selectedImageBytes = imageBytes;
        _isUploading = true;
      });

      final imageUrl = await imageService.uploadImage(imageFile);
      if (imageUrl != null) {
        setState(() {
          _networkImageUrl = imageUrl;
          _isUploading = false;
        });
      } else {
        setState(() {
          _isUploading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Gagal mengunggah gambar.")),
          );
        }
      }
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_variants.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tambahkan minimal satu varian harga.")),
        );
        return;
      }

      if (_networkImageUrl == null || _networkImageUrl!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Harap unggah gambar produk.")),
        );
        return;
      }

      final productData = ProductModel(
        id: _isEditing ? widget.product!.id : null,
        name: _nameController.text,
        origin: _originController.text,
        roastLevel: _roastLevelController.text,
        tastingNotes: _tastingNotesController.text,
        stock: int.tryParse(_stockController.text) ?? 0,
        imageUrl: _networkImageUrl!,
        variants: _variants,
      );

      try {
        if (_isEditing) {
          await ref.read(firestoreServiceProvider).updateProduct(productData);
        } else {
          await ref.read(firestoreServiceProvider).addProduct(productData);
        }
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menyimpan produk: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? "Edit Produk" : "Tambah Produk Baru"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                onTap: _pickAndUploadImage,
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.primary.withAlpha(128)),
                      image: _selectedImageBytes != null
                          ? DecorationImage(
                              image: MemoryImage(_selectedImageBytes!),
                              fit: BoxFit.cover,
                            )
                          : (_networkImageUrl != null &&
                                  _networkImageUrl!.isNotEmpty)
                              ? DecorationImage(
                                  image: NetworkImage(_networkImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : (_networkImageUrl == null ||
                                _networkImageUrl!.isEmpty)
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 40),
                                    SizedBox(height: 8),
                                    Text("Unggah Gambar Produk"),
                                  ],
                                ),
                              )
                            : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Nama Kopi"),
                validator: (value) =>
                    value!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originController,
                decoration: const InputDecoration(labelText: "Asal (Origin)"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roastLevelController,
                decoration: const InputDecoration(labelText: "Tingkat Roasting"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tastingNotesController,
                decoration:
                    const InputDecoration(labelText: "Profil Rasa (Tasting Notes)"),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: "Stok Awal"),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) =>
                    value!.isEmpty ? 'Stok tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              Divider(color: AppColors.primary.withAlpha(128)),
              const SizedBox(height: 16),
              Text("Varian Harga", style: Theme.of(context).textTheme.titleLarge),
              ..._variants.map((variant) => ListTile(
                    title: Text("${variant.weight}gr - ${_currencyFormatter.format(variant.price)}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => setState(() => _variants.remove(variant)),
                    ),
                  )),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _variantWeightController,
                      decoration: const InputDecoration(
                        labelText: "Berat",
                        suffixText: "gr",
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _variantPriceController,
                      decoration: const InputDecoration(
                          labelText: "Harga",
                          prefixText: "Rp "),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Tambah Varian"),
                onPressed: _addVariant,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  side: BorderSide(color: Theme.of(context).primaryColor),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isEditing ? "Simpan Perubahan" : "Simpan Produk",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

