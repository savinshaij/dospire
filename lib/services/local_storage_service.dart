import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class LocalStorageService {
  LocalStorageService._();

  static final LocalStorageService instance = LocalStorageService._();

  SharedPreferences? _prefs;

  static const _profileKey = 'dospire_profile';
  static const _tasksKey = 'dospire_tasks';
  static const _hobbiesKey = 'dospire_hobbies';
  static const _notesKey = 'dospire_notes';
  static const _focusedDateKey = 'dospire_focus';

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveProfile(UserProfile? profile) async {
    final prefs = await _storage;
    if (profile == null) {
      await prefs.remove(_profileKey);
    } else {
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    }
  }

  Future<UserProfile?> loadProfile() async {
    final prefs = await _storage;
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = await _storage;
    await prefs.setString(
      _tasksKey,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }

  Future<List<Task>> loadTasks() async {
    final prefs = await _storage;
    final raw = prefs.getString(_tasksKey);
    if (raw == null) return [];
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  Future<void> saveHobbies(List<Hobby> hobbies) async {
    final prefs = await _storage;
    await prefs.setString(
      _hobbiesKey,
      jsonEncode(hobbies.map((h) => h.toJson()).toList()),
    );
  }

  Future<List<Hobby>> loadHobbies() async {
    final prefs = await _storage;
    final raw = prefs.getString(_hobbiesKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Hobby.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveNotes(List<Note> notes) async {
    final prefs = await _storage;
    await prefs.setString(
      _notesKey,
      jsonEncode(notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<List<Note>> loadNotes() async {
    final prefs = await _storage;
    final raw = prefs.getString(_notesKey);
    if (raw == null) return [];
    final notes = (jsonDecode(raw) as List<dynamic>)
        .map((e) => Note.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    notes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notes;
  }

  Future<void> saveFocusedDate(DateTime date) async {
    final prefs = await _storage;
    await prefs.setString(_focusedDateKey, date.toIso8601String());
  }

  Future<DateTime?> loadFocusedDate() async {
    final prefs = await _storage;
    final raw = prefs.getString(_focusedDateKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }
}

