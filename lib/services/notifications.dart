import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:hive/hive.dart';
import '../models/tip_entry.dart';
import '../models/notification_schedule_entry.dart';
import '../models/topic_entry.dart';
import '../models/api_key_entry.dart';
import '../models/gemini_model.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const MethodChannel _nativeNotificationChannel =
    MethodChannel('com.example.alarm/notifications');

const String backgroundTipTask = 'backgroundTipTask';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundTipTask) {
      final topicsBox = await Hive.openBox<TopicEntry>('topics');
      final topics = topicsBox.values.toList();
      if (topics.isNotEmpty) {
        final random = Random();
        final selectedTopic = topics[random.nextInt(topics.length)].topic;
        // Generate a full tip using the existing logic
        final settings = await Hive.openBox('settings');
        final apiKeyBox = await Hive.openBox<ApiKeyEntry>('apiKeys');
        final selectedApiKeyIndex =
            settings.get('selectedApiKeyIndex', defaultValue: 0);
        String apiKey = '';
        if (apiKeyBox.isNotEmpty && selectedApiKeyIndex < apiKeyBox.length) {
          apiKey = apiKeyBox.getAt(selectedApiKeyIndex)?.key ?? '';
        }
        String tip = 'Here is your random AI tip about $selectedTopic!';
        if (apiKey.isNotEmpty) {
          try {
            tip = await _generateTipForTopic(selectedTopic, apiKey);
          } catch (_) {}
        }
        final tipId = 'random_tip_${DateTime.now().millisecondsSinceEpoch}';
        final notificationId = generateNotificationId(tipId);
        await showTipNotification(
          tip,
          useNative: true,
          tipId: tipId,
          notificationId: notificationId,
          topic: selectedTopic,
        );
      }
    }
    return Future.value(true);
  });
}

Future<void> registerBackgroundTipTask() async {
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  await Workmanager().registerPeriodicTask(
    '1',
    backgroundTipTask,
    frequency: const Duration(hours: 24), // Once a day
    initialDelay: const Duration(minutes: 1), // For quick test, then remove
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );
}

Future<void> showTipNotification(String tip,
    {List<String>? references,
    bool useNative = false,
    String? tipId,
    int? notificationId,
    String? topic}) async {
  debugPrint(
      '[Notifications] showTipNotification called. useNative=$useNative tipId=$tipId notificationId=$notificationId topic=$topic');
  // Save to Hive
  final tipsBox = Hive.box<TipEntry>('tips');
  await tipsBox.add(TipEntry(tip: tip, references: references));

  // Extract title and overview
  final title = _extractTitleFromTip(tip) ?? 'Your Daily Tip';
  final overview = _extractOverviewFromTip(tip);
  final topicName = topic ??
      (references != null && references.isNotEmpty ? references.first : '');
  final payload = {
    'tip': tip,
    'title': title,
    'overview': overview,
    'topic': topicName,
  };

  if (useNative && tipId != null && notificationId != null) {
    debugPrint('[Notifications] Invoking native notification channel');
    await _nativeNotificationChannel.invokeMethod('showNativeNotification', {
      'tipText': tip,
      'tipId': tipId,
      'notificationId': notificationId,
      'title': title,
      'overview': overview,
      'topic': topicName,
      'payload': payload,
    });
    debugPrint('[Notifications] Native notification invoked successfully');
    return;
  }

  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'daily_tips',
    'Daily Tips',
    channelDescription: 'Notification channel for daily tips',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const DarwinNotificationDetails iOSPlatformChannelSpecifics =
      DarwinNotificationDetails();
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: androidPlatformChannelSpecifics,
    iOS: iOSPlatformChannelSpecifics,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    overview,
    platformChannelSpecifics,
    payload: payload.toString(),
  );
  debugPrint('[Notifications] Local notification shown with title="$title"');
}

String? _extractTitleFromTip(String tip) {
  final lines = tip.split('\n');
  for (final line in lines) {
    if (line.startsWith('## Tip Title')) {
      final titleIndex = lines.indexOf(line);
      for (int i = titleIndex + 1; i < lines.length; i++) {
        final titleLine = lines[i].trim();
        if (titleLine.isNotEmpty &&
            !titleLine.startsWith('#') &&
            !titleLine.startsWith('[') &&
            !titleLine.startsWith('*')) {
          return titleLine.replaceAll(RegExp(r'[\[\]"]'), '');
        }
      }
    }
    if (line.startsWith('## ') && !line.contains('Tip Title')) {
      return line.replaceAll('## ', '').trim();
    }
  }
  return null;
}

