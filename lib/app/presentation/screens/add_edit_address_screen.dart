import 'package:duniakopi_project/app/data/models/address_model.dart';
import 'package:duniakopi_project/app/data/models/rajaongkir_model.dart';
import 'package:duniakopi_project/app/data/services/address_service.dart';
import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/data/services/rajaongkir_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEditAddressScreen extends ConsumerStatefulWidget {
  final AddressModel? address;
  const AddEditAddressScreen({super.key, this.address});

  @override
  ConsumerState<AddEditAddressScreen> createState() =>
      _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends ConsumerState<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  Province? _selectedProvince;
  City? _selectedCity;
  
  bool _isLoading = false;
  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _recipientController.text = widget.address!.recipientName;
      _phoneController.text = widget.address!.phoneNumber.startsWith('+62')
          ? widget.address!.phoneNumber.substring(3)
          : widget.address!.phoneNumber;
      _addressController.text = widget.address!.fullAddress;
      _postalCodeController.text = widget.address!.postalCode;
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final userId = ref.read(authStateProvider).value?.uid;
      if (userId == null) return;

      final newAddress = AddressModel(
        id: _isEditing ? widget.address!.id : null,
        recipientName: _recipientController.text,
        phoneNumber: '+62${_phoneController.text}',
        fullAddress: _addressController.text,
        city: _selectedCity!.cityName,
        cityId: _selectedCity!.cityId, // NEW: Save city ID
        province: _selectedProvince!.provinceName,
        provinceId: _selectedProvince!.provinceId, // NEW: Save province ID
        postalCode: _postalCodeController.text,
      );

      try {
        final addressService = ref.read(addressServiceProvider);
        if (_isEditing) {
          await addressService.updateAddress(userId, newAddress);
        } else {
          await addressService.addAddress(userId, newAddress);
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal menyimpan alamat: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provincesAsync = ref.watch(provincesProvider);
    final citiesAsync = _selectedProvince != null
        ? ref.watch(citiesProvider(_selectedProvince!.provinceId))
        : null;

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? "Edit Alamat" : "Tambah Alamat Baru")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _recipientController,
                label: "Nama Penerima",
              ),
              _buildTextField(
                controller: _phoneController,
                label: "Nomor Telepon",
                prefix: "+62 ",
                keyboardType: TextInputType.phone,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _buildTextField(
                controller: _addressController,
                label: "Alamat Lengkap (Nama Jalan, No. Rumah, dll)",
                maxLines: 3,
              ),

              provincesAsync.when(
                data: (provinces) => _buildDropdown<Province>(
                  label: "Provinsi",
                  value: _selectedProvince,
                  items: provinces,
                  onChanged: (province) {
                    setState(() {
                      _selectedProvince = province;
                      _selectedCity = null;
                    });
                  },
                  itemAsString: (province) => province.provinceName,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Text('Gagal memuat provinsi: $e'),
              ),
              
              _buildDropdown<City>(
                label: "Kota/Kabupaten",
                value: _selectedCity,
                items: citiesAsync?.value ?? [],
                onChanged: _selectedProvince == null ? null : (city) {
                  setState(() => _selectedCity = city);
                },
                itemAsString: (city) => city.cityName,
              ),

              _buildTextField(
                controller: _postalCodeController,
                label: "Kode Pos",
                keyboardType: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16)
                      ),
                      child: const Text("Simpan Alamat"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    int? maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        maxLines: maxLines,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        validator: (val) => val!.isEmpty ? '$label tidak boleh kosong' : null,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    T? value,
    required List<T> items,
    required void Function(T?)? onChanged,
    required String Function(T) itemAsString,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(itemAsString(item)),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: (val) => val == null ? '$label harus dipilih' : null,
        isExpanded: true,
        disabledHint: Text(label == "Kota/Kabupaten" ? 'Pilih provinsi dulu' : 'Memuat...'),
      ),
    );
  }
}