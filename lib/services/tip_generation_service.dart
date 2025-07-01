import 'dart:math';
import 'package:hive/hive.dart';
import '../models/api_key_entry.dart';
import '../models/topic_entry.dart';
import '../models/tip_entry.dart';
import 'notifications.dart';

class TipGenerationService {
  static const int maxDailyTips = 5;
  static const Duration generationInterval = Duration(hours: 2);

  static Future<void> generateAndScheduleTips() async {
    try {
      final settings = Hive.box('settings');
      final autoGenerateTips =
          settings.get('autoGenerateTips', defaultValue: false);
      final notificationsEnabled =
          settings.get('notificationsEnabled', defaultValue: true);
      final dailyTipCount = settings.get('dailyTipCount', defaultValue: 1);

      if (!autoGenerateTips || !notificationsEnabled) return;

      final apiKeysBox = Hive.box<ApiKeyEntry>('apiKeys');
      final topicsBox = Hive.box<TopicEntry>('topics');
      final tipsBox = Hive.box<TipEntry>('tips');

      final apiKeys = apiKeysBox.values.toList();
      final topics = topicsBox.values.toList();

      if (apiKeys.isEmpty || topics.isEmpty) return;

      final selectedApiKeyIndex =
          settings.get('selectedApiKeyIndex', defaultValue: 0);
      if (selectedApiKeyIndex >= apiKeys.length) return;

      final apiKey = apiKeys[selectedApiKeyIndex];
      final random = Random();

      // Generate tips up to the daily limit
      int tipsGenerated = 0;
      final today = DateTime.now();
      final todayTips = tipsBox.values
          .where((tip) =>
              tip.createdAt.year == today.year &&
              tip.createdAt.month == today.month &&
              tip.createdAt.day == today.day)
          .length;

      final remainingTips = dailyTipCount - todayTips;
      if (remainingTips <= 0) return;

      while (tipsGenerated < remainingTips && tipsGenerated < maxDailyTips) {
        try {
          // Select random topic
          final selectedTopic = topics[random.nextInt(topics.length)];

          // Generate tip
          final tipText =
              await _generateTipForTopic(selectedTopic.topic, apiKey.key);

          // Save to Hive
          final tipEntry = TipEntry(
            tip: tipText,
            createdAt: DateTime.now(),
            references: ['Topic: ${selectedTopic.topic}', 'Auto-generated'],
            isFavorite: false,
          );
          await tipsBox.add(tipEntry);

          // Schedule notification
          await scheduleDailyTipNotification(
            tipText,
            references: tipEntry.references,
            hour: _getRandomNotificationHour(),
            minute: random.nextInt(60),
          );

          tipsGenerated++;

          // Add small delay to avoid API rate limiting
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          print('Error generating tip: $e');
          break;
        }
      }

      print('Generated $tipsGenerated tips successfully');
    } catch (e) {
      print('Error in tip generation service: $e');
    }
  }

  static Future<String> _generateTipForTopic(
      String topic, String apiKey) async {
    return await _generateTipForTopicFromNotifications(topic, apiKey);
  }

  static int _getRandomNotificationHour() {
    final random = Random();
    // Generate random hour between 8 AM and 8 PM
    return 8 + random.nextInt(12);
  }

  static Future<void> scheduleRecurringTipGeneration() async {
    // This would typically be handled by a background service
    // For now, we'll just generate tips when the app starts
    await generateAndScheduleTips();
  }

  static Future<List<TipEntry>> getTodaysTips() async {
    final tipsBox = Hive.box<TipEntry>('tips');
    final today = DateTime.now();

    return tipsBox.values
        .where((tip) =>
            tip.createdAt.year == today.year &&
            tip.createdAt.month == today.month &&
            tip.createdAt.day == today.day)
        .toList();
  }

  static Future<List<TipEntry>> getFavoriteTips() async {
    final tipsBox = Hive.box<TipEntry>('tips');
    return tipsBox.values.where((tip) => tip.isFavorite).toList();
  }

  static Future<void> cleanupOldTips() async {
    final tipsBox = Hive.box<TipEntry>('tips');
    final settings = Hive.box('settings');
    final keepDays = settings.get('keepTipsDays', defaultValue: 30);

    final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));
    final tipsToDelete = <int>[];

    for (int i = 0; i < tipsBox.length; i++) {
      final tip = tipsBox.getAt(i);
      if (tip != null &&
          tip.createdAt.isBefore(cutoffDate) &&
          !tip.isFavorite) {
        tipsToDelete.add(i);
      }
    }

    // Delete from highest index to lowest to avoid index shifting
    for (int i = tipsToDelete.length - 1; i >= 0; i--) {
      await tipsBox.deleteAt(tipsToDelete[i]);
    }

    print('Cleaned up ${tipsToDelete.length} old tips');
  }
}

// Import the function from notifications.dart
Future<String> _generateTipForTopicFromNotifications(
    String topic, String apiKey) async {
  // This is a placeholder - we'll import the actual function from notifications.dart
  // For now, return a simple tip
  final tips = [
    'Focus on small, consistent actions in $topic today.',
    'Take 5 minutes to practice $topic techniques.',
    'Reflect on your progress in $topic this week.',
    'Set a small, achievable goal related to $topic.',
    'Share something you learned about $topic with others.',
  ];
  final random = Random();
  return tips[random.nextInt(tips.length)];
}
