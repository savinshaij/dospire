import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../state/app_state.dart';
import 'app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();

  // Start at age 18 by default
  int _selectedAge = 18;
  late PageController _ageController;

  @override
  void initState() {
    super.initState();
    // viewportFraction 0.33 allows us to see the neighbors clearly
    _ageController = PageController(
      initialPage: _selectedAge,
      viewportFraction: 0.33,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _finish() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      // Haptic feedback for success
      HapticFeedback.mediumImpact();
      context.read<AppState>().completeOnboarding(
        name: name,
        age: _selectedAge,
      );
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
    } else {
      // Simple error feedback (shake or snackbar could be added here)
      HapticFeedback.vibrate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32), // More rounded/modern
          border: Border.all(color: Colors.black, width: 3), // Bold border
          boxShadow: const [
            // Hard shadow for "Pop" effect
            BoxShadow(color: Colors.black, offset: Offset(8, 8), blurRadius: 0),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Header ---
            const Text(
              'Who are you?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.black,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Let's personalize your experience.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),

            // --- Name Input ---
            const Text(
              "YOUR NAME",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            _ModernTextField(controller: _nameController),

            const SizedBox(height: 24),

            // --- Age Selector ---
            const Text(
              "YOUR AGE",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: Stack(
                children: [
                  // The Selector Highlight Box
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent, width: 3),
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.accent.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  // The Scrolling Numbers
                  PageView.builder(
                    controller: _ageController,
                    onPageChanged: (index) {
                      setState(() => _selectedAge = index);
                      HapticFeedback.selectionClick();
                    },
                    itemBuilder: (context, index) {
                      // Calculate scale/opacity based on distance from center
                      // This part requires an AnimatedBuilder for perfect smoothness
                      // but basic implementation works well with PageView physics.
                      final isSelected = _selectedAge == index;

                      return Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: isSelected ? 32 : 18,
                            fontWeight: isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isSelected ? Colors.black : Colors.grey[400],
                          ),
                          child: Text("$index"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- Action Button ---
            _BouncyButton(onTap: _finish, label: 'Start Journey'),
          ],
        ),
      ),
    );
  }
}

// --- Helper Widgets for Clean Code ---

class _ModernTextField extends StatelessWidget {
  final TextEditingController controller;

  const _ModernTextField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Enter name...",
          hintStyle: TextStyle(color: Colors.grey),
          icon: Icon(Icons.person_outline_rounded, color: Colors.black),
        ),
      ),
    );
  }
}

class _BouncyButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _BouncyButton({required this.onTap, required this.label});

  @override
  State<_BouncyButton> createState() => _BouncyButtonState();
}

class _BouncyButtonState extends State<_BouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          height: 64, // Big height
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: const Offset(0, 4),
                blurRadius: 10,
              ),
            ],
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}
