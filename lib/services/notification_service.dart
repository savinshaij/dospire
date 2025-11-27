import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

// --- NOTIFICATION MESSAGES ---
class NotificationMessages {
  static const List<String> taskReminders = [
    "Hey there! Time to tackle this task - you've got this! 🚀",
    "Your schedule says it's time! Let's get this task done. ⏰",
    "Reminder: This task is waiting for your awesome energy! 💪",
    "Wake up! Your task needs your attention right now📝",
    "It's time! Let's turn this task into a completed success ✅",
    "Ignoring this won't make it smaller… unlike some people I know 😏",
    "You're not busy, you're just bad at time management and coping 😂",
    "Stop being a little bitch and handle your shit 🥱",
    "This task wants to be dominated. Be a good dom and finish it🥵",
    "Bend over and take care of this task like you mean it 🍑💦",
    "Good morning, you gorgeous waste of potential😇",
    "Touch grass? Nah, touch this task first😒",
    "Congrats, you've successfully done nothing… again. Fix it🎉🍾",
    "I'll ride your notifications until you do it. Your choice😤",
    "Congratulations, you're speed-running disappointment. Do the task, champ🎉🎊",
    "Do it before I moan the deadline👄",
    "Get it done, you gorgeous failure😤",
    "This is why nobody trusts you with secrets OR deadlines🤣",
    "Don't forget! This task is on your agenda for now. 🎯",
    "Ready, set, go! Your task awaits your brilliance. 🌟",
    "Tick-tock! Time to check off this important task. ⌚",
    "Your productivity moment is here! Let's conquer this task. 🔥",
    "Heads up! This task is due for some action from you. 💼",
  ];

  static const List<String> morningHabits = [
    "Good morning sunshine! Let's start the day with your healthy habits. ☀️",
    "Rise and shine! Time to nurture those positive habits. 🌅",
    "Morning boost! Ready to build your habits bright and early? 🌞",
    "Good morning habit champion! Let's make today amazing. ✨",
    "Hello, beautiful day! Time to strengthen your habits. 🌈",
    "Rise with purpose! Your morning habits await. 🌺",
    "Start strong! Let's build those healthy habits together. 💐",
    "Morning magic! Ready to nourish your habits? 🌸",
    "Dawn of greatness! Let's cultivate your morning routines. 🌹",
    "Good morning, habit hero! Time to shine! ⭐",
    "Rise and grind, lazy ass dominate every inch",
    "Good morning beast, bend the day over and take it. 😈",
    "Morning bitch, get up and finish strong today.😏",
    "Rise, you snooze-button simp. Today's begging for a real champ.",
    "Morning, quitter. Your streak's lonelier than your inbox—fix it.",
    "Yo, dreamer, stop drooling and start doing. Goals don't chase themselves.",
    "Wake up, wannabe. Your to-do list is laughing at your pathetic hustle.",
    "Morning, basic. Your habits called—they're embarrassed to know you.",
    "Hey, flop, get up. Your potentials rotting faster than your leftovers.",
    "Good morning, nobody. Prove you're somebody or stay a snooze forever. 😈",
  ];

  static const List<String> eveningHabits = [
    "Evening, bitch. Did you nut inside your habits today? 🌙",
    "Reflection, slut. How many times did you make them cum? 🌌",
    "Day's over, loser. Habits still dry and begging? 🌃",
    "Habit check, weakling. They're tight and untouched. 🌓",
    "Night roast: Your streak's throbbing, simp—finish it. 🌕",
    "Sun down, dreams leaking. Pound them one last time. 🌑",
    "Finish the routine, quitter, or leave them edged again. 🏁",
    "Sleep soon, failure. Did your habits squirt progress? 😴",
    "Evening wins? Make those habits gag on victory. 🎉",
    "Lock in, coward. Rail them raw before bed. 🔒😈",
    "Evening, lazy fuck. Did you even touch your habits or just edge all day? 🌙",
    "Reflection time, quitter. Your streak's drier than your love life. 🌌",
    "Day's over, flop. Habits still starving while you scrolled like a loser? 🌃",
    "Habit check, weakling. They look pathetic—feed them or stay trash. 🌓",
    "Night roast: Your potential's leaking. Finish strong or stay soft. 🌕",
    "Sun's down, dreams dying. Pound your routine or admit you're weak. 🌑",
    "Close the day, coward. Lock in wins or keep sucking at life. 🏁",
    "Sleep soon, failure. Made your habits cum progress yet? 😴",
    "Evening summary, basic bitch. Celebrate real wins or stay mediocre. 🎉",
    "Lock it in tonight, simp. Rail tomorrow's version of you or rot. 🔒😈",
  ];
}

