import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../widgets/empty_state.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlanCollections {
  const _PlanCollections({
    required this.tasks,
    required this.hobbies,
  });

  final List<Task> tasks;
  final List<Hobby> hobbies;
}

class _PlansScreenState extends State<PlansScreen> {
  late DateTime _selectedDate;
  late PageController _datePageController;
  String _filter = 'all'; // 'all', 'completed', 'pending'

  // The "Anchor" date allows us to calculate indices infinitely
  final DateTime _anchorDate = DateTime(2020, 1, 1);

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    // Calculate initial index based on difference between now and anchor
    // viewportFraction 0.18 makes items roughly 60-70px wide, allowing neighbors to be seen
    final initialIndex = DateUtils.dateOnly(
      DateTime.now(),
    ).difference(_anchorDate).inDays;
    _datePageController = PageController(
      initialPage: initialIndex,
      viewportFraction: 0.18,
    );
  }

  @override
  void dispose() {
    _datePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AppState, _PlanCollections>(
      selector: (_, state) => _PlanCollections(
        tasks: state.tasks,
        hobbies: state.hobbies,
      ),
      builder: (context, data, _) {
        final appState = context.read<AppState>();
        final dayEntries = _getEntriesForDate(
          data.tasks,
          data.hobbies,
          _selectedDate,
        );

        return Scaffold(
          backgroundColor: AppColors.background, // Clean off-white
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // --- HEADER SECTION ---
                _buildHeader(context),

                const SizedBox(height: 10),

                // --- NEW SNAP WHEEL SELECTOR ---
                _buildWheelDateSelector(),

                const SizedBox(height: 16),

                // --- TITLE & FILTER DROPDOWN ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Your Plans',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                      _FilterDropdown(
                        currentFilter: _filter,
                        onChanged: (val) => setState(() => _filter = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // --- TIMELINE LIST ---
                Expanded(
                  child: dayEntries.isEmpty
                      ? const EmptyState(
                          title: 'No plans for this day',
                          message: 'Take a break or add a new task!',
                          icon: Icons.event_busy,
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                          itemCount: dayEntries.length,
                          itemBuilder: (context, index) {
                            final entry = dayEntries[index];
                            final color =
                                entry.originalColor ?? AppColors.pastels[0];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _TimelineCard(
                                entry: entry,
                                color: color,
                                onToggle: () {
                                  if (entry.type == 'task') {
                                    appState.toggleTask(entry.id);
                                  } else {
                                    appState.toggleHobby(entry.id);
                                  }
                                },
                                onDelete: () async {
                                  if (entry.type == 'task') {
                                    await appState.deleteTask(entry.id);
                                  } else {
                                    await appState.deleteHobby(entry.id);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- NEW WHEEL SELECTOR ---
  Widget _buildWheelDateSelector() {
    return SizedBox(
      height: 88, // Total height of the picker area
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. THE STATIC "NEEDLE" (Selection Box)
          // This stays firmly in the center.
          Container(
            width: 64,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black, width: 2),
              // Subtle shadow to give it depth behind the sliding numbers
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),

          // 2. THE MOVING WHEEL (PageView)
          // This slides on top.
          PageView.builder(
            controller: _datePageController,
            // Physics handles the "Snap" effect
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                // Calculate the new date based on the index
                _selectedDate = _anchorDate.add(Duration(days: index));
              });
            },
            itemBuilder: (context, index) {
              final date = _anchorDate.add(Duration(days: index));
              final isSelected = DateUtils.isSameDay(date, _selectedDate);
              final isToday = DateUtils.isSameDay(date, DateTime.now());

              // We use an AnimatedBuilder-like approach via state rebuilds
              // When _selectedDate changes, this builder re-runs to update colors.

              return AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isSelected ? 1.0 : 0.5, // Fade out side items slightly
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Day Name (MON, TUE)
                      Text(
                        DateFormat(
                          'E',
                        ).format(date).substring(0, 3).toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          // White if over black box, Black if over white background
                          color: isSelected ? Colors.white : Colors.black54,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Date Number (12, 13)
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          // White if over black box, Black if over white background
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF6C63FF)
                                : Colors.black,
                            shape: BoxShape.circle,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF6C63FF,
                                      ).withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textMain,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate).toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 2.0,
                  height: 1.2,
                ),
              ),
            ],
          ),

          // CALENDAR BUTTON (Updated to sync with Wheel)
          _NeuIconButton(
            icon: Icons.calendar_month,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Colors.black, // Header background color
                        onPrimary: Colors.white, // Header text color
                        onSurface: Colors.black, // Body text color
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  // SYNC THE WHEEL TO THE PICKED DATE
                  final index = DateUtils.dateOnly(
                    picked,
                  ).difference(_anchorDate).inDays;
                  _datePageController.jumpToPage(index);
                });
              }
            },
          ),
        ],
      ),
    );
  }

  List<_PlanEntry> _getEntriesForDate(
    List<Task> tasks,
    List<Hobby> hobbies,
    DateTime date,
  ) {
    final List<_PlanEntry> entries = [];

    for (final task in tasks) {
      if (DateUtils.isSameDay(task.date, date)) {
        // Filter Logic
        if (_filter == 'completed' && !task.isDone) continue;
        if (_filter == 'pending' && task.isDone) continue;

        entries.add(
          _PlanEntry(
            id: task.taskId,
            title: task.title,
            subtitle: task.details ?? 'Task',
            time: task.time,
            isDone: task.isDone,
            type: 'task',
            originalColor: task.color,
          ),
        );
      }
    }

    for (final hobby in hobbies) {
      if (DateUtils.isSameDay(hobby.periodStart, date)) {
        // Filter Logic
        if (_filter == 'completed' && !hobby.isDone) continue;
        if (_filter == 'pending' && hobby.isDone) continue;

        entries.add(
          _PlanEntry(
            id: hobby.hobbyId,
            title: hobby.title,
            subtitle: hobby.category,
            time: const TimeOfDay(hour: 18, minute: 0),
            isDone: hobby.isDone,
            type: 'habit',
            originalColor: hobby.color,
          ),
        );
      }
    }

    entries.sort((a, b) {
      final aMin = a.time.hour * 60 + a.time.minute;
      final bMin = b.time.hour * 60 + b.time.minute;
      return aMin.compareTo(bMin);
    });

    return entries;
  }
}

