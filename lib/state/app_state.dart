import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../services/hive_storage_service.dart';
import '../services/notification_service.dart';
import '../app_theme.dart';

class AppState extends ChangeNotifier {
  AppState(this._storage);

  final HiveStorageService _storage;
  final Uuid _uuid = const Uuid();
  bool _isReady = false;
  late NotificationService _notificationService;

  UserProfile? profile;
  DateTime focusedDate = DateTime.now();
  List<Task> tasks = [];
  List<Hobby> hobbies = [];
  List<Note> notes = [];

  // Spin challenge usage (in-memory only, not persisted)
  DateTime? lastSpinDate;

  // Sequential color index
  int _lastColorIndex = 0;

  bool get isReady => _isReady;

  Future<void> hydrate() async {
    try {
      // Initialize notification service
      _notificationService = NotificationService();

      // OPTIMIZED: Load data concurrently with individual error handling
      // If one fails, others should still succeed.
      final results = await Future.wait([
        _storage.loadProfile().catchError((e) {
          debugPrint('Failed to load profile: $e');
          return null;
        }),
        _storage.loadTasks().catchError((e) {
          debugPrint('Failed to load tasks: $e');
          return <Task>[];
        }),
        _storage.loadHobbies().catchError((e) {
          debugPrint('Failed to load hobbies: $e');
          return <Hobby>[];
        }),
        _storage.loadNotes().catchError((e) {
          debugPrint('Failed to load notes: $e');
          return <Note>[];
        }),
        _storage.loadFocusedDate().catchError((e) {
          debugPrint('Failed to load focused date: $e');
          return DateTime.now();
        }),
      ]);

      // Assign results
      profile = results[0] as UserProfile?;
      tasks = results[1] as List<Task>;
      hobbies = results[2] as List<Hobby>;
      notes = results[3] as List<Note>;
      _sortNotes(); // Ensure loaded notes are sorted
      focusedDate = (results[4] as DateTime?) ?? DateTime.now();

      _isReady = true;

      // BACKGROUND: Schedule notifications (don't await - fire and forget)
      unawaited(
        _scheduleAllNotifications().catchError((e) {
          debugPrint('Notification scheduling failed: $e');
          return Future<void>.value();
        }),
      );

      // Check if we need to reschedule notifications (e.g., after device reboot)
      // This is a workaround since we can't reschedule directly from native Android
      // without Flutter context
      _checkAndRescheduleNotificationsIfNeeded();

      notifyListeners();
    } catch (e) {
      debugPrint('App hydration failed: $e');
      _isReady = true; // Allow app to start anyway
      notifyListeners();
    }
  }