String _extractOverviewFromTip(String tip) {
  final lines = tip.split('\n');
  final buffer = StringBuffer();
  bool inTipSection = false;
  for (final line in lines) {
    if (line.trim().toLowerCase().startsWith('## the tip')) {
      inTipSection = true;
      continue;
    }
    if (inTipSection) {
      if (line.trim().startsWith('## ')) break;
      if (line.trim().isNotEmpty) buffer.writeln(line.trim());
      if (buffer.length > 120) break;
    }
  }
  final result = buffer.toString().trim();
  return result.isNotEmpty
      ? result
      : tip
          .split('\n')
          .firstWhere((l) => l.trim().isNotEmpty, orElse: () => tip)
          .trim();
}

Future<void> scheduleDailyTipNotification(String tip,
    {List<String>? references,
    int hour = 8,
    int minute = 0,
    int intervalDays = 1}) async {
  try {
    tz.initializeTimeZones();
    debugPrint(
        '[Notifications] scheduleDailyTipNotification hour=$hour minute=$minute intervalDays=$intervalDays');
    String body = tip;
    if (references != null && references.isNotEmpty) {
      body += '\n\nReferences:\n' + references.join('\n');
    }
    // Save to Hive
    final tipsBox = Hive.box<TipEntry>('tips');
    await tipsBox.add(TipEntry(tip: tip, references: references));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Your Daily Tip',
      body,
      _nextInstanceOfTimeWithInterval(hour, minute, intervalDays),
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_tips', 'Daily Tips',
            channelDescription: 'Notification channel for daily tips'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('[Notifications] Daily tip scheduled successfully');
  } catch (e) {
    // Handle exact alarms permission issues gracefully
    print('Notification scheduling failed: $e');

    // Check if it's an exact alarms permission issue
    if (e.toString().contains('exact_alarms_not_permitted')) {
      throw Exception(
          'Exact alarms permission required for scheduling notifications');
    }

    // Re-throw other exceptions
    rethrow;
  }
}

Future<void> cancelDailyTipNotification() async {
  await flutterLocalNotificationsPlugin.cancel(0);
}

