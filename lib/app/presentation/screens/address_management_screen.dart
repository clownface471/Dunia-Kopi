import 'package:duniakopi_project/app/data/services/address_service.dart';
import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/presentation/screens/add_edit_address_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final addressesProvider = StreamProvider.autoDispose((ref) {
  final userId = ref.watch(authStateProvider).value?.uid;
  if (userId != null) {
    return ref.watch(addressServiceProvider).getAddresses(userId);
  }
  return Stream.value([]);
});

class AddressManagementScreen extends ConsumerWidget {
  const AddressManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);
    final userId = ref.watch(authStateProvider).value?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Alamat"),
      ),
      body: addressesAsync.when(
        data: (addresses) {
          if (addresses.isEmpty) {
            return const Center(child: Text("Anda belum menambahkan alamat."));
          }
          return ListView.builder(
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final address = addresses[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${address.fullAddress}, ${address.city}, ${address.postalCode}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddEditAddressScreen(address: address),
                      ));
                    },
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AddEditAddressScreen(),
          ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
