import 'package:hive/hive.dart';

part 'notification_schedule_entry.g.dart';

@HiveType(typeId: 4)
class NotificationScheduleEntry extends HiveObject {
  @HiveField(0)
  List<int> hours; // List of hours for notifications

  @HiveField(1)
  List<int> minutes; // List of minutes for notifications (same length as hours)

  @HiveField(2)
  List<int>? weekdays; // 1=Mon ... 7=Sun, null=every day

  @HiveField(3)
  int? intervalDays; // e.g. every X days

  @HiveField(4)
  DateTime? startDate;

  @HiveField(5)
  DateTime? endDate;

  @HiveField(6)
  bool enabled;

  @HiveField(7)
  String? topic; // Optional: per-topic scheduling

  @HiveField(8)
  String? customSound;

  @HiveField(9)
  String? title; // Custom notification title

  @HiveField(10)
  String? messageTemplate; // Custom message template

  @HiveField(11)
  bool vibration = true;

  @HiveField(12)
  int? colorTag; // For UI color coding

  @HiveField(13)
  bool paused = false;

  @HiveField(14)
  DateTime? snoozeUntil; // For snoozing notifications

  @HiveField(15)
  String repeat; // 'daily', 'weekly', 'custom'

  NotificationScheduleEntry({
    required this.hours,
    required this.minutes,
    this.weekdays,
    this.intervalDays,
    this.startDate,
    this.endDate,
    this.enabled = true,
    this.topic,
    this.customSound,
    this.title,
    this.messageTemplate,
    this.vibration = true,
    this.colorTag,
    this.paused = false,
    this.snoozeUntil,
    this.repeat = 'weekly',
  });
}
