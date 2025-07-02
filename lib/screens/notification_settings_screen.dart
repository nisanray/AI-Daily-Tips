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
    bool randomTime = entry?.intervalDays == -1;
    int notificationsPerDay = (entry?.hours.length ?? 1);
    int intervalDays = entry?.intervalDays ?? 1;

    void save() async {
      // Validation
      if (titleController.text.trim().isEmpty) {
        Navigator.of(context).pop();
        _showErrorDialog('Schedule name is required.');
        return;
      }

      try {
        final box =
            Hive.box<NotificationScheduleEntry>('notificationSchedules');
        List<int> saveHours = [];
        List<int> saveMinutes = [];

        if (randomTime) {
          saveHours = [];
          saveMinutes = [];
          intervalDays = -1;
        } else {
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
        _showErrorDialog('Failed to save: ${e.toString()}');
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          void setBoth(VoidCallback fn) {
            setState(fn);
            setModalState(fn);
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: CupertinoPageScaffold(
              backgroundColor: CupertinoColors.systemGroupedBackground,
              navigationBar: CupertinoNavigationBar(
                backgroundColor: CupertinoColors.systemBackground,
                border: null,
                leading: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                middle: Text(isEdit ? 'Edit Schedule' : 'New Schedule'),
                trailing: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    isEdit ? 'Save' : 'Create',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: save,
                ),
              ),
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Basic Info Card
                    _buildFormCard(
                      title: 'Basic Information',
                      icon: CupertinoIcons.info_circle,
                      children: [
                        _buildTextField(
                          controller: titleController,
                          label: 'Schedule Name',
                          placeholder: 'e.g., Morning AI Tips',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: messageController,
                          label: 'Message Template',
                          placeholder: 'Your AI tip: {tip}',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: topicController,
                          label: 'Topic (Optional)',
                          placeholder: 'e.g., Machine Learning, Flutter',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Timing Card
                    _buildFormCard(
                      title: 'Timing & Frequency',
                      icon: CupertinoIcons.clock,
                      children: [
                        _buildSegmentedControl(
                          'Repeat Pattern',
                          repeat,
                          {
                            'daily': 'Daily',
                            'weekly': 'Weekly',
                            'custom': 'Custom',
                          },
                          (v) => setBoth(() => repeat = v),
                        ),
                        if (repeat == 'custom') ...[
                          const SizedBox(height: 16),
                          _buildNumberPicker(
                            'Repeat Every',
                            '$intervalDays days',
                            () => _showIntervalPicker(intervalDays, (newValue) {
                              setBoth(() => intervalDays = newValue);
                            }),
                          ),
                        ],
                        if (repeat == 'daily') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildNumberPicker(
                                  'Notifications per day',
                                  '$notificationsPerDay',
                                  () => _showNotificationsPerDayPicker(
                                      notificationsPerDay, (newValue) {
                                    setBoth(
                                        () => notificationsPerDay = newValue);
                                  }),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                children: [
                                  const Text(
                                    'Random Time',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: CupertinoColors.label,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CupertinoSwitch(
                                    value: randomTime,
                                    onChanged: (v) =>
                                        setBoth(() => randomTime = v),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        _buildWeekdaySelector(weekdays, setBoth),
                        if (!randomTime) ...[
                          const SizedBox(height: 16),
                          _buildTimeSelector(
                              hours, minutes, notificationsPerDay, setBoth),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Appearance & Behavior Card
                    _buildFormCard(
                      title: 'Appearance & Behavior',
                      icon: CupertinoIcons.paintbrush,
                      children: [
                        _buildColorPicker(colorTag, setBoth),
                        const SizedBox(height: 16),
                        _buildToggleRow('Vibration', vibration,
                            (v) => setBoth(() => vibration = v)),
                        const SizedBox(height: 8),
                        _buildToggleRow('Enabled', enabled,
                            (v) => setBoth(() => enabled = v)),
                        const SizedBox(height: 8),
                        _buildToggleRow(
                            'Paused', paused, (v) => setBoth(() => paused = v)),
                      ],
                    ),

                    if (isEdit) ...[
                      const SizedBox(height: 16),
                      CupertinoButton(
                        color: CupertinoColors.systemRed,
                        child: const Text('Delete Schedule'),
                        onPressed: () => _showDeleteConfirmation(idx!, context),
                      ),
                    ],

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(icon, color: CupertinoColors.systemBlue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String placeholder,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          maxLines: maxLines,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemFill,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentedControl(
    String label,
    String value,
    Map<String, String> options,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoSegmentedControl<String>(
          groupValue: value,
          children: options.map((k, v) => MapEntry(
              k,
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(v),
              ))),
          onValueChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNumberPicker(String label, String value, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemFill,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.label,
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: CupertinoColors.secondaryLabel,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdaySelector(
      List<int> weekdays, Function(VoidCallback) setBoth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Active Days',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(7, (i) {
            final day = i + 1;
            final short = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i];
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selected
                      ? CupertinoColors.systemBlue
                      : CupertinoColors.systemFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    short,
                    style: TextStyle(
                      color: selected
                          ? CupertinoColors.white
                          : CupertinoColors.label,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(List<int> hours, List<int> minutes, int count,
      Function(VoidCallback) setBoth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification Times',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(count, (i) {
            return CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showTimePicker(i, hours, minutes, setBoth),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.clock, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      '${hours.length > i ? hours[i].toString().padLeft(2, '0') : '08'}:${minutes.length > i ? minutes[i].toString().padLeft(2, '0') : '00'}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildColorPicker(int? colorTag, Function(VoidCallback) setBoth) {
    final colors = [
      CupertinoColors.systemBlue.value,
      CupertinoColors.systemGreen.value,
      CupertinoColors.systemOrange.value,
      CupertinoColors.systemRed.value,
      CupertinoColors.systemPurple.value,
      CupertinoColors.systemTeal.value,
      CupertinoColors.systemYellow.value,
      CupertinoColors.systemPink.value,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Color Theme',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors.map((color) {
            final isSelected = colorTag == color;
            return GestureDetector(
              onTap: () => setBoth(() => colorTag = color),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(color),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? CupertinoColors.label : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: isSelected
                    ? const Icon(CupertinoIcons.check_mark,
                        color: CupertinoColors.white, size: 20)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildToggleRow(
      String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: CupertinoColors.label,
          ),
        ),
        CupertinoSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  void _showTimePicker(int index, List<int> hours, List<int> minutes,
      Function(VoidCallback) setBoth) {
    final now = DateTime.now();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 250,
        color: CupertinoColors.systemBackground,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: DateTime(
            now.year,
            now.month,
            now.day,
            hours.length > index ? hours[index] : 8,
            minutes.length > index ? minutes[index] : 0,
          ),
          use24hFormat: true,
          onDateTimeChanged: (dt) => setBoth(() {
            if (hours.length > index) {
              hours[index] = dt.hour;
              minutes[index] = dt.minute;
            } else {
              hours.add(dt.hour);
              minutes.add(dt.minute);
            }
          }),
        ),
      ),
    );
  }

  void _showIntervalPicker(int current, Function(int) onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 200,
        color: CupertinoColors.systemBackground,
        child: CupertinoPicker(
          itemExtent: 32,
          scrollController:
              FixedExtentScrollController(initialItem: current - 1),
          onSelectedItemChanged: (v) => onChanged(v + 1),
          children: List.generate(30, (i) => Text('${i + 1} days')),
        ),
      ),
    );
  }

  void _showNotificationsPerDayPicker(int current, Function(int) onChanged) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 200,
        color: CupertinoColors.systemBackground,
        child: CupertinoPicker(
          itemExtent: 32,
          scrollController:
              FixedExtentScrollController(initialItem: current - 1),
          onSelectedItemChanged: (v) => onChanged(v + 1),
          children: List.generate(10, (i) => Text('${i + 1}')),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int index, BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Delete Schedule'),
        content: const Text(
            'Are you sure you want to delete this notification schedule? This action cannot be undone.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Delete'),
            onPressed: () async {
              try {
                final box = Hive.box<NotificationScheduleEntry>(
                    'notificationSchedules');
                await box.deleteAt(index);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close modal
                setState(() {});
              } catch (e) {
                _showErrorDialog('Failed to delete: ${e.toString()}');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _deleteSchedule(int idx) async {
    final box = Hive.box<NotificationScheduleEntry>('notificationSchedules');
    await box.deleteAt(idx);
    setState(() {});
  }

  Widget _buildQuickActionsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _pauseAll
                      ? CupertinoColors.systemRed.withOpacity(0.1)
                      : CupertinoColors.systemGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _pauseAll ? CupertinoIcons.pause_circle : CupertinoIcons.bell,
                  color: _pauseAll
                      ? CupertinoColors.systemRed
                      : CupertinoColors.systemGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pause All Notifications',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    Text(
                      _pauseAll
                          ? 'All notifications are paused'
                          : 'Notifications are active',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _pauseAll,
                onChanged: _togglePauseAll,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: CupertinoColors.separator),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _snoozeUntil != null
                      ? CupertinoColors.systemOrange.withOpacity(0.1)
                      : CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _snoozeUntil != null
                      ? CupertinoIcons.moon_zzz
                      : CupertinoIcons.moon,
                  color: _snoozeUntil != null
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.systemBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Snooze Notifications',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                    ),
                    Text(
                      _snoozeUntil == null
                          ? 'Not snoozed'
                          : 'Until ${_snoozeUntil!.day}/${_snoozeUntil!.month} at ${_snoozeUntil!.hour.toString().padLeft(2, '0')}:${_snoozeUntil!.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemFill,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _snoozeUntil == null ? 'Set' : 'Edit',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                ),
                onPressed: () => _showSnoozeOptions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(NotificationScheduleEntry schedule, int index) {
    final isEnabled = schedule.enabled && !schedule.paused;
    final timeString = schedule.hours.isEmpty
        ? 'Random times'
        : List.generate(
                schedule.hours.length,
                (j) =>
                    '${schedule.hours[j].toString().padLeft(2, '0')}:${schedule.minutes[j].toString().padLeft(2, '0')}')
            .join(', ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: schedule.colorTag != null
              ? Color(schedule.colorTag!).withOpacity(0.3)
              : CupertinoColors.separator,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Dismissible(
        key: ValueKey(schedule.key),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: CupertinoColors.systemRed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.only(right: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.delete,
                    color: CupertinoColors.white, size: 28),
                SizedBox(height: 4),
                Text('Delete',
                    style:
                        TextStyle(color: CupertinoColors.white, fontSize: 12)),
              ],
            ),
          ),
        ),
        confirmDismiss: (_) async {
          _deleteSchedule(index);
          return false;
        },
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddOrEditSchedule(entry: schedule, idx: index),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: schedule.colorTag != null
                            ? Color(schedule.colorTag!)
                            : CupertinoColors.systemBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (schedule.colorTag != null
                                    ? Color(schedule.colorTag!)
                                    : CupertinoColors.systemBlue)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isEnabled
                            ? CupertinoIcons.bell
                            : CupertinoIcons.bell_slash,
                        color: CupertinoColors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.title ?? 'Schedule ${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.label,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeString,
                            style: const TextStyle(
                              fontSize: 15,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 32,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemFill,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(CupertinoIcons.bell, size: 16),
                          ),
                          onPressed: () async {
                            await showTipNotification(
                                'Test: ${schedule.title ?? 'Schedule ${index + 1}'}');
                          },
                        ),
                        const SizedBox(height: 8),
                        CupertinoSwitch(
                          value: schedule.enabled,
                          onChanged: (v) async {
                            schedule.enabled = v;
                            await schedule.save();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if (schedule.weekdays != null &&
                    schedule.weekdays!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(CupertinoIcons.calendar,
                                size: 16,
                                color: CupertinoColors.secondaryLabel),
                            const SizedBox(width: 8),
                            Text(
                              'Active Days',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: schedule.weekdays!.map((day) {
                            final dayName = [
                              'Mon',
                              'Tue',
                              'Wed',
                              'Thu',
                              'Fri',
                              'Sat',
                              'Sun'
                            ][day - 1];
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: schedule.colorTag != null
                                    ? Color(schedule.colorTag!)
                                    : CupertinoColors.systemBlue,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                dayName,
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
                if (schedule.topic != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(CupertinoIcons.tag,
                          size: 16, color: CupertinoColors.secondaryLabel),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          schedule.topic!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.secondaryLabel,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (schedule.paused || schedule.snoozeUntil != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: schedule.paused
                          ? CupertinoColors.systemRed.withOpacity(0.1)
                          : CupertinoColors.systemOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          schedule.paused
                              ? CupertinoIcons.pause
                              : CupertinoIcons.moon_zzz,
                          size: 14,
                          color: schedule.paused
                              ? CupertinoColors.systemRed
                              : CupertinoColors.systemOrange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          schedule.paused
                              ? 'Paused'
                              : 'Snoozed until ${schedule.snoozeUntil!.day}/${schedule.snoozeUntil!.month}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: schedule.paused
                                ? CupertinoColors.systemRed
                                : CupertinoColors.systemOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSnoozeOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: const Text('Snooze Notifications'),
        message: const Text('Choose how long to snooze notifications'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('1 Hour'),
            onPressed: () {
              Navigator.pop(context);
              _setSnooze(DateTime.now().add(const Duration(hours: 1)));
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('4 Hours'),
            onPressed: () {
              Navigator.pop(context);
              _setSnooze(DateTime.now().add(const Duration(hours: 4)));
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Until Tomorrow'),
            onPressed: () {
              Navigator.pop(context);
              final tomorrow = DateTime.now().add(const Duration(days: 1));
              _setSnooze(
                  DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0));
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Custom Time'),
            onPressed: () {
              Navigator.pop(context);
              final now = DateTime.now();
              showCupertinoModalPopup(
                context: context,
                builder: (_) => Container(
                  height: 250,
                  color: CupertinoColors.systemBackground,
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: now.add(const Duration(hours: 1)),
                    minimumDate: now,
                    onDateTimeChanged: _setSnooze,
                  ),
                ),
              );
            },
          ),
          if (_snoozeUntil != null)
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Text('Clear Snooze'),
              onPressed: () {
                Navigator.pop(context);
                _setSnooze(null);
              },
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedulesBox =
        Hive.box<NotificationScheduleEntry>('notificationSchedules');
    final schedules = schedulesBox.values.toList();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Notification Settings'),
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add_circled, size: 28),
          onPressed: () => _showAddOrEditSchedule(),
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Quick Actions Card
            SliverToBoxAdapter(child: _buildQuickActionsCard()),

            // Schedules Header
            SliverToBoxAdapter(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.clock,
                        color: CupertinoColors.systemBlue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Notification Schedules',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemFill,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${schedules.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Schedules List
            if (schedules.isEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: const Icon(
                          CupertinoIcons.bell_slash,
                          size: 32,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Schedules Yet',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create your first notification schedule to start receiving AI tips',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.secondaryLabel,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton.filled(
                        child: const Text('Create Schedule'),
                        onPressed: () => _showAddOrEditSchedule(),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildScheduleCard(schedules[index], index),
                  childCount: schedules.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
