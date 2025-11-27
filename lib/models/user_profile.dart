import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 0)
class UserProfile {
  UserProfile({
    required this.name,
    required this.age,
    required this.createdAt,
    this.muteNotifications = false,
  });

  @HiveField(0)
  final String name;

  @HiveField(1)
  final int age;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final bool muteNotifications;

  UserProfile copyWith({
    String? name,
    int? age,
    DateTime? createdAt,
    bool? muteNotifications,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      createdAt: createdAt ?? this.createdAt,
      muteNotifications: muteNotifications ?? this.muteNotifications,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String,
      age: json['age'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      muteNotifications: json['muteNotifications'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'createdAt': createdAt.toIso8601String(),
      'muteNotifications': muteNotifications,
    };
  }
}