// --- NOTIFICATION SERVICE ---
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  static const String _channelId = 'dospire_notifications';
  static const String _channelName = 'DoSpire Notifications';
  static const String _channelDescription = 'All app notifications';

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  final List<String> _logs = [];

  List<String> getDebugLog() => List.unmodifiable(_logs);

  void _log(String message) {
    final timestamp = DateTime.now()
        .toIso8601String()
        .split('T')[1]
        .split('.')[0];
    _logs.add('[$timestamp] $message');
    if (_logs.length > 50) _logs.removeAt(0); // Keep last 50 logs
  }

  NotificationService._internal() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  }

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    // Initialize plugin
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // EXPLICITLY CREATE CHANNELS (Android 8+)
    // This ensures they appear in settings even before a notification is scheduled
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      // Consolidate into a single channel as requested
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _isInitialized = true;
    _log('Service initialized');
  }

  void _onNotificationResponse(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> requestPermissions() async {
    // Android permissions
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }

    // iOS permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<bool> checkExactAlarmPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidImplementation == null) return true; // Not Android

    // Check if we can schedule exact alarms
    // Note: The plugin doesn't expose a direct "checkPermission" for exact alarms easily
    // in all versions, but we can infer or just rely on the request.
    // However, for debugging, we can try to see if the OS allows it.
    // Since the plugin wrapper is thin, we might not have a direct boolean check exposed
    // without using another package (like permission_handler).
    // BUT, we can assume if we requested it, we might have it.
    // For now, we'll return true to avoid blocking, but in a real app we'd use
    // permission_handler to check Permission.scheduleExactAlarm.status
    return true;
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    // Logic: Schedule 5 minutes before, UNLESS that time is already past.
    // If 5 min before is past, but the task itself is still in the future,
    // schedule for the exact task time.

    DateTime notificationTime = scheduledTime.subtract(
      const Duration(minutes: 5),
    );

    final now = DateTime.now();

    if (notificationTime.isBefore(now)) {
      // 5 min before is in the past.
      // Check if the actual task time is still in the future.
      if (scheduledTime.isAfter(now)) {
        // Yes, task is in future. Schedule for exact time.
        // Add a small buffer (5s) if it's extremely close to now to ensure scheduling works
        if (scheduledTime.difference(now).inSeconds < 5) {
          notificationTime = now.add(const Duration(seconds: 5));
        } else {
          notificationTime = scheduledTime;
        }
      } else {
        // Task is already in the past. Don't schedule.
        _log('Skipped past task: $id ($title)');
        return;
      }
    }

    final tz.TZDateTime tzTime = tz.TZDateTime.from(notificationTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false, // Disabled to prevent auto-opening
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      sound: 'notification_sound.aiff',
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      _log('Scheduled task $id at $tzTime');
    } catch (e) {
      _log('Error scheduling task $id: $e');
      debugPrint('Error scheduling task reminder: $e');
      // This often fails if Exact Alarm permission is denied
    }
  }

  Future<void> scheduleMorningHabitReminder({
    required int id,
    required String body,
    required TimeOfDay morningTime, // e.g., 8:00 AM
  }) async {
    final DateTime now = DateTime.now();
    final DateTime nextMorning = DateTime(
      now.year,
      now.month,
      now.day,
      morningTime.hour,
      morningTime.minute,
    );

    // If morning time has passed today, schedule for tomorrow
    DateTime scheduledTime = nextMorning;
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false, // Disabled
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id + 1000, // Offset morning notifications by 1000
        'Morning Habits',
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    } catch (e) {
      debugPrint('Error scheduling morning habit: $e');
      _log('Error scheduling morning habit: $e');
    }
    _log('Scheduled morning habit at $tzTime');
  }

  Future<void> scheduleEveningHabitReminder({
    required int id,
    required String body,
    required TimeOfDay eveningTime, // e.g., 9:00 PM
  }) async {
    final DateTime now = DateTime.now();
    final DateTime nextEvening = DateTime(
      now.year,
      now.month,
      now.day,
      eveningTime.hour,
      eveningTime.minute,
    );

    // If evening time has passed today, schedule for tomorrow
    DateTime scheduledTime = nextEvening;
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'hobuu_notifications',
          'Hobuu Notifications',
          channelDescription: 'All app notifications',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: false, // Disabled
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id + 2000, // Offset evening notifications by 2000
        'Evening Habits',
        body,
        tzTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
    } catch (e) {
      debugPrint('Error scheduling evening habit: $e');
      _log('Error scheduling evening habit: $e');
    }
    _log('Scheduled evening habit at $tzTime');
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
    _log('Cancelled notification $id');
  }

  Future<void> cancelMorningNotification(int habitId) async {
    await _flutterLocalNotificationsPlugin.cancel(habitId + 1000);
    _log('Cancelled morning habit ${habitId + 1000}');
  }

  Future<void> cancelEveningNotification(int habitId) async {
    await _flutterLocalNotificationsPlugin.cancel(habitId + 2000);
    _log('Cancelled evening habit ${habitId + 2000}');
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    _log('Cancelled ALL notifications');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Show notification immediately (for testing)
  Future<void> showTestNotification(String title, String body) async {
    if (!_isInitialized) {
      await initialize();
    }

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: false, // Disabled
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      details,
    );
    _log('Shown test notification: $title');
  }

  String getRandomTaskReminder() {
    final randomIndex =
        DateTime.now().millisecond % NotificationMessages.taskReminders.length;
    return NotificationMessages.taskReminders[randomIndex];
  }

  String getRandomMorningHabitMessage() {
    final randomIndex =
        DateTime.now().millisecond % NotificationMessages.morningHabits.length;
    return NotificationMessages.morningHabits[randomIndex];
  }

  String getRandomEveningHabitMessage() {
    final randomIndex =
        DateTime.now().millisecond % NotificationMessages.eveningHabits.length;
    return NotificationMessages.eveningHabits[randomIndex];
  }
}
