import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'models/api_key_entry.dart';
import 'models/topic_entry.dart';
import 'models/tip_entry.dart';
import 'models/notification_schedule_entry.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/notifications.dart';
import 'services/tip_generation_service.dart';
import 'screens/tip_viewer_screen.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Cancel all scheduled and shown notifications when app is resumed
      cancelAllScheduledNotifications();
      // Optionally, cancel native notification with a known ID (0 for default)
      cancelNativeNotification(notificationId: 0);
    }
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addObserver(AppLifecycleHandler());
  await registerBackgroundTipTask();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ApiKeyEntryAdapter());
  Hive.registerAdapter(TopicEntryAdapter());
  Hive.registerAdapter(TipEntryAdapter());
  Hive.registerAdapter(NotificationScheduleEntryAdapter());

  // Open Hive boxes
  await Hive.openBox('settings');
  await Hive.openBox<ApiKeyEntry>('apiKeys');
  await Hive.openBox<TopicEntry>('topics');
  await Hive.openBox<TipEntry>('tips');
  await Hive.openBox<NotificationScheduleEntry>('notificationSchedules');

  // Initialize timezone data for notifications
  tz.initializeTimeZones();

  // Notification setup
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
    requestSoundPermission: true,
    requestBadgePermission: true,
    requestAlertPermission: true,
  );
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Handle notification tap
      if (response.payload != null && response.payload!.isNotEmpty) {
        try {
          final payload = response.payload!;
          // Try to parse as Map (from toString), fallback to raw string
          final tipData = _parseNotificationPayload(payload);
          if (tipData != null) {
            navigatorKey.currentState?.push(
              CupertinoPageRoute(
                builder: (context) => TipViewerScreen(
                  tip: tipData['tip'] ?? '',
                  title: tipData['title'] ?? '',
                  topic: tipData['topic'] ?? '',
                ),
              ),
            );
          }
        } catch (e) {
          print('Failed to parse notification payload: $e');
        }
      }
    },
  );

  // Request notification permission on Android 13+
  // (Removed: now handled only in onboarding dialog)
  // if (Platform.isAndroid) {
  //   final androidInfo = await DeviceInfoPlugin().androidInfo;
  //   if (androidInfo.version.sdkInt >= 33) {
  //     final status = await Permission.notification.request();
  //     if (!status.isGranted) {
  //       print('Notification permission not granted.');
  //     }
  //   }
  // }

  // Setup initial notification schedules
  await _setupInitialNotifications();

  // Setup native notification callbacks
  setupNativeNotificationCallbacks(
    onTipRead: (data) => print('Native: Tip Read: ' + data.toString()),
    onTipShare: (data) => print('Native: Tip Share: ' + data.toString()),
    onTipSave: (data) => print('Native: Tip Save: ' + data.toString()),
    onTipDismiss: (data) => print('Native: Tip Dismiss: ' + data.toString()),
    onNotificationShown: (data) =>
        print('Native: Notification Shown: ' + data.toString()),
  );

  runApp(const MyApp());
}

Future<void> _setupInitialNotifications() async {
  final settings = Hive.box('settings');
  final notificationsEnabled =
      settings.get('notificationsEnabled', defaultValue: true);

  if (notificationsEnabled) {
    // Schedule smart tip notifications if enabled
    final autoGenerateTips =
        settings.get('autoGenerateTips', defaultValue: false);
    if (autoGenerateTips) {
      await scheduleSmartTipNotification();
    }

    // Generate and schedule tips for today
    await TipGenerationService.generateAndScheduleTips();

    // Clean up old tips
    await TipGenerationService.cleanupOldTips();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Daily Tips',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        brightness: Brightness.light,
      ),
      navigatorKey: navigatorKey,
      home: _getInitialScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/welcome': (context) => const WelcomeScreen(),
      },
    );
  }

  Widget _getInitialScreen() {
    final settings = Hive.box('settings');
    final hasSeenWelcome = settings.get('hasSeenWelcome', defaultValue: false);

    if (hasSeenWelcome) {
      return const HomeScreen();
    } else {
      return const OnboardingScreen();
    }
  }
}

Map<String, dynamic>? _parseNotificationPayload(String payload) {
  // Try to parse a Map from the payload string
  try {
    // Remove curly braces and newlines
    final map = <String, dynamic>{};
    final cleaned = payload.replaceAll(RegExp(r'[{}\n]'), '');
    for (final part in cleaned.split(',')) {
      final kv = part.split(':');
      if (kv.length >= 2) {
        final key = kv[0].trim();
        final value = kv.sublist(1).join(':').trim();
        map[key] = value;
      }
    }
    return map;
  } catch (e) {
    return null;
  }
}
