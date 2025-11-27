import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app_theme.dart';
import 'firebase_options.dart';
import 'models/models.dart';
import 'screens/splash_screen.dart';
import 'services/hive_storage_service.dart';
import 'services/notification_service.dart';
import 'services/remote_config_service.dart';
import 'state/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Remote Config
  await RemoteConfigService.instance.initialize();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(HobbyAdapter());
  Hive.registerAdapter(HobbyFrequencyAdapter());
  Hive.registerAdapter(NoteAdapter());

  // Initialize Storage Service
  final storageService = HiveStorageService();
  await storageService.init();

  // Initialize Notification Service (for permissions/channels)
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Lock Orientation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runZonedGuarded(
    () async {
      runApp(
        MultiProvider(
          providers: [
            Provider<HiveStorageService>.value(value: storageService),
            ChangeNotifierProvider(
              create: (_) => AppState(storageService)..hydrate(),
            ),
          ],
          child: const DoSpireApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Global Error: $error');
      debugPrint('Stack Trace: $stack');
      // Here you could log to a service like Crashlytics
    },
  );
}

class DoSpireApp extends StatelessWidget {
  const DoSpireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        // Show loading indicator while hydrating
        if (!state.isReady) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.black),
              ),
            ),
          );
        }

        return MaterialApp(
          title: 'DoSpire',
          debugShowCheckedModeBanner: false,
          theme: DoSpireTheme.light,
          // Removed themeMode and darkTheme
          home: const SplashScreen(),
        );
      },
    );
  }
}