  // User profile -------------------------------------------------------------
  Future<void> completeOnboarding({
    required String name,
    required int age,
  }) async {
    profile = UserProfile(name: name, age: age, createdAt: DateTime.now());
    await _storage.saveProfile(profile);
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    bool? muteNotifications,
  }) async {
    if (profile != null) {
      final previousMuteState = profile!.muteNotifications;
      profile = profile!.copyWith(
        name: name,
        age: age,
        muteNotifications: muteNotifications,
      );
      await _storage.saveProfile(profile);

      // If mute state changed, handle notification scheduling
      if (muteNotifications != null && muteNotifications != previousMuteState) {
        if (muteNotifications) {
          // Just canceled all notifications - they're already stopped
          await _notificationService.cancelAllNotifications();
        } else {
          // Re-enable notifications - reschedule everything
          await _scheduleAllNotifications();
        }
      }

      notifyListeners();
    }
  }

  // Tasks --------------------------------------------------------------------
  Future<void> createTask({
    required String title,
    required DateTime date,
    required TimeOfDay time,
    String? details,
  }) async {
    _lastColorIndex = (_lastColorIndex + 1) % AppColors.pastels.length;
    final task = Task(
      taskId: _uuid.v4(),
      title: title,
      date: date,
      hour: time.hour,
      minute: time.minute,
      details: details,
      colorIndex: _lastColorIndex,
    );
    tasks = [...tasks, task]..sort((a, b) => a.date.compareTo(b.date));
    await _storage.saveTasks(tasks);

    // Schedule notification for new task (5 min before)
    final taskDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    await _scheduleTaskNotification(task.taskId.hashCode, title, taskDateTime);

    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    tasks = tasks.map((e) => e.taskId == task.taskId ? task : e).toList();
    await _storage.saveTasks(tasks);
    notifyListeners();
  }

  Future<void> deleteTask(String id) async {
    // Cancel notification for deleted task
    try {
      await _notificationService.cancelNotification(id.hashCode);
    } catch (e) {
      debugPrint('Failed to cancel notification for task $id: $e');
    }

    tasks = tasks.where((t) => t.taskId != id).toList();
    await _storage.saveTasks(tasks);
    notifyListeners();
  }

  Future<void> toggleTask(String id) async {
    tasks = tasks
        .map(
          (task) =>
              task.taskId == id ? task.copyWith(isDone: !task.isDone) : task,
        )
        .toList();
    await _storage.saveTasks(tasks);
    notifyListeners();
  }

  List<Task> tasksForDate(DateTime date) {
    return tasks.where((task) => _isSameDay(task.date, date)).toList();
  }

  // Hobbies ------------------------------------------------------------------
  Future<void> createHobby({
    required String title,
    required String category,
    required HobbyFrequency frequency,
    required DateTime periodStart,
    required DateTime periodEnd,
    List<int> weekdays = const [],
    TimeOfDay? time,
  }) async {
    _lastColorIndex = (_lastColorIndex + 1) % AppColors.pastels.length;
    final hobby = Hobby(
      hobbyId: _uuid.v4(),
      title: title,
      category: category,
      frequency: frequency,
      periodStart: periodStart,
      periodEnd: periodEnd,
      selectedWeekdays: weekdays,
      colorIndex: _lastColorIndex,
      timeHour: time?.hour,
      timeMinute: time?.minute,
    );
    hobbies = [...hobbies, hobby];
    await _storage.saveHobbies(hobbies);

    // Schedule notifications for the new habit
    if (!(profile?.muteNotifications ?? false)) {
      await _scheduleMorningNotification(
        hobby.hobbyId.hashCode,
        _notificationService.getRandomMorningHabitMessage(),
        const TimeOfDay(hour: 8, minute: 0),
      );

      await _scheduleEveningNotification(
        hobby.hobbyId.hashCode,
        _notificationService.getRandomEveningHabitMessage(),
        const TimeOfDay(hour: 21, minute: 0),
      );
    }

    notifyListeners();
  }

  Future<void> updateHobby(Hobby hobby) async {
    hobbies = hobbies
        .map((h) => h.hobbyId == hobby.hobbyId ? hobby : h)
        .toList();
    await _storage.saveHobbies(hobbies);
    notifyListeners();
  }

  Future<void> deleteHobby(String id) async {
    // Cancel notifications for deleted hobby
    try {
      await _notificationService.cancelMorningNotification(id.hashCode);
      await _notificationService.cancelEveningNotification(id.hashCode);
    } catch (e) {
      debugPrint('Failed to cancel notifications for hobby $id: $e');
    }

    hobbies = hobbies.where((h) => h.hobbyId != id).toList();
    await _storage.saveHobbies(hobbies);
    notifyListeners();
  }

  Future<void> toggleHobby(String id) async {
    hobbies = hobbies
        .map(
          (hobby) => hobby.hobbyId == id
              ? hobby.copyWith(isDone: !hobby.isDone)
              : hobby,
        )
        .toList();
    await _storage.saveHobbies(hobbies);
    notifyListeners();
  }

  List<Hobby> hobbiesForDate(DateTime date) {
    return hobbies.where((hobby) {
      final inRange =
          !date.isBefore(hobby.periodStart) && !date.isAfter(hobby.periodEnd);
      if (!inRange) return false;
      if (hobby.frequency == HobbyFrequency.everyday ||
          hobby.selectedWeekdays.isEmpty) {
        return true;
      }
      final weekday = date.weekday;
      return hobby.selectedWeekdays.contains(weekday);
    }).toList();
  }

  // Notes --------------------------------------------------------------------
  Future<void> addNote({required String title, required String body}) async {
    _lastColorIndex = (_lastColorIndex + 1) % AppColors.pastels.length;
    final note = Note(
      noteId: _uuid.v4(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
      isPinned: false, // New notes are unpinned by default
      colorIndex: _lastColorIndex,
    );
    notes = [note, ...notes];
    _sortNotes(); // Ensure correct order
    await _storage.saveNotes(notes);
    notifyListeners();
  }

  Future<void> deleteNote(String id) async {
    notes = notes.where((note) => note.noteId != id).toList();
    await _storage.saveNotes(notes);
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    notes = notes.map((n) => n.noteId == note.noteId ? note : n).toList();
    _sortNotes(); // Re-sort in case pin status changed
    await _storage.saveNotes(notes);
    notifyListeners();
  }

  Future<void> toggleNotePin(String id) async {
    notes = notes.map((n) {
      if (n.noteId == id) {
        return n.copyWith(isPinned: !n.isPinned);
      }
      return n;
    }).toList();
    _sortNotes();
    await _storage.saveNotes(notes);
    notifyListeners();
  }

  void _sortNotes() {
    notes.sort((a, b) {
      // 1. Pinned notes come first
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;

      // 2. Then sort by date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  // Dates --------------------------------------------------------------------
  Future<void> setFocusedDate(DateTime date) async {
    focusedDate = date;
    await _storage.saveFocusedDate(date);
    notifyListeners();
  }

  /// Refresh data from storage (used by pull-to-refresh)
  Future<void> refresh() async {
    await hydrate();
  }

  double punctualityFor(DateTime date) {
    final todaysTasks = tasksForDate(date);
    if (todaysTasks.isEmpty) return 0;
    final done = todaysTasks.where((task) => task.isDone).length;
    return done / todaysTasks.length;
  }

  double overallPunctuality() {
    final total = tasks.length + hobbies.length;
    if (total == 0) return 0;
    final completed =
        tasks.where((task) => task.isDone).length +
        hobbies.where((hobby) => hobby.isDone).length;
    return completed / total;
  }

  // Spin challenge helpers ---------------------------------------------------

  bool hasSpunToday() {
    if (lastSpinDate == null) return false;
    final now = DateTime.now();
    return _isSameDay(lastSpinDate!, now);
  }

  void markSpinToday() {
    lastSpinDate = DateTime.now();
  }

  String friendlyDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, y').format(date);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Notification methods -----------------------------------------------------
  Future<void> _scheduleAllNotifications() async {
    await _notificationService.initialize();

    // Request permissions
    await _notificationService.requestPermissions();

    // Don't schedule if notifications are muted
    if (profile?.muteNotifications ?? false) return;

    // Schedule all task notifications
    for (final task in tasks) {
      final taskDateTime = DateTime(
        task.date.year,
        task.date.month,
        task.date.day,
        task.time.hour,
        task.time.minute,
      );
      await _scheduleTaskNotification(
        task.taskId.hashCode,
        task.title,
        taskDateTime,
      );
    }

    // Schedule morning and evening habit notifications
    for (final hobby in hobbies) {
      // Morning notification (8:00 AM)
      await _scheduleMorningNotification(
        hobby.hobbyId.hashCode,
        _notificationService.getRandomMorningHabitMessage(),
        const TimeOfDay(hour: 8, minute: 0),
      );

      // Evening notification (9:00 PM)
      await _scheduleEveningNotification(
        hobby.hobbyId.hashCode,
        _notificationService.getRandomEveningHabitMessage(),
        const TimeOfDay(hour: 21, minute: 0),
      );
    }
  }

  Future<void> _scheduleTaskNotification(
    int id,
    String title,
    DateTime taskTime,
  ) async {
    final message = _notificationService.getRandomTaskReminder();
    await _notificationService.scheduleTaskReminder(
      id: id,
      title: title,
      body: message,
      scheduledTime: taskTime,
    );
  }

  Future<void> _scheduleMorningNotification(
    int hobbyId,
    String message,
    TimeOfDay time,
  ) async {
    await _notificationService.scheduleMorningHabitReminder(
      id: hobbyId,
      body: message,
      morningTime: time,
    );
  }

  Future<void> _scheduleEveningNotification(
    int hobbyId,
    String message,
    TimeOfDay time,
  ) async {
    await _notificationService.scheduleEveningHabitReminder(
      id: hobbyId,
      body: message,
      eveningTime: time,
    );
  }

  // Check and reschedule notifications if needed (e.g., after device reboot)
  // Note: flutter_local_notifications can't reschedule when app is killed,
  // so this only works when app is reopened
  void _checkAndRescheduleNotificationsIfNeeded() {
    // For now, we always reschedule on app start to ensure notifications are active
    // In a perfect world, we'd check a flag set by BootCompleteReceiver,
    // but since we can't access Android shared prefs easily from Flutter,
    // we just ensure notifications are scheduled when app starts
    unawaited(
      _scheduleAllNotifications().catchError((e) {
        debugPrint('Notification rescheduling failed: $e');
      }),
    );
  }

  // Data Management ----------------------------------------------------------
  Future<String> exportData() async {
    final data = {
      'profile': profile?.toJson(),
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'hobbies': hobbies.map((h) => h.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'focusedDate': focusedDate.toIso8601String(),
      'version': '1.0.0',
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  Future<void> importData(String jsonString) async {
    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version or structure if needed
      // if (data['version'] != '1.0.0') throw Exception('Incompatible version');

      // Clear existing data
      await _storage.saveProfile(null);
      await _storage.saveTasks([]);
      await _storage.saveHobbies([]);
      await _storage.saveNotes([]);

      // Import Profile
      if (data['profile'] != null) {
        profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
        await _storage.saveProfile(profile);
      }

      // Import Tasks
      if (data['tasks'] != null) {
        tasks = (data['tasks'] as List)
            .map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList();
        await _storage.saveTasks(tasks);
      }

      // Import Hobbies
      if (data['hobbies'] != null) {
        hobbies = (data['hobbies'] as List)
            .map((h) => Hobby.fromJson(h as Map<String, dynamic>))
            .toList();
        await _storage.saveHobbies(hobbies);
      }

      // Import Notes
      if (data['notes'] != null) {
        notes = (data['notes'] as List)
            .map((n) => Note.fromJson(n as Map<String, dynamic>))
            .toList();
        await _storage.saveNotes(notes);
      }

      // Import Focused Date
      if (data['focusedDate'] != null) {
        focusedDate = DateTime.parse(data['focusedDate'] as String);
        await _storage.saveFocusedDate(focusedDate);
      }

      // Re-initialize notifications
      await _notificationService.cancelAllNotifications();
      await _scheduleAllNotifications();

      notifyListeners();
    } catch (e) {
      debugPrint('Import failed: $e');
      rethrow; // Let UI handle the error
    }
  }

  // Data reset ---------------------------------------------------------------
  Future<void> resetAllData() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (e) {
      debugPrint('Failed to cancel notifications during reset: $e');
    }

    await _storage.clearAll();

    profile = null;
    tasks = [];
    hobbies = [];
    notes = [];
    focusedDate = DateTime.now();
    lastSpinDate = null;
    _lastColorIndex = 0;

    notifyListeners();
  }
}
