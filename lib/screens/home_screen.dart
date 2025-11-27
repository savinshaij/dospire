import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../screens/profile_screen.dart';
import '../services/remote_config_service.dart';
import '../state/app_state.dart';
import '../widgets/announcement_dialog.dart';
import '../widgets/empty_state.dart';

import '../app_theme.dart';
import '../utils/responsive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  Timer? _greetingTimer;
  String _currentGreeting = "";

  // For delayed sorting
  final Set<String> _recentlyCompleted = {};

  // For counting animation
  int _previousPercentage = 0;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateGreeting();
    // Update greeting every minute
    _greetingTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _updateGreeting();
    });

    // Check for announcements after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAnnouncement();
    });
  }

  Future<void> _checkAnnouncement() async {
    final remoteConfig = RemoteConfigService.instance;

    // 1. Check if enabled
    if (!remoteConfig.isAnnouncementEnabled) return;

    // 2. Check if already seen
    final prefs = await SharedPreferences.getInstance();
    final seenId = prefs.getString('seen_announcement_id');
    final currentId = remoteConfig.announcementId;

    if (seenId == currentId) return;

    if (!mounted) return;

    // 3. Show Dialog
    showDialog(
      context: context,
      builder: (context) => AnnouncementDialog(
        title: remoteConfig.announcementTitle,
        body: remoteConfig.announcementBody,
        imageUrl: remoteConfig.announcementImageUrl,
        linkUrl: remoteConfig.announcementLink,
        onDismiss: () async {
          Navigator.of(context).pop();
          await prefs.setString('seen_announcement_id', currentId);
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateGreeting();
      // Refresh data when app resumes
      context.read<AppState>().refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _greetingTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    String newGreeting;
    if (hour >= 0 && hour < 2) {
      newGreeting = "Happy Midnight,";
    } else if (hour < 12) {
      newGreeting = "Good Morning,";
    } else if (hour < 17) {
      newGreeting = "Good Afternoon,";
    } else {
      newGreeting = "Good Evening,";
    }

    if (_currentGreeting != newGreeting) {
      if (mounted) {
        setState(() {
          _currentGreeting = newGreeting;
        });
      }
    }
  }

  // Helper to get ID
  String _getId(dynamic item) {
    if (item is Task) return item.taskId;
    if (item is Hobby) return item.hobbyId;
    return '';
  }

  // Helper to get Color
  Color _getColor(dynamic item) {
    if (item is Task) return item.color;
    if (item is Hobby) return item.color ?? AppColors.pastels[0];
    return AppColors.pastels[0];
  }

  // Sorting Logic: Pending First, Then by Time
  List<dynamic> _getSortedItems(List<Task> tasks, List<Hobby> hobbies) {
    final today = DateTime.now();
    final todaysTasks = tasks
        .where(
          (t) =>
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day,
        )
        .toList();

    final todaysHobbies = hobbies
        .where(
          (h) =>
              h.periodStart.isBefore(today.add(const Duration(days: 1))) &&
              h.periodEnd.isAfter(today.subtract(const Duration(days: 1))),
        )
        .toList();

    final allItems = [...todaysTasks, ...todaysHobbies];

    allItems.sort((a, b) {
      final aId = _getId(a);
      final bId = _getId(b);

      final aRealDone = (a is Task && a.isDone) || (a is Hobby && a.isDone);
      final bRealDone = (b is Task && b.isDone) || (b is Hobby && b.isDone);

      final aSortDone = aRealDone && !_recentlyCompleted.contains(aId);
      final bSortDone = bRealDone && !_recentlyCompleted.contains(bId);

      // 1. Completion Status (Active first)
      if (aSortDone != bSortDone) return aSortDone ? 1 : -1;

      // 2. Type (Task before Hobby)
      if (a is Hobby && b is Task) return 1;
      if (a is Task && b is Hobby) return -1;

      // 3. Time
      if (a is Task && b is Task) {
        return (a.time.hour * 60 + a.time.minute).compareTo(
          b.time.hour * 60 + b.time.minute,
        );
      }
      return 0;
    });

    return allItems;
  }

  void _handleItemToggle(dynamic item) {
    final state = context.read<AppState>();
    final id = _getId(item);
    final isDone = item is Task
        ? item.isDone
        : (item is Hobby ? item.isDone : false);

    if (!isDone) {
      // Marking as DONE
      setState(() {
        _recentlyCompleted.add(id);
      });

      // Toggle state immediately
      if (item is Task) {
        state.toggleTask(item.taskId);
      } else if (item is Hobby) {
        state.toggleHobby(item.hobbyId);
      }

      // Wait 2 seconds then re-sort
      Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _recentlyCompleted.remove(id);
          });
        }
      });
    } else {
      // Marking as not done (immediate)
      if (item is Task) {
        state.toggleTask(item.taskId);
      } else if (item is Hobby) {
        state.toggleHobby(item.hobbyId);
      }
    }
  }

  Widget _buildItem(dynamic item) {
    final id = _getId(item);
    final color = _getColor(item);
    return _PastelTaskCard(
      key: ValueKey(id),
      item: item,
      bgColor: color,
      onTap: () => _handleItemToggle(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, _HomeData>(
      selector: (_, state) => _HomeData(
        isReady: state.isReady,
        profile: state.profile,
        tasks: state.tasks,
        hobbies: state.hobbies,
      ),
      builder: (context, data, _) {
        final theme = Theme.of(context);

        if (!data.isReady) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(
              child: CircularProgressIndicator(
                color: AppColors.dashboardBackground,
              ),
            ),
          );
        }

        final today = DateTime.now();
        final name = data.profile?.name ?? 'User';

        // Calculate stats for dashboard
        final todaysTasks = data.tasks
            .where(
              (t) =>
                  t.date.year == today.year &&
                  t.date.month == today.month &&
                  t.date.day == today.day,
            )
            .toList();
        final todaysHobbies = data.hobbies
            .where(
              (h) =>
                  h.periodStart.isBefore(today.add(const Duration(days: 1))) &&
                  h.periodEnd.isAfter(today.subtract(const Duration(days: 1))),
            )
            .toList();

        final totalItems = todaysTasks.length + todaysHobbies.length;
        final doneTasks = todaysTasks.where((t) => t.isDone).length;
        final doneHobbies = todaysHobbies.where((h) => h.isDone).length;
        final totalDone = doneTasks + doneHobbies;
        final remaining = totalItems - totalDone;

        final double rawPct = totalItems == 0
            ? 1.0
            : (totalDone / totalItems).clamp(0.0, 1.0);
        final int percentage = (rawPct * 100).round();

        // Handle Animation State
        if (_isFirstLoad) {
          _previousPercentage = percentage;
          _isFirstLoad = false;
        }

        // Get sorted items
        final sortedItems = _getSortedItems(data.tasks, data.hobbies);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // 1. Header
                      SliverPadding(
                        padding: EdgeInsets.only(
                          top: MediaQuery.of(context).padding.top + ResponsiveSize.lg,
                          left: ResponsiveSize.xl,
                          right: ResponsiveSize.xl,
                          bottom: ResponsiveSize.xl,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _SimpleHeader(
                            name: name,
                            greeting: _currentGreeting,
                          ),
                        ),
                      ),

                      // 2. Dashboard
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: ResponsiveSize.xl),
                        sliver: SliverToBoxAdapter(
                          child: _DarkDashboard(
                            percentage: percentage,
                            previousPercentage: _previousPercentage,
                            totalTasks: totalItems,
                            remaining: remaining,
                            onAnimationEnd: () {
                              Future.microtask(() {
                                if (mounted &&
                                    _previousPercentage != percentage) {
                                  _previousPercentage = percentage;
                                }
                              });
                            },
                          ),
                        ),
                      ),

                      // 3. Title
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          ResponsiveSize.xl,
                          ResponsiveSize.xxl,
                          ResponsiveSize.xl,
                          ResponsiveSize.lg,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            "Today's Plan",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // 4. LIST (Simplified)
                      sortedItems.isEmpty
                          ? const SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyState(
                                title: 'Ready for Takeoff!',
                                message:
                                    'Your day awaits. Add your first task!',
                                icon: Icons.rocket_launch,
                              ),
                            )
                          : SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                ResponsiveSize.xl,
                                0,
                                ResponsiveSize.xl,
                                ResponsiveSize.xxl * 3,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  final item = sortedItems[index];
                                  return _buildItem(item);
                                }, childCount: sortedItems.length),
                              ),
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _HomeData {
  const _HomeData({
    required this.isReady,
    required this.profile,
    required this.tasks,
    required this.hobbies,
  });

  final bool isReady;
  final UserProfile? profile;
  final List<Task> tasks;
  final List<Hobby> hobbies;
}

