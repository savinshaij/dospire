import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../app_theme.dart';

part 'hobby.g.dart';

@HiveType(typeId: 3)
enum HobbyFrequency {
  @HiveField(0)
  everyday,
  @HiveField(1)
  someDays,
}

@HiveType(typeId: 2)
class Hobby {
  Hobby({
    required this.hobbyId,
    required this.title,
    required this.category,
    required this.frequency,
    required this.periodStart,
    required this.periodEnd,
    this.selectedWeekdays = const [],
    this.colorValue,
    this.timeHour,
    this.timeMinute,
    this.isDone = false,
    this.colorIndex,
  });

  @HiveField(0)
  final String hobbyId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final HobbyFrequency frequency;

  @HiveField(4)
  final DateTime periodStart;

  @HiveField(5)
  final DateTime periodEnd;

  @HiveField(6)
  final List<int> selectedWeekdays;

  @HiveField(7)
  final int? colorValue;

  @HiveField(8)
  final int? timeHour;

  @HiveField(9)
  final int? timeMinute;

  @HiveField(10)
  final bool isDone;

  @HiveField(11)
  final int? colorIndex;

  // Computed color from stored int value
  Color? get color {
    if (colorIndex != null &&
        colorIndex! >= 0 &&
        colorIndex! < AppColors.pastels.length) {
      return AppColors.pastels[colorIndex!];
    }
    return colorValue != null ? Color(colorValue!) : null;
  }

  // Computed TimeOfDay from stored hour/minute values
  TimeOfDay? get time => timeHour != null && timeMinute != null
      ? TimeOfDay(hour: timeHour!, minute: timeMinute!)
      : null;

  Hobby copyWith({
    String? hobbyId,
    String? title,
    String? category,
    HobbyFrequency? frequency,
    DateTime? periodStart,
    DateTime? periodEnd,
    List<int>? selectedWeekdays,
    Color? color,
    TimeOfDay? time,
    bool? isDone,
    int? colorIndex,
  }) {
    return Hobby(
      hobbyId: hobbyId ?? this.hobbyId,
      title: title ?? this.title,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      periodStart: periodStart ?? this.periodStart,
      periodEnd: periodEnd ?? this.periodEnd,
      selectedWeekdays: selectedWeekdays ?? this.selectedWeekdays,
      colorValue: color != null
          ? (color.r * 255).toInt() << 24 |
                (color.g * 255).toInt() << 16 |
                (color.b * 255).toInt() << 8 |
                (color.a * 255).toInt()
          : colorValue,
      timeHour: time?.hour ?? timeHour,
      timeMinute: time?.minute ?? timeMinute,
      isDone: isDone ?? this.isDone,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  factory Hobby.fromJson(Map<String, dynamic> json) {
    Color? color;
    if (json['color'] != null) {
      color = Color(int.parse(json['color'] as String));
    }
    TimeOfDay? time;
    if (json['hour'] != null && json['minute'] != null) {
      time = TimeOfDay(
        hour: json['hour'] as int,
        minute: json['minute'] as int,
      );
    }

    return Hobby(
      hobbyId: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String? ?? '',
      frequency: HobbyFrequency.values[json['frequency'] ?? 0],
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      selectedWeekdays: List<int>.from(json['weekdays'] ?? []),
      colorValue: color != null
          ? (color.r * 255).toInt() << 24 |
                (color.g * 255).toInt() << 16 |
                (color.b * 255).toInt() << 8 |
                (color.a * 255).toInt()
          : null,
      timeHour: time?.hour,
      timeMinute: time?.minute,
      isDone: json['isDone'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': hobbyId,
      'title': title,
      'category': category,
      'frequency': frequency.index,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'weekdays': selectedWeekdays,
      'color': color != null
          ? ((color!.r * 255).toInt() << 24 |
                    (color!.g * 255).toInt() << 16 |
                    (color!.b * 255).toInt() << 8 |
                    (color!.a * 255).toInt())
                .toString()
          : null,
      'isDone': isDone,
      'colorIndex': colorIndex,
    };
    if (time != null) {
      map['hour'] = time!.hour;
      map['minute'] = time!.minute;
    }
    return map;
  }

  String get frequencyLabel =>
      frequency == HobbyFrequency.everyday ? 'Everyday' : 'Some days';
}
