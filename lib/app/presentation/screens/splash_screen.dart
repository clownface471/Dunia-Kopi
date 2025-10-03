import 'dart:async';
import 'package:duniakopi_project/app/presentation/screens/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isVisible = true;
        });
      }
    });
    _navigateToHome();
  }

  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 4), () {});
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
            top: _isVisible ? screenHeight * 0.35 : screenHeight * 0.5,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1500),
              opacity: _isVisible ? 1.0 : 0.0,
              child: Icon(
                Icons.coffee,
                size: 100,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          
          AnimatedPositioned(
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeInOut,
            top: screenHeight * 0.5,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 1500),
              opacity: _isVisible ? 1.0 : 0.0,
              child: Text(
                "Dunia Kopi",
                style: GoogleFonts.dancingScript(
                  fontSize: 60,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}