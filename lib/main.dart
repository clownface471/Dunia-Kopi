import 'package:duniakopi_project/app/core/theme/app_theme.dart';
import 'package:duniakopi_project/app/presentation/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dunia Kopi',
      theme: AppTheme.vintageTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), 
    );
  }
}

