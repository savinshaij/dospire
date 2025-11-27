import 'package:flutter/material.dart';
import '../app_theme.dart';

class DoSpireBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final IconData fabIcon;
  final VoidCallback onFabTap;

  const DoSpireBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.fabIcon,
    required this.onFabTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive padding based on width
          final isWide = constraints.maxWidth > 600;
          final horizontalPadding = isWide
              ? (constraints.maxWidth - 400) / 2
              : 24.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              0,
              horizontalPadding,
              20,
            ),
            child: SizedBox(
              height: 72, // Increased height for better touch targets
              child: Row(
                children: [
                  // Main Navigation Pill
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.navBackground,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _NavItem(
                            icon: Icons.home_rounded,
                            label: "Home",
                            isSelected: currentIndex == 0,
                            onTap: () => onChanged(0),
                          ),
                          _NavItem(
                            icon: Icons.calendar_month_rounded,
                            label: "Calendar",
                            isSelected: currentIndex == 1,
                            onTap: () => onChanged(1),
                          ),
                          _NavItem(
                            icon: Icons.sticky_note_2_rounded,
                            label: "Notes",
                            isSelected: currentIndex == 2,
                            onTap: () => onChanged(2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 20), // Increased spacing
                  // Floating Action Button
                  _AnimatedFab(icon: fabIcon, onTap: onFabTap),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Semantics added for accessibility (Screen readers)
    return Semantics(
      selected: isSelected,
      label: label,
      button: true,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          // Customizing splash color for better visibility on black
          splashColor: AppColors.navSelectedIcon.withValues(alpha: 0.2),
          highlightColor: AppColors.navSelectedIcon.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutQuint,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.navSelectedIcon
                    : AppColors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                // Animating color transition
                color: isSelected
                    ? AppColors.navBackground
                    : AppColors.navUnselectedIcon.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedFab extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedFab({required this.icon, required this.onTap});

  @override
  State<_AnimatedFab> createState() => _AnimatedFabState();
}

class _AnimatedFabState extends State<_AnimatedFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppColors.navBackground,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        // Material & InkWell strictly for the Ripple Effect
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: () {}, // Handled in TapUp for better animation sync
            customBorder: const CircleBorder(),
            splashColor: AppColors.navSelectedIcon.withValues(alpha: 0.2),
            child: Icon(
              widget.icon,
              color: AppColors.navSelectedIcon,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
