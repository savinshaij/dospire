import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../app_theme.dart';

part 'task.g.dart';

@HiveType(typeId: 1)
class Task {
  Task({
    required this.taskId,
    required this.title,
    required this.date,
    required this.hour,
    required this.minute,
    this.details,
    this.isDone = false,
    this.colorIndex,
  });

  @HiveField(0)
  final String taskId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int hour;

  @HiveField(4)
  final int minute;

  @HiveField(5)
  final String? details;

  @HiveField(6)
  final bool isDone;

  @HiveField(7)
  final int? colorIndex;

  // Computed TimeOfDay from stored hour/minute values
  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  Color get color {
    if (colorIndex != null &&
        colorIndex! >= 0 &&
        colorIndex! < AppColors.pastels.length) {
      return AppColors.pastels[colorIndex!];
    }
    return AppColors.pastels[0]; // Default fallback
  }

  Task copyWith({
    String? taskId,
    String? title,
    DateTime? date,
    TimeOfDay? time,
    String? details,
    bool? isDone,
    int? colorIndex,
  }) {
    final TimeOfDay actualTime = time ?? this.time;
    return Task(
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      date: date ?? this.date,
      hour: actualTime.hour,
      minute: actualTime.minute,
      details: details ?? this.details,
      isDone: isDone ?? this.isDone,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskId: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      details: json['details'] as String?,
      isDone: json['isDone'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': taskId,
      'title': title,
      'date': date.toIso8601String(),
      'hour': time.hour,
      'minute': time.minute,
      'details': details,
      'isDone': isDone,
      'colorIndex': colorIndex,
    };
  }
}
