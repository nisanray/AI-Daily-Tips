import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> showTipNotification(String tip, {List<String>? references}) async {
  String body = tip;
  if (references != null && references.isNotEmpty) {
    body += '\n\nReferences:\n' + references.join('\n');
  }
  // Save to Hive
  final tipsBox = Hive.box<TipEntry>('tips');
  await tipsBox.add(TipEntry(tip: tip, references: references));

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
    'Your Daily Tip',
    body,
    platformChannelSpecifics,
  );
}

Future<void> scheduleDailyTipNotification(String tip,
    {List<String>? references,
    int hour = 8,
    int minute = 0,
    int intervalDays = 1}) async {
  try {
    tz.initializeTimeZones();
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
  int notificationId = 1; // Use unique IDs for multiple notifications

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
          await flutterLocalNotificationsPlugin.zonedSchedule(
            notificationId++,
            'Your Daily Tip',
            _buildNotificationBody(tip, references),
            _nextInstanceOfWeekdayTime(hour, minute, weekday),
            NotificationDetails(
              android: AndroidNotificationDetails(
                'daily_tips',
                'Daily Tips',
                channelDescription: 'Notification channel for daily tips',
                sound: schedule.customSound != null
                    ? RawResourceAndroidNotificationSound(schedule.customSound!)
                    : null,
              ),
              iOS: DarwinNotificationDetails(
                sound: schedule.customSound,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      } else {
        // Interval or daily
        await flutterLocalNotificationsPlugin.zonedSchedule(
          notificationId++,
          'Your Daily Tip',
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
              sound: schedule.customSound != null
                  ? RawResourceAndroidNotificationSound(schedule.customSound!)
                  : null,
            ),
            iOS: DarwinNotificationDetails(
              sound: schedule.customSound,
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

Future<String> _generateTipForTopic(String topic, String apiKey) async {
  // Get the selected model from settings
  final settings = Hive.box('settings');
  final selectedModelId = settings.get('selectedModelId', defaultValue: GeminiModel.defaultModel.id);
  final selectedModel = GeminiModel.getModelById(selectedModelId) ?? GeminiModel.defaultModel;
  
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