class _SimpleHeader extends StatelessWidget {
  final String name;
  final String greeting;

  const _SimpleHeader({
    required this.name,
    required this.greeting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              greeting,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -6),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary, // Uber Black
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.cardColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? AppColors.white.withValues(alpha: 0.24)
                    : AppColors.border,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.onSurface,
              size: 26,
            ),
          ),
        ),
      ],
    );
  }
}

// --- 2. DASHBOARD (With Counting Animation) ---
class _DarkDashboard extends StatelessWidget {
  final int percentage;
  final int previousPercentage;
  final int totalTasks;
  final int remaining;
  final VoidCallback? onAnimationEnd;

  const _DarkDashboard({
    required this.percentage,
    required this.previousPercentage,
    required this.totalTasks,
    required this.remaining,
    this.onAnimationEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
      decoration: BoxDecoration(
        color: AppColors.textPrimary, // Uber Black
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.2),
            offset: const Offset(0, 10),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Daily Progress",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: previousPercentage, end: percentage),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeOutExpo,
                    onEnd: onAnimationEnd,
                    builder: (context, value, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "$value",
                            style: const TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textInverse,
                              height: 1.0,
                              letterSpacing: -2.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "%",
                            style: TextStyle(
                              fontSize: 24,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 8,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: percentage / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppPalette.neoGreen,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppPalette.neoGreen.withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 32),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatRow(
                  icon: Icons.calendar_today,
                  label: "Total",
                  value: "$totalTasks",
                ),
                const SizedBox(height: 24),
                _StatRow(
                  icon: Icons.pending_outlined,
                  label: "Left",
                  value: "$remaining",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textInverse,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PastelTaskCard extends StatelessWidget {
  final dynamic item;
  final Color bgColor;
  final VoidCallback onTap;

  const _PastelTaskCard({
    super.key,
    required this.item,
    required this.bgColor,
    required this.onTap,
  });

  bool get isTask => item is Task;
  bool get isHobby => item is Hobby;

  bool get isDone {
    if (item is Task) return (item as Task).isDone;
    if (item is Hobby) return (item as Hobby).isDone;
    return false;
  }

  String get title {
    if (item is Task) return (item as Task).title;
    if (item is Hobby) return (item as Hobby).title;
    return 'Untitled';
  }

  String get subtitle {
    if (item is Task) return (item as Task).details ?? "";
    if (item is Hobby) return (item as Hobby).category;
    return "";
  }

  String get typeLabel {
    if (item is Task) return "TASK";
    if (item is Hobby) return "HABIT";
    return "ITEM";
  }

  Map<String, String> get timeData {
    if (item is Task) {
      final t = (item as Task).time;
      final dt = DateTime(2024, 1, 1, t.hour, t.minute);
      return {
        'time': DateFormat('h:mm').format(dt),
        'period': DateFormat('a').format(dt),
      };
    }
    return {'time': '--', 'period': ''};
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    final mainColor = isDone ? const Color(0xFFF5F5F5) : bgColor;
    // For active state, left side is lighter.
    final leftColor = isDone
        ? const Color(0xFFF5F5F5)
        : (Color.lerp(bgColor, Colors.white, 0.4) ?? bgColor);

    final textColor = isDone ? AppColors.textSecondary : AppColors.textPrimary;
    final borderColor = isDone ? AppPalette.grey : Colors.black;

    final semanticsLabel = StringBuffer()
      ..write('$typeLabel: $title')
      ..write(isDone ? ', completed' : ', pending');
    if (isTask) {
      semanticsLabel.write(
        ', scheduled at ${timeData['time']} ${timeData['period']}',
      );
    }

    return Semantics(
      label: semanticsLabel.toString(),
      button: true,
      onTapHint: isDone ? 'Mark as incomplete' : 'Mark as complete',
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: mainColor,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 2),
          ),
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.black.withValues(alpha: 0.05),
            highlightColor: Colors.black.withValues(alpha: 0.02),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- LEFT SIDE (Icon/Time) ---
                  Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: leftColor,
                    ),
                    child: Center(
                      child: item is Task
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  timeData['time']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: textColor,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  timeData['period']!,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            )
                          : Icon(Icons.eco_outlined, size: 24, color: textColor),
                    ),
                  ),

                  // --- RIGHT SIDE (Content) ---
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    decoration: isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textColor.withValues(alpha: 0.6),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // --- TAG ---
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // --- CHECKBOX ---
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: isDone ? Colors.black : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: borderColor,
                                width: 2,
                              ),
                            ),
                            child: isDone
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
