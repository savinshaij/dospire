import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/notification_service.dart';
import '../state/app_state.dart';

// Colors matching profile
class TestingColors {
  static const bg = Color(0xFFFAFBFF);
  static const textMain = Color(0xFF1A1D2B);
  static const textLight = Color(0xFF6B7280);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFF000000);
}

class TestingScreen extends StatefulWidget {
  const TestingScreen({super.key});

  @override
  State<TestingScreen> createState() => _TestingScreenState();
}

class _TestingScreenState extends State<TestingScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;
  List<PendingNotificationRequest> _pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _loadPendingNotifications() async {
    final pending = await _notificationService.getPendingNotifications();
    setState(() {
      _pendingNotifications = pending;
    });
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
    setState(() {
      _isInitialized = _notificationService.isInitialized;
    });
    _loadPendingNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final allItems = [
          ...state.tasks.map((task) => {'type': 'task', 'item': task}),
          ...state.hobbies.map((habit) => {'type': 'habit', 'item': habit}),
        ];

        return Scaffold(
          backgroundColor: TestingColors.bg,
          appBar: AppBar(
            backgroundColor: TestingColors.bg,
            elevation: 0,
            title: const Text(
              'Testing Console',
              style: TextStyle(
                color: TestingColors.textMain,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: TestingColors.textMain),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: TestingColors.textMain),
                onPressed: _loadPendingNotifications,
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Errors & Logs
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TestingColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TestingColors.border, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Errors & Logs',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: TestingColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getLogs(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                            color: TestingColors.textMain,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Test Notification Button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TestingColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TestingColors.border, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Test Notification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: TestingColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _isInitialized
                              ? () async {
                                  await _notificationService.showTestNotification(
                                    'Test Notification',
                                    'If you see this, notifications are working! 📲',
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Test notification sent'),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: const Text('Send Test Notification'),
                        ),
                        if (!_isInitialized)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Initializing notifications...',
                              style: TextStyle(color: TestingColors.textLight),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Permissions Check
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TestingColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TestingColors.border, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Permissions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: TestingColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<bool>(
                          future: _notificationService
                              .checkExactAlarmPermission(),
                          builder: (context, snapshot) {
                            final hasPermission = snapshot.data ?? false;
                            return Row(
                              children: [
                                Icon(
                                  hasPermission
                                      ? Icons.check_circle
                                      : Icons.error,
                                  color: hasPermission
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    hasPermission
                                        ? 'Exact Alarms Allowed'
                                        : 'Exact Alarms NOT Allowed',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: hasPermission
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ),
                                if (!hasPermission)
                                  TextButton(
                                    onPressed: () {
                                      _notificationService.requestPermissions();
                                    },
                                    child: const Text('Fix'),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Pending System Notifications
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TestingColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TestingColors.border, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pending System Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: TestingColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Actually scheduled in OS',
                          style: TextStyle(
                            fontSize: 12,
                            color: TestingColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_pendingNotifications.isEmpty)
                          const Text(
                            'No pending notifications found in system.',
                            style: TextStyle(
                              fontSize: 14,
                              color: TestingColors.textLight,
                            ),
                          )
                        else
                          ..._pendingNotifications.map((notification) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: TestingColors.bg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: TestingColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ID: ${notification.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: TestingColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    notification.title ?? 'No Title',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: TestingColors.textMain,
                                    ),
                                  ),
                                  Text(
                                    notification.body ?? 'No Body',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: TestingColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // App State Scheduled Items
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TestingColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TestingColors.border, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'App State Schedule',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: TestingColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'What the app *thinks* is scheduled',
                          style: TextStyle(
                            fontSize: 12,
                            color: TestingColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (allItems.isEmpty)
                          const Text(
                            'No tasks or habits scheduled in app state.',
                            style: TextStyle(
                              fontSize: 14,
                              color: TestingColors.textLight,
                            ),
                          )
                        else
                          ...allItems.map((data) {
                            if (data['type'] == 'task') {
                              final task = data['item'] as Task;
                              return _buildScheduledItem(
                                'Task: ${task.title}',
                                '${task.date.toString().split(' ')[0]} ${task.time.format(context)}',
                              );
                            } else {
                              final habit = data['item'] as Hobby;
                              String timeText = habit.time != null
                                  ? 'Time: ${habit.time!.format(context)}'
                                  : 'No specific time set';
                              return _buildScheduledItem(
                                'Habit: ${habit.title}',
                                'Period: ${habit.periodStart.toString().split(' ')[0]} - ${habit.periodEnd.toString().split(' ')[0]}\n$timeText',
                              );
                            }
                          }),
                        const SizedBox(height: 12),
                        const Text(
                          'Note: If notifications are not received, check app permissions and device settings.',
                          style: TextStyle(
                            fontSize: 12,
                            color: TestingColors.textLight,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLogs() {
    final appState = context.read<AppState>();
    final now = DateTime.now();
    final timezone = now.timeZoneName;
    final offset = now.timeZoneOffset;

    final serviceLogs = _notificationService.getDebugLog();

    final systemInfo =
        '''
[INFO] App started successfully
[INFO] Notification service initialized: $_isInitialized
[DEBUG] Current time: ${now.toString()}
[DEBUG] Timezone: $timezone (UTC${offset.isNegative ? '' : '+'}${offset.inHours}:${(offset.inMinutes % 60).toString().padLeft(2, '0')})
[DEBUG] Loaded ${appState.tasks.length} tasks
[DEBUG] Loaded ${appState.hobbies.length} habits
[DEBUG] System scheduled: ${_pendingNotifications.length} notifications
[DEBUG] Notifications muted: ${appState.profile?.muteNotifications ?? false}
''';

    if (serviceLogs.isEmpty) {
      return '$systemInfo\n[INFO] No recent notification actions recorded.';
    }

    return '$systemInfo\n--- RECENT ACTIONS ---\n${serviceLogs.reversed.join('\n')}';
  }

  Widget _buildScheduledItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TestingColors.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TestingColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: TestingColors.textMain,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: TestingColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}
