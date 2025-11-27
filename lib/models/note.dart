import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../app_theme.dart';

part 'note.g.dart';

@HiveType(typeId: 4)
class Note {
  Note({
    required this.noteId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.isPinned = false,
    this.colorIndex,
  });

  @HiveField(0)
  final String noteId;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String body;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final bool isPinned;

  @HiveField(5)
  final int? colorIndex;

  Color get color {
    if (colorIndex != null &&
        colorIndex! >= 0 &&
        colorIndex! < AppColors.pastels.length) {
      return AppColors.pastels[colorIndex!];
    }
    return AppColors.pastels[0]; // Default fallback
  }

  Note copyWith({
    String? noteId,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isPinned,
    int? colorIndex,
  }) {
    return Note(
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isPinned: isPinned ?? this.isPinned,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      noteId: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isPinned: json['isPinned'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': noteId,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'isPinned': isPinned,
      'colorIndex': colorIndex,
    };
  }
}
