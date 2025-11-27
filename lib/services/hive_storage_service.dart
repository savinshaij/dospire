import 'package:hive_flutter/hive_flutter.dart';
import '../models/models.dart';

class HiveStorageService {
  static const String _profileBoxName = 'profileBox';
  static const String _tasksBoxName = 'tasksBox';
  static const String _hobbiesBoxName = 'hobbiesBox';
  static const String _notesBoxName = 'notesBox';
  static const String _settingsBoxName = 'settingsBox';

  late Box<UserProfile> _profileBox;
  late Box<Task> _tasksBox;
  late Box<Hobby> _hobbiesBox;
  late Box<Note> _notesBox;
  late Box _settingsBox;

  Future<void> init() async {
    _profileBox = await Hive.openBox<UserProfile>(_profileBoxName);
    _tasksBox = await Hive.openBox<Task>(_tasksBoxName);
    _hobbiesBox = await Hive.openBox<Hobby>(_hobbiesBoxName);
    _notesBox = await Hive.openBox<Note>(_notesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // Profile
  Future<void> saveProfile(UserProfile? profile) async {
    if (profile == null) {
      await _profileBox.clear();
    } else {
      await _profileBox.put('userProfile', profile);
    }
  }

  Future<UserProfile?> loadProfile() async {
    return _profileBox.get('userProfile');
  }

  // Tasks
  Future<void> saveTasks(List<Task> tasks) async {
    await _syncBox<Task>(_tasksBox, tasks, (task) => task.taskId);
  }

  Future<List<Task>> loadTasks() async {
    return _tasksBox.values.toList();
  }

  // Hobbies
  Future<void> saveHobbies(List<Hobby> hobbies) async {
    await _syncBox<Hobby>(_hobbiesBox, hobbies, (hobby) => hobby.hobbyId);
  }

  Future<List<Hobby>> loadHobbies() async {
    return _hobbiesBox.values.toList();
  }

  // Notes
  Future<void> saveNotes(List<Note> notes) async {
    await _syncBox<Note>(_notesBox, notes, (note) => note.noteId);
  }

  Future<List<Note>> loadNotes() async {
    return _notesBox.values.toList();
  }

  // Settings / Focused Date
  Future<void> saveFocusedDate(DateTime date) async {
    await _settingsBox.put('focusedDate', date);
  }

  Future<DateTime?> loadFocusedDate() async {
    return _settingsBox.get('focusedDate') as DateTime?;
  }

  Future<void> clearAll() async {
    await Future.wait([
      _profileBox.clear(),
      _tasksBox.clear(),
      _hobbiesBox.clear(),
      _notesBox.clear(),
      _settingsBox.clear(),
    ]);
  }

  Future<void> _syncBox<T>(
    Box<T> box,
    List<T> items,
    String Function(T item) idGetter,
  ) async {
    if (items.isEmpty) {
      await box.clear();
      return;
    }

    final targetIds = items.map(idGetter).toSet();

    final keysToDelete = box.keys
        .where((dynamic key) => key is String && !targetIds.contains(key))
        .toList();
    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }

    final updates = <String, T>{
      for (final item in items) idGetter(item): item,
    };
    await box.putAll(updates);
  }
}
