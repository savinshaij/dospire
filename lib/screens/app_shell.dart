import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Ensure these imports match your actual file structure
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/responsive.dart';
import '../widgets/dospire_bottom_nav.dart';
import '../widgets/onboarding_dialog.dart';
import '../widgets/quick_add_sheet.dart';
import 'home_screen.dart';
import 'notes_screen.dart';
import 'note_composer_page.dart';
import 'plans_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _onboardingShown = false;
  late final PageController _pageController;

  final _pages = const [HomeScreen(), PlansScreen(), NotesScreen()];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowOnboarding();
  }

  Future<void> _maybeShowOnboarding() async {
    if (_onboardingShown) return;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    final appState = context.read<AppState>();
    if (appState.profile != null) return;
    _onboardingShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const OnboardingDialog(),
    );
  }

  void _onNavChanged(int index) {
    final int distance = (index - _index).abs();
    setState(() => _index = index);

    // If tabs are not adjacent (e.g. Home <-> Notes), jump instantly
    // to avoid scrolling through intermediate screens.
    if (distance > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _index = index);
  }

  // --- Dynamic FAB Logic ---

  // 1. Get the correct icon based on the current tab
  IconData get _currentFabIcon {
    switch (_index) {
      case 1: // Plans Tab
        return Icons.category;
      case 2: // Notes Tab
        return Icons.edit_note;
      case 0: // Home Tab
      default:
        return Icons.add;
    }
  }

  // 2. Handle the tap based on the current tab
  void _handleFabTap() {
    switch (_index) {
      case 2: // Notes -> Open Full Composer
        _openNoteComposer();
        break;
      case 0: // Home -> Quick Add
      case 1: // Plans -> Quick Add
      default:
        _openQuickAdd();
        break;
    }
  }

  // --- Actions ---

  void _openQuickAdd() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const QuickAddSheet(),
    );
  }

  void _openNoteComposer([Note? note]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => NoteComposerPage(note: note)));
  }

  @override
  Widget build(BuildContext context) {
    // Initialize responsive sizing for consistent scaling across device sizes
    ResponsiveSize.init(context);

    return Scaffold(
      extendBody:
          true, // Important for transparent backgrounds if you have them
      // Standard Body Switcher
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: _pages,
      ),

      // Custom Bottom Navigation containing the Split-Pill Design
      bottomNavigationBar: DoSpireBottomNav(
        currentIndex: _index,
        onChanged: _onNavChanged,
        fabIcon: _currentFabIcon, // Pass dynamic icon
        onFabTap: _handleFabTap, // Pass dynamic action
      ),
    );
  }
}
