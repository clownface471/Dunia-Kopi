import 'package:duniakopi_project/app/data/services/auth_service.dart';
import 'package:duniakopi_project/app/presentation/screens/login_screen.dart';
import 'package:duniakopi_project/app/presentation/screens/main_nav_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainNavScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => const Scaffold(body: Center(child: Text("Terjadi kesalahan."))),
    );
  }
}