Future<void> scheduleAllCustomNotifications(String tip,
    {List<String>? references}) async {
  tz.initializeTimeZones();
  final schedulesBox =
      Hive.box<NotificationScheduleEntry>('notificationSchedules');
  final now = tz.TZDateTime.now(tz.local);

  for (var schedule in schedulesBox.values.where((s) => s.enabled)) {
    // Check date range
    if (schedule.startDate != null &&
        now.isBefore(tz.TZDateTime.from(schedule.startDate!, tz.local)))
      continue;
    if (schedule.endDate != null &&
        now.isAfter(tz.TZDateTime.from(schedule.endDate!, tz.local))) continue;

    // For each time
    for (int i = 0; i < schedule.hours.length; i++) {
      int hour = schedule.hours[i];
      int minute = schedule.minutes[i];
      // For each weekday (if set)
      if (schedule.weekdays != null && schedule.weekdays!.isNotEmpty) {
        for (var weekday in schedule.weekdays!) {
          final uniqueId = schedule.key.hashCode ^ hour ^ minute ^ weekday;
          await flutterLocalNotificationsPlugin.zonedSchedule(
            uniqueId,
            schedule.title ?? 'Your Daily Tip',
            _buildNotificationBody(tip, references),
            _nextInstanceOfWeekdayTime(hour, minute, weekday),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_tips',
                'Daily Tips',
                channelDescription: 'Notification channel for daily tips',
                groupKey: schedule.title ?? 'Daily Tips',
                importance: Importance.max,
                priority: Priority.high,
                styleInformation: BigTextStyleInformation(
                    _buildNotificationBody(tip, references)),
                sound: schedule.customSound != null
                    ? RawResourceAndroidNotificationSound(schedule.customSound!)
                    : null,
                actions: <AndroidNotificationAction>[
                  AndroidNotificationAction('mark_read', 'Mark as Read'),
                  AndroidNotificationAction('save', 'Save'),
                  AndroidNotificationAction('share', 'Share'),
                ],
              ),
              iOS: DarwinNotificationDetails(
                sound: schedule.customSound,
                // Add actions for iOS if needed
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else {
        // Interval or daily
        final uniqueId = schedule.key.hashCode ^ hour ^ minute;
        await flutterLocalNotificationsPlugin.zonedSchedule(
          uniqueId,
          schedule.title ?? 'Your Daily Tip',
          _buildNotificationBody(tip, references),
          schedule.intervalDays != null
              ? _nextInstanceOfTimeWithInterval(
                  hour, minute, schedule.intervalDays!)
              : _nextInstanceOfTime(hour, minute),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'daily_tips',
              'Daily Tips',
              channelDescription: 'Notification channel for daily tips',
              groupKey: schedule.title ?? 'Daily Tips',
              importance: Importance.max,
              priority: Priority.high,
              styleInformation: BigTextStyleInformation(
                  _buildNotificationBody(tip, references)),
              sound: schedule.customSound != null
                  ? RawResourceAndroidNotificationSound(schedule.customSound!)
                  : null,
              actions: <AndroidNotificationAction>[
                AndroidNotificationAction('mark_read', 'Mark as Read'),
                AndroidNotificationAction('save', 'Save'),
                AndroidNotificationAction('share', 'Share'),
              ],
            ),
            iOS: DarwinNotificationDetails(
              sound: schedule.customSound,
              // Add actions for iOS if needed
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents:
              schedule.intervalDays != null ? null : DateTimeComponents.time,
        );
      }
    }
  }
}

String _buildNotificationBody(String tip, List<String>? references) {
  String body = tip;
  if (references != null && references.isNotEmpty) {
    body += '\n\nReferences:\n' + references.join('\n');
  }
  return body;
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  var scheduled =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

tz.TZDateTime _nextInstanceOfTimeWithInterval(
    int hour, int minute, int intervalDays) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  var scheduled =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  if (scheduled.isBefore(now)) {
    scheduled = scheduled.add(Duration(days: intervalDays));
  }
  return scheduled;
}

tz.TZDateTime _nextInstanceOfWeekdayTime(int hour, int minute, int weekday) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduled =
      tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

// Smart tip notification that generates tips from available topics
Future<void> scheduleSmartTipNotification() async {
  final topicsBox = Hive.box<TopicEntry>('topics');
  final apiKeysBox = Hive.box<ApiKeyEntry>('apiKeys');
  final settings = Hive.box('settings');

  final topics = topicsBox.values.toList();
  final apiKeys = apiKeysBox.values.toList();
  final selectedApiKeyIndex =
      settings.get('selectedApiKeyIndex', defaultValue: 0);

  if (topics.isEmpty ||
      apiKeys.isEmpty ||
      selectedApiKeyIndex >= apiKeys.length) {
    // Fallback to generic tip
    await showTipNotification(
        'Take a moment today to reflect on your goals and progress. Small steps lead to big achievements!',
        references: ['Daily Tips App']);
    return;
  }

  // Select a random topic
  final random = Random();
  final selectedTopic = topics[random.nextInt(topics.length)];
  final selectedApiKey = apiKeys[selectedApiKeyIndex];

  try {
    final tipText =
        await _generateTipForTopic(selectedTopic.topic, selectedApiKey.key);
    await showTipNotification(tipText,
        references: ['Topic: ${selectedTopic.topic}']);
  } catch (e) {
    // Fallback tip if API fails
    await showTipNotification(
        'Focus on ${selectedTopic.topic} today. What small action can you take to improve in this area?',
        references: ['Topic: ${selectedTopic.topic}']);
  }
}

// Export this function for use in tip_generation_service.dart
Future<String> generateTipForTopic(String topic, String apiKey) async {
  return await _generateTipForTopic(topic, apiKey);
}

Future<String> _generateTipForTopic(String topic, String apiKey) async {
  // Get the selected API key and its associated model
  final settings = Hive.box('settings');
  final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');
  final selectedApiKeyIndex =
      settings.get('selectedApiKeyIndex', defaultValue: 0);

  GeminiModel selectedModel = GeminiModel.defaultModel;

  // Try to get the model from the selected API key
  if (selectedApiKeyIndex < apiKeyBox.length) {
    final selectedApiKey = apiKeyBox.getAt(selectedApiKeyIndex);
    if (selectedApiKey != null) {
      selectedModel = selectedApiKey.model;
    }
  }

  final url = Uri.parse(selectedModel.generateApiUrl(apiKey));
  final body = jsonEncode({
    'contents': [
      {
        'parts': [
          {
            'text': '''
Generate a comprehensive, beginner-friendly tip about $topic for a mobile notification. 

Format your response as follows:

## Tip Title
[Compelling title that fits in a notification]

## The Tip
[A detailed, actionable tip that is 300-500 words. Make it beginner-friendly by:
- Explaining technical terms clearly
- Providing step-by-step guidance
- Including real-world examples
- Explaining WHY each step matters
If this is a programming topic, include brief code examples with comments.]

## Quick Action Steps
1. [First actionable step]
2. [Second step with specific details]
3. [Third step with expected outcome]

## ⚠️ Key Warning
[One important mistake to avoid]

## 🎯 Pro Tip
[One advanced technique or best practice]

REQUIREMENTS:
- Explain technical terms for beginners
- Include practical examples
- Make it educational and actionable
- Keep the title under 50 characters
- Focus on immediate value
'''
          }
        ]
      }
    ],
    'generationConfig': {
      'temperature': 0.7,
      'topK': 40,
      'topP': 0.95,
      'maxOutputTokens': 4096,
    }
  });

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final candidates = data['candidates'] as List?;
    if (candidates != null && candidates.isNotEmpty) {
      final text = candidates[0]['content']['parts'][0]['text'];
      return text.toString();
    } else {
      throw Exception('No tip returned by Gemini.');
    }
  } else {
    throw Exception('Gemini API error: ${response.body}');
  }
}

// Cancel all scheduled notifications
Future<void> cancelAllScheduledNotifications() async {
  await flutterLocalNotificationsPlugin.cancelAll();
}

// Get pending notification count
Future<int> getPendingNotificationCount() async {
  final pendingNotifications =
      await flutterLocalNotificationsPlugin.pendingNotificationRequests();
  return pendingNotifications.length;
}

// Schedule test notification
Future<void> scheduleTestNotification() async {
  await flutterLocalNotificationsPlugin.zonedSchedule(
    999, // Use a special ID for test notifications
    'Test Notification',
    'This is a test notification to verify that notifications are working properly.',
    tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Channel for test notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

Future<void> showNativeNotification({
  required String tipText,
  required String tipId,
  required int notificationId,
}) async {
  await _nativeNotificationChannel.invokeMethod('showNativeNotification', {
    'tipText': tipText,
    'tipId': tipId,
    'notificationId': notificationId,
  });
}

Future<void> updateNativeNotification({
  required String tipText,
  required String tipId,
  required int notificationId,
}) async {
  await _nativeNotificationChannel.invokeMethod('updateNativeNotification', {
    'tipText': tipText,
    'tipId': tipId,
    'notificationId': notificationId,
  });
}

Future<void> cancelNativeNotification({
  required int notificationId,
}) async {
  await _nativeNotificationChannel.invokeMethod('cancelNativeNotification', {
    'notificationId': notificationId,
  });
}

void setupNativeNotificationCallbacks({
  required void Function(Map<dynamic, dynamic>) onTipRead,
  required void Function(Map<dynamic, dynamic>) onTipShare,
  required void Function(Map<dynamic, dynamic>) onTipSave,
  required void Function(Map<dynamic, dynamic>) onTipDismiss,
  void Function(Map<dynamic, dynamic>)? onNotificationShown,
}) {
  _nativeNotificationChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'onTipRead':
        onTipRead(call.arguments as Map<dynamic, dynamic>);
        break;
      case 'onTipShare':
        onTipShare(call.arguments as Map<dynamic, dynamic>);
        break;
      case 'onTipSave':
        onTipSave(call.arguments as Map<dynamic, dynamic>);
        break;
      case 'onTipDismiss':
        onTipDismiss(call.arguments as Map<dynamic, dynamic>);
        break;
      case 'onNotificationShown':
        if (onNotificationShown != null) {
          onNotificationShown(call.arguments as Map<dynamic, dynamic>);
        }
        break;
      default:
        break;
    }
  });
}

int generateNotificationId(String tipId) {
  // Simple hash for demonstration; in production, use a better hash or a UUID
  return tipId.hashCode & 0x7FFFFFFF;
}

Future<void> enableRandomNotifications() async {
  await Workmanager().registerPeriodicTask(
    'random_5min',
    backgroundTipTask,
    frequency: const Duration(minutes: 5),
    initialDelay: const Duration(minutes: 1),
    constraints: Constraints(
      networkType: NetworkType.not_required,
      requiresBatteryNotLow: false,
      requiresCharging: false,
      requiresDeviceIdle: false,
      requiresStorageNotLow: false,
    ),
  );
}

Future<void> disableRandomNotifications() async {
  await Workmanager().cancelByUniqueName('random_5min');
}
