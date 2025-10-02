import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duniakopi_project/app/data/models/address_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddressService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<AddressModel> _addressCollection(String userId) {
    return _db.collection('users').doc(userId).collection('addresses').withConverter<AddressModel>(
          fromFirestore: (snapshot, _) => AddressModel.fromFirestore(snapshot),
          toFirestore: (address, _) => address.toMap(),
        );
  }

  Stream<List<AddressModel>> getAddresses(String userId) {
    return _addressCollection(userId).snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> addAddress(String userId, AddressModel address) {
    return _addressCollection(userId).add(address);
  }

  Future<void> updateAddress(String userId, AddressModel address) {
    return _addressCollection(userId).doc(address.id).update(address.toMap());
  }

  Future<void> deleteAddress(String userId, String addressId) {
    return _addressCollection(userId).doc(addressId).delete();
  }
}

final addressServiceProvider = Provider<AddressService>((ref) => AddressService());
