import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../state/app_state.dart';
import 'app_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Wait for minimum splash duration
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final state = context.read<AppState>();

    // Wait for hydration if not ready
    if (!state.isReady) {
      // Simple polling for simplicity, or could use a listener
      int retries = 0;
      while (!state.isReady && retries < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
    }

    if (!mounted) return;

    // Navigate based on profile existence
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            state.profile == null ? const OnboardingScreen() : const AppShell(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Simple text-only splash
            Text(
              'DoSpire',
              style: AppTextStyles.display.copyWith(
                color: AppColors.textPrimary,
                fontSize: 48,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
