import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:duniakopi_project/app/data/models/user_model.dart';
import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DebugUserScreen extends ConsumerStatefulWidget {
  const DebugUserScreen({super.key});

  @override
  ConsumerState<DebugUserScreen> createState() => _DebugUserScreenState();
}

class _DebugUserScreenState extends ConsumerState<DebugUserScreen> {
  bool _isChecking = false;
  String _status = 'Belum diperiksa';
  bool _userDocExists = false;

  Future<void> _checkUserDocument() async {
    setState(() {
      _isChecking = true;
      _status = 'Memeriksa...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _status = 'User tidak login';
          _isChecking = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      setState(() {
        _userDocExists = doc.exists;
        if (doc.exists) {
          _status = '✅ User document ditemukan\n\nData: ${doc.data()}';
        } else {
          _status = '❌ User document TIDAK ditemukan di Firestore';
        }
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isChecking = false;
      });
    }
  }

  Future<void> _createUserDocument() async {
    setState(() => _isChecking = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User tidak login');
      }

      await ref.read(authServiceProvider).createUserDocument(user);

      setState(() {
        _status = '✅ User document berhasil dibuat!';
        _userDocExists = true;
        _isChecking = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User document berhasil dibuat! Silakan restart aplikasi.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error membuat document: $e';
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug User Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'User Debug Tool',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            userAsync.when(
              data: (user) {
                if (user == null) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Tidak ada user yang login'),
                    ),
                  );
                }
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Firebase Auth User:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('UID: ${user.uid}'),
                        Text('Email: ${user.email}'),
                        Text('Verified: ${user.emailVerified}'),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (e, st) => Text('Error: $e'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isChecking ? null : _checkUserDocument,
              child: _isChecking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Periksa Firestore Document'),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.grey.shade100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(_status),
              ),
            ),
            if (!_userDocExists && _status.contains('TIDAK ditemukan'))
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _createUserDocument,
                  icon: const Icon(Icons.build),
                  label: const Text('Perbaiki - Buat User Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            const Spacer(),
            const Divider(),
            const Text(
              'Langkah Manual:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Klik "Periksa Firestore Document"\n'
              '2. Jika tidak ditemukan, klik "Perbaiki"\n'
              '3. Logout dan login ulang',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}