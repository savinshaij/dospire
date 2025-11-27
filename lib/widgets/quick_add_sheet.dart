import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../models/models.dart';
import '../state/app_state.dart';

class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key});

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  int _tabIndex = 0; // 0 = One-time (Task), 1 = Recurring (Hobby)
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _detailsController = TextEditingController();

  // Task specific
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  // Hobby specific
  HobbyFrequency _frequency = HobbyFrequency.everyday;
  DateTime _periodStart = DateTime.now();
  DateTime _periodEnd = DateTime.now().add(const Duration(days: 30));
  final List<int> _selectedWeekdays = [1, 2, 3, 4, 5]; // Mon-Fri default

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final state = context.read<AppState>();

    if (_tabIndex == 0) {
      // Create Task
      final targetDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      bool hasConflict(DateTime checkTime) {
        return state.tasks.any((task) {
          final taskTime = DateTime(
            task.date.year,
            task.date.month,
            task.date.day,
            task.hour,
            task.minute,
          );
          return taskTime.difference(checkTime).inMinutes.abs() < 5;
        });
      }

      if (hasConflict(targetDateTime)) {
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AppColors.transparent,
            insetPadding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: AppColors.textPrimary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Schedule Conflict',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You already have a task scheduled within 5 minutes of this time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary.withValues(alpha: 0.6),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.textPrimary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.border,
                                width: 2,
                              ),
                            ),
                            child: const Text(
                              'Create Anyway',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textInverse,
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

        if (shouldProceed != true) return;

        // Auto-increment logic
        DateTime adjustedTime = targetDateTime;
        while (hasConflict(adjustedTime)) {
          adjustedTime = adjustedTime.add(const Duration(minutes: 1));
        }

        state.createTask(
          title: title,
          date: adjustedTime,
          time: TimeOfDay.fromDateTime(adjustedTime),
          details: _detailsController.text.trim(),
        );
      } else {
        state.createTask(
          title: title,
          date: _selectedDate,
          time: _selectedTime,
          details: _detailsController.text.trim(),
        );
      }
    } else {
      // Create Hobby
      if (_selectedWeekdays.isEmpty) return;

      state.createHobby(
        title: title,
        category: _categoryController.text.trim().isEmpty
            ? 'General'
            : _categoryController.text.trim(),
        frequency: _frequency,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        weekdays: _selectedWeekdays,
        // For now, hobbies don't have a specific time in the UI, defaulting to 9 AM
        time: const TimeOfDay(hour: 9, minute: 0),
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'New Plan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(width: 1),
                    ),
                    child: const Icon(Icons.close, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab Switcher
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(width: 1),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, offset: Offset(4, 4)),
                ],
                color: AppColors.cardSurface,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'One-time',
                      isSelected: _tabIndex == 0,
                      onTap: () => setState(() => _tabIndex = 0),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'Recurring',
                      isSelected: _tabIndex == 1,
                      onTap: () => setState(() => _tabIndex = 1),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Title Input
            const _Label('TITLE'),
            _NeoInput(
              controller: _titleController,
              hint: 'What are you planning?',
              autofocus: true,
            ),
            const SizedBox(height: 16),

            if (_tabIndex == 0) ...[
              // Task Inputs
              const _Label('DETAILS'),
              _NeoInput(
                controller: _detailsController,
                hint: 'Add some details...',
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('DATE'),
                        _NeoButton(
                          icon: Icons.calendar_today,
                          label: DateFormat('MMM d').format(_selectedDate),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.black,
                                      onPrimary: AppColors.white,
                                      onSurface: AppColors.black,
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('TIME'),
                        _NeoButton(
                          icon: Icons.access_time,
                          label: _selectedTime.format(context),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.black,
                                      onPrimary: AppColors.white,
                                      onSurface: AppColors.black,
                                      surface: AppColors.white,
                                    ),
                                    timePickerTheme: TimePickerThemeData(
                                      dialHandColor: AppColors.black,
                                      dialBackgroundColor: AppColors.background,
                                      hourMinuteColor:
                                          WidgetStateColor.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.selected,
                                                )
                                                ? AppColors.black
                                                : AppColors.background,
                                          ),
                                      hourMinuteTextColor:
                                          WidgetStateColor.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.selected,
                                                )
                                                ? AppColors.white
                                                : AppColors.black,
                                          ),
                                      dayPeriodColor:
                                          WidgetStateColor.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.selected,
                                                )
                                                ? AppColors.black
                                                : AppColors.background,
                                          ),
                                      dayPeriodTextColor:
                                          WidgetStateColor.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.selected,
                                                )
                                                ? AppColors.white
                                                : AppColors.black,
                                          ),
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.black,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              setState(() => _selectedTime = time);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Hobby Inputs
              const _Label('CATEGORY'),
              _NeoInput(
                controller: _categoryController,
                hint: 'e.g., Fitness, Art',
              ),
              const SizedBox(height: 16),

              const _Label('DURATION'),
              _NeoButton(
                icon: Icons.calendar_today,
                label:
                    '${DateFormat('MMM d').format(_periodStart)} - ${DateFormat('MMM d').format(_periodEnd)}',
                onTap: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: DateTimeRange(
                      start: _periodStart,
                      end: _periodEnd,
                    ),
                  );
                  if (range != null) {
                    setState(() {
                      _periodStart = range.start;
                      _periodEnd = range.end;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              const _Label('FREQUENCY'),
              Row(
                children: [
                  _FrequencyChip(
                    label: 'Everyday',
                    isSelected: _frequency == HobbyFrequency.everyday,
                    onTap: () =>
                        setState(() => _frequency = HobbyFrequency.everyday),
                  ),
                  const SizedBox(width: 12),
                  _FrequencyChip(
                    label: 'Specific Days',
                    isSelected: _frequency == HobbyFrequency.someDays,
                    onTap: () =>
                        setState(() => _frequency = HobbyFrequency.someDays),
                  ),
                ],
              ),

              if (_frequency == HobbyFrequency.someDays) ...[
                const SizedBox(height: 16),
                const _Label('REPEAT ON'),
                _DaySelector(
                  selectedWeekdays: _selectedWeekdays,
                  onChanged: (updated) {
                    setState(() {
                      _selectedWeekdays.clear();
                      _selectedWeekdays.addAll(updated);
                    });
                  },
                ),
              ],
            ],

            const SizedBox(height: 32),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_tabIndex == 1 && _selectedWeekdays.isEmpty)
                    ? null
                    : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.textInverse,
                  disabledBackgroundColor: AppColors.textSecondary.withValues(
                    alpha: 0.3,
                  ),
                  disabledForegroundColor: AppColors.textSecondary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  (_tabIndex == 1 && _selectedWeekdays.isEmpty)
                      ? 'No day selected'
                      : 'Create Plan',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<int> selectedWeekdays;
  final ValueChanged<List<int>> onChanged;

  const _DaySelector({required this.selectedWeekdays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final itemWidth = width / 7;

        return Row(
          children: List.generate(7, (index) {
            final day = index + 1;
            final isSelected = selectedWeekdays.contains(day);
            final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

            return SizedBox(
              width: itemWidth,
              child: GestureDetector(
                onTap: () {
                  final newList = List<int>.from(selectedWeekdays);
                  if (isSelected) {
                    newList.remove(
                      day,
                    ); // Allow removing even if it's the last one
                  } else {
                    newList.add(day);
                  }
                  onChanged(newList);
                },
                behavior: HitTestBehavior.opaque,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primaryAccent.withValues(alpha: 0.3)
                          : AppColors.cardSurface,
                      border: Border.all(width: 1),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 4),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labels[index],
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary, // Always black text
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary, // Uber Black
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryAccent.withValues(alpha: 0.3)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary, // Uber Black for both states
          ),
        ),
      ),
    );
  }
}

class _NeoInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool autofocus;

  const _NeoInput({
    required this.controller,
    required this.hint,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        border: Border.all(width: 2, color: AppColors.border),
        borderRadius: BorderRadius.circular(12), // Slightly sharper
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(4, 4),
            blurRadius: 0, // Hard shadow
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: TextField(
          controller: controller,
          autofocus: autofocus,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            focusColor: Colors.transparent,
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.3),
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _NeoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NeoButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          border: Border.all(width: 2, color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(4, 4),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FrequencyChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryAccent : AppColors.cardSurface,
          border: Border.all(width: 2, color: AppColors.border),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 4),
                    blurRadius: 8,
                  ),
                ]
              : const [
                  BoxShadow(
                    color: AppColors.shadow,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
