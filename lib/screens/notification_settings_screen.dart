import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/notification_schedule_entry.dart';
import '../services/notifications.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pauseAll = false;
  DateTime? _snoozeUntil;

  @override
  void initState() {
    super.initState();
    final settings = Hive.box('settings');
    _pauseAll = settings.get('pauseAllNotifications', defaultValue: false);
    _snoozeUntil = settings.get('snoozeUntil');
  }

  void _togglePauseAll(bool value) async {
    final settings = Hive.box('settings');
    setState(() => _pauseAll = value);
    await settings.put('pauseAllNotifications', value);
  }

  void _setSnooze(DateTime? until) async {
    final settings = Hive.box('settings');
    setState(() => _snoozeUntil = until);
    await settings.put('snoozeUntil', until);
  }

  void _showAddOrEditSchedule({NotificationScheduleEntry? entry, int? idx}) {
    final isEdit = entry != null;
    final titleController = TextEditingController(text: entry?.title ?? '');
    final messageController =
        TextEditingController(text: entry?.messageTemplate ?? '');
    final topicController = TextEditingController(text: entry?.topic ?? '');
    List<int> weekdays =
        entry?.weekdays != null ? List<int>.from(entry!.weekdays!) : [];
    List<int> hours = entry?.hours != null ? List<int>.from(entry!.hours) : [8];
    List<int> minutes =
        entry?.minutes != null ? List<int>.from(entry!.minutes) : [0];
    int? colorTag = entry?.colorTag;
    bool vibration = entry?.vibration ?? true;
    bool paused = entry?.paused ?? false;
    bool enabled = entry?.enabled ?? true;
    DateTime? snoozeUntil = entry?.snoozeUntil;
    String repeat = entry?.repeat ?? 'weekly';
    bool randomTime = entry?.intervalDays == -1; // Use -1 for random time
    int notificationsPerDay = (entry?.hours.length ?? 1);
    int intervalDays = entry?.intervalDays ?? 1;
    String? errorText;

    // New: Support for custom times per day
    bool customTimesPerDay = false;
    // Map weekday (1=Mon...7=Sun) to list of times (hour, minute)
    Map<int, List<List<int>>> perDayTimes = {};
    if (entry != null &&
        entry.weekdays != null &&
        entry.weekdays!.isNotEmpty &&
        entry.hours.isNotEmpty) {
      // Try to infer per-day times from entry (if previously saved)
      for (var d in entry.weekdays!) {
        perDayTimes[d] = [];
        for (int i = 0; i < entry.hours.length; i++) {
          perDayTimes[d]!.add([entry.hours[i], entry.minutes[i]]);
        }
      }
    }

    void save() async {
      // Validation
      if (titleController.text.trim().isEmpty) {
        setState(() => errorText = 'Schedule name is required.');
        return;
      }
      if (!randomTime && (repeat == 'daily' && notificationsPerDay > 0)) {
        if (customTimesPerDay) {
          for (var d in weekdays) {
            if (!perDayTimes.containsKey(d) || perDayTimes[d]!.isEmpty) {
              setState(() =>
                  errorText = 'Set at least one time for each selected day.');
              return;
            }
          }
        } else {
          for (int i = 0; i < notificationsPerDay; i++) {
            if (hours.length <= i || minutes.length <= i) {
              setState(() => errorText = 'Please set all notification times.');
              return;
            }
          }
        }
      }
      if (repeat == 'custom' && (intervalDays < 1 || intervalDays > 30)) {
        setState(() => errorText = 'Interval days must be between 1 and 30.');
        return;
      }
      if (repeat == 'daily' && notificationsPerDay < 1) {
        setState(() => errorText = 'At least one notification per day.');
        return;
      }
      setState(() => errorText = null);
      try {
        final box =
            Hive.box<NotificationScheduleEntry>('notificationSchedules');
        List<int> saveHours = [];
        List<int> saveMinutes = [];
        if (randomTime) {
          saveHours = [];
          saveMinutes = [];
          intervalDays = -1;
        } else if (repeat == 'daily' &&
            notificationsPerDay > 0 &&
            customTimesPerDay) {
          // Flatten all per-day times into hours/minutes, and store weekdays as all selected days
          for (var d in weekdays) {
            for (var t in perDayTimes[d] ?? []) {
              saveHours.add(t[0]);
              saveMinutes.add(t[1]);
            }
          }
        } else if (repeat == 'daily' && notificationsPerDay > 0) {
          saveHours = List<int>.from(hours);
          saveMinutes = List<int>.from(minutes);
          while (saveHours.length > notificationsPerDay) {
            saveHours.removeLast();
            saveMinutes.removeLast();
          }
          while (saveHours.length < notificationsPerDay) {
            saveHours.add(8);
            saveMinutes.add(0);
          }
        } else {
          saveHours = List<int>.from(hours);
          saveMinutes = List<int>.from(minutes);
        }
        final newEntry = NotificationScheduleEntry(
          title: titleController.text.trim(),
          messageTemplate: messageController.text.trim(),
          topic: topicController.text.trim().isEmpty
              ? null
              : topicController.text.trim(),
          weekdays: weekdays,
          hours: saveHours,
          minutes: saveMinutes,
          colorTag: colorTag,
          vibration: vibration,
          paused: paused,
          enabled: enabled,
          snoozeUntil: snoozeUntil,
          repeat: repeat,
          intervalDays:
              repeat == 'custom' ? intervalDays : (randomTime ? -1 : null),
        );
        if (isEdit && idx != null) {
          await box.putAt(idx, newEntry);
        } else {
          await box.add(newEntry);
        }
        Navigator.pop(context);
        setState(() {});
      } catch (e) {
        setState(() => errorText = 'Failed to save: \\${e.toString()}');
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void setBoth(VoidCallback fn) {
              setState(fn);
              setModalState(fn);
            }

            return CupertinoActionSheet(
              title: Text(isEdit ? 'Edit Schedule' : 'Add Schedule'),
              message: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoTextField(
                    controller: titleController,
                    placeholder: 'Schedule Name',
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: messageController,
                    placeholder: 'Notification Message (use {tip})',
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: topicController,
                    placeholder: 'Topic (optional)',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Repeat:'),
                      const SizedBox(width: 8),
                      CupertinoSegmentedControl<String>(
                        groupValue: repeat,
                        children: const {
                          'daily': Text('Daily'),
                          'weekly': Text('Weekly'),
                          'custom': Text('Every N days'),
                        },
                        onValueChanged: (v) => setBoth(() => repeat = v),
                      ),
                    ],
                  ),
                  if (repeat == 'custom')
                    Row(
                      children: [
                        const Text('Repeat every'),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text('$intervalDays days'),
                          onPressed: () async {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (_) => SizedBox(
                                height: 200,
                                child: CupertinoPicker(
                                  itemExtent: 32,
                                  scrollController: FixedExtentScrollController(
                                      initialItem: intervalDays - 1),
                                  onSelectedItemChanged: (v) =>
                                      setBoth(() => intervalDays = v + 1),
                                  children: List.generate(
                                      30, (i) => Text('${i + 1} days')),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  if (repeat == 'daily')
                    Row(
                      children: [
                        const Text('Notifications per day:'),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text('$notificationsPerDay'),
                          onPressed: () async {
                            showCupertinoModalPopup(
                              context: context,
                              builder: (_) => SizedBox(
                                height: 200,
                                child: CupertinoPicker(
                                  itemExtent: 32,
                                  scrollController: FixedExtentScrollController(
                                      initialItem: notificationsPerDay - 1),
                                  onSelectedItemChanged: (v) => setBoth(
                                      () => notificationsPerDay = v + 1),
                                  children: List.generate(
                                      10, (i) => Text('${i + 1}')),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        CupertinoSwitch(
                          value: randomTime,
                          onChanged: (v) => setBoth(() => randomTime = v),
                        ),
                        const SizedBox(width: 4),
                        const Text('Random time'),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Weekdays:'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          children: List.generate(7, (i) {
                            final day = i + 1;
                            final short =
                                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i];
                            final selected = weekdays.contains(day);
                            return GestureDetector(
                              onTap: () => setBoth(() {
                                if (selected) {
                                  weekdays.remove(day);
                                } else {
                                  weekdays.add(day);
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? CupertinoColors.activeBlue
                                      : CupertinoColors.systemGrey4,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(short,
                                    style: TextStyle(
                                        color: selected
                                            ? CupertinoColors.white
                                            : CupertinoColors.black)),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  if (!randomTime) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Times:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: List.generate(notificationsPerDay, (i) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    child: Text(
                                        '${hours.length > i ? hours[i].toString().padLeft(2, '0') : '08'}:${minutes.length > i ? minutes[i].toString().padLeft(2, '0') : '00'}'),
                                    onPressed: () async {
                                      final now = DateTime.now();
                                      showCupertinoModalPopup(
                                        context: context,
                                        builder: (_) => SizedBox(
                                          height: 250,
                                          child: CupertinoDatePicker(
                                            mode: CupertinoDatePickerMode.time,
                                            initialDateTime: DateTime(
                                                now.year,
                                                now.month,
                                                now.day,
                                                hours.length > i ? hours[i] : 8,
                                                minutes.length > i
                                                    ? minutes[i]
                                                    : 0),
                                            use24hFormat: true,
                                            onDateTimeChanged: (dt) =>
                                                setBoth(() {
                                              if (hours.length > i) {
                                                hours[i] = dt.hour;
                                                minutes[i] = dt.minute;
                                              } else {
                                                hours.add(dt.hour);
                                                minutes.add(dt.minute);
                                              }
                                            }),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Color:'),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colorTag != null
                                ? Color(colorTag!)
                                : CupertinoColors.systemGrey4,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: CupertinoColors.systemGrey, width: 1),
                          ),
                        ),
                        onPressed: () async {
                          final colors = [
                            CupertinoColors.activeBlue.value,
                            CupertinoColors.systemRed.value,
                            CupertinoColors.systemGreen.value,
                            CupertinoColors.systemYellow.value,
                            CupertinoColors.systemGrey.value,
                            CupertinoColors.systemPurple.value,
                            CupertinoColors.systemTeal.value,
                          ];
                          showCupertinoModalPopup(
                            context: context,
                            builder: (_) => CupertinoActionSheet(
                              title: const Text('Pick a color'),
                              actions: colors
                                  .map((c) => CupertinoActionSheetAction(
                                        onPressed: () => setBoth(() {
                                          colorTag = c;
                                          Navigator.pop(context);
                                        }),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Color(c),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            border: Border.all(
                                                color:
                                                    CupertinoColors.systemGrey,
                                                width: 1),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              cancelButton: CupertinoActionSheetAction(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Vibration'),
                      const Spacer(),
                      CupertinoSwitch(
                        value: vibration,
                        onChanged: (v) => setBoth(() => vibration = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Paused'),
                      const Spacer(),
                      CupertinoSwitch(
                        value: paused,
                        onChanged: (v) => setBoth(() => paused = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Enabled'),
                      const Spacer(),
                      CupertinoSwitch(
                        value: enabled,
                        onChanged: (v) => setBoth(() => enabled = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Snooze Until:'),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(snoozeUntil == null
                            ? 'Off'
                            : '${snoozeUntil!.hour.toString().padLeft(2, '0')}:${snoozeUntil!.minute.toString().padLeft(2, '0')}'),
                        onPressed: () async {
                          final now = DateTime.now();
                          showCupertinoModalPopup(
                            context: context,
                            builder: (_) => SizedBox(
                              height: 250,
                              child: CupertinoDatePicker(
                                mode: CupertinoDatePickerMode.dateAndTime,
                                initialDateTime: snoozeUntil ??
                                    now.add(const Duration(hours: 1)),
                                onDateTimeChanged: (dt) =>
                                    setBoth(() => snoozeUntil = dt),
                              ),
                            ),
                          );
                        },
                      ),
                      if (snoozeUntil != null)
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Icon(CupertinoIcons.clear_circled,
                              size: 18),
                          onPressed: () => setBoth(() => snoozeUntil = null),
                        ),
                    ],
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(errorText!,
                        style: const TextStyle(
                            color: CupertinoColors.systemRed, fontSize: 14)),
                  ],
                ],
              ),
              actions: [
                CupertinoActionSheetAction(
                  onPressed: save,
                  child: Text(isEdit ? 'Save Changes' : 'Add Schedule'),
                ),
                if (isEdit)
                  CupertinoActionSheetAction(
                    isDestructiveAction: true,
                    onPressed: () async {
                      try {
                        final box = Hive.box<NotificationScheduleEntry>(
                            'notificationSchedules');
                        await box.deleteAt(idx!);
                        Navigator.pop(context);
                        setState(() {});
                      } catch (e) {
                        setModalState(() =>
                            errorText = 'Failed to delete: \\${e.toString()}');
                      }
                    },
                    child: const Text('Delete'),
                  ),
              ],
              cancelButton: CupertinoActionSheetAction(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context),
              ),
            );
          },
        );
      },
    );
  }

  void _deleteSchedule(int idx) async {
    final box = Hive.box<NotificationScheduleEntry>('notificationSchedules');
    await box.deleteAt(idx);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final schedulesBox =
        Hive.box<NotificationScheduleEntry>('notificationSchedules');
    final schedules = schedulesBox.values.toList();
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Notification Settings'),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pause All Notifications',
                    style: TextStyle(fontSize: 15)),
                CupertinoSwitch(
                  value: _pauseAll,
                  onChanged: _togglePauseAll,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Snooze', style: TextStyle(fontSize: 15)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(_snoozeUntil == null
                      ? 'Off'
                      : 'Until ${_snoozeUntil!.hour.toString().padLeft(2, '0')}:${_snoozeUntil!.minute.toString().padLeft(2, '0')}'),
                  onPressed: () async {
                    final now = DateTime.now();
                    showCupertinoModalPopup(
                      context: context,
                      builder: (_) => CupertinoActionSheet(
                        title: const Text('Snooze Notifications'),
                        message: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.dateAndTime,
                          initialDateTime: now.add(const Duration(hours: 1)),
                          onDateTimeChanged: (dt) => _setSnooze(dt),
                        ),
                        actions: [
                          CupertinoActionSheetAction(
                            child: const Text('Clear Snooze'),
                            onPressed: () {
                              Navigator.pop(context);
                              _setSnooze(null);
                            },
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          child: const Text('Done'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Schedules',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.add),
                  onPressed: () => _showAddOrEditSchedule(),
                ),
              ],
            ),
            ...List.generate(schedules.length, (i) {
              final s = schedules[i];
              return Dismissible(
                key: ValueKey(s.key),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  color: CupertinoColors.systemRed,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 24.0),
                    child: Icon(CupertinoIcons.delete,
                        color: CupertinoColors.white),
                  ),
                ),
                confirmDismiss: (_) async {
                  _deleteSchedule(i);
                  return false;
                },
                child: GestureDetector(
                  onTap: () => _showAddOrEditSchedule(entry: s, idx: i),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: s.colorTag != null
                          ? Color(s.colorTag!)
                          : CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.title ?? 'Schedule ${i + 1}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              const SizedBox(height: 2),
                              Text(
                                  'Times: ${List.generate(s.hours.length, (j) => s.hours[j].toString().padLeft(2, '0') + ':' + s.minutes[j].toString().padLeft(2, '0')).join(', ')}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.inactiveGray)),
                              if (s.weekdays != null && s.weekdays!.isNotEmpty)
                                Text(
                                    'Weekdays: ${s.weekdays!.map((d) => [
                                          'Mon',
                                          'Tue',
                                          'Wed',
                                          'Thu',
                                          'Fri',
                                          'Sat',
                                          'Sun'
                                        ][d - 1]).join(', ')}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: CupertinoColors.inactiveGray)),
                              if (s.topic != null)
                                Text('Topic: ${s.topic}',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: CupertinoColors.inactiveGray)),
                              if (s.paused)
                                const Text('Paused',
                                    style: TextStyle(
                                        color: CupertinoColors.systemRed,
                                        fontSize: 13)),
                              if (s.snoozeUntil != null)
                                Text('Snoozed until: ${s.snoozeUntil}',
                                    style: const TextStyle(
                                        color: CupertinoColors.systemOrange,
                                        fontSize: 13)),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 28,
                          child: const Icon(CupertinoIcons.bell),
                          onPressed: () async {
                            // Send test notification for this schedule
                            await showTipNotification(
                                'Test notification for schedule: ${s.title ?? 'Schedule ${i + 1}'}');
                          },
                        ),
                        CupertinoSwitch(
                          value: s.enabled,
                          onChanged: (v) async {
                            s.enabled = v;
                            await s.save();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 30),
            const Text('Notification Log',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            // TODO: Show notification log/history here
            const SizedBox(height: 10),
            Center(child: Text('No log yet.')), // Placeholder
          ],
        ),
      ),
    );
  }
}