// --- UI COMPONENTS (Timeline Card & Button kept same as before) ---

class _TimelineCard extends StatefulWidget {
  final _PlanEntry entry;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TimelineCard({
    required this.entry,
    required this.color,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<_TimelineCard> createState() => _TimelineCardState();
}

class _TimelineCardState extends State<_TimelineCard> {
  double _scale = 1.0;

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border, width: 2),
            // No Shadow as requested
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.delete_forever,
                size: 40,
                color: AppColors.shadow,
              ),
              const SizedBox(height: 12),
              const Text(
                'Delete Item?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.shadow,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to remove "${widget.entry.title}"?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: const Text(
                          'Cancel',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        widget.onDelete();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.textMain,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: const Text(
                          'Delete',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cardSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeString =
        '${widget.entry.time.hourOfPeriod}:${widget.entry.time.minute.toString().padLeft(2, '0')} ${widget.entry.time.period == DayPeriod.am ? 'AM' : 'PM'}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              timeString,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.0,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTapDown: (_) => setState(() => _scale = 0.95),
            onTap: () {
              setState(() => _scale = 1.0);
              widget.onToggle();
            },
            onTapCancel: () => setState(() => _scale = 1.0),
            onLongPress: () {
              setState(() => _scale = 0.95);
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) setState(() => _scale = 1.0);
                _showDeleteConfirmation();
              });
            },
            child: AnimatedScale(
              scale: _scale,
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: widget.entry.isDone
                      ? const Color(0xFFF0F0F0)
                      : widget.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.entry.isDone ? Colors.black12 : Colors.black,
                    width: 2,
                  ),
                  boxShadow: widget.entry.isDone
                      ? []
                      : const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(4, 4),
                            blurRadius: 0,
                          ),
                        ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.entry.isDone
                              ? Colors.black
                              : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: widget.entry.isDone
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.entry.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: widget.entry.isDone
                                    ? AppColors.textSecondary
                                    : Colors
                                          .black, // Pastels are light, so black text is better
                                decoration: widget.entry.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationThickness: 2.0,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    widget.entry.type.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.entry.subtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: widget.entry.isDone
                                          ? AppColors.textSecondary
                                          : Colors.black87,
                                      height: 1.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NeuIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NeuIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textMain, size: 24),
      ),
    );
  }
}

class _PlanEntry {
  final String id;
  final String title;
  final String subtitle;
  final TimeOfDay time;
  final bool isDone;
  final String type;
  final Color? originalColor;

  _PlanEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isDone,
    required this.type,
    this.originalColor,
  });
}

class _FilterDropdown extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({required this.currentFilter, required this.onChanged});

  String _getLabel(String value) {
    switch (value) {
      case 'completed':
        return 'Completed';
      case 'pending':
        return 'Pending';
      case 'all':
      default:
        return 'All Plans';
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 48),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border, width: 2),
      ),
      itemBuilder: (context) => [
        _buildMenuItem('all', 'All Plans'),
        _buildMenuItem('completed', 'Completed'),
        _buildMenuItem('pending', 'Pending'),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getLabel(currentFilter),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.shadow,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: AppColors.shadow,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label) {
    final isSelected = currentFilter == value;
    return PopupMenuItem<String>(
      value: value,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? AppColors.textMain : AppColors.textSecondary,
        ),
      ),
    );
  }
}
