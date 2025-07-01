import 'dart:io';
// import 'package:alarm/payment_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'models/api_key_entry.dart';
import 'models/topic_entry.dart';
import 'models/tip_entry.dart';
import 'models/notification_schedule_entry.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notifications.dart';
import 'services/tip_generation_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      print('Notification tapped: ${response.payload}');
    },
  );

  // Request notification permission on Android 13+
  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        print('Notification permission not granted.');
      }
    }
  }

  // Setup initial notification schedules
  await _setupInitialNotifications();

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
      return const WelcomeScreen();
    }
  }
}
