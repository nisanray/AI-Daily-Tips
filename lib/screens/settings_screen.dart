import 'package:alarm/screens/api_settings_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'notification_settings_screen.dart';
import '../services/notifications.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _autoGenerateTips = false;
  int _dailyTipCount = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = Hive.box('settings');
    setState(() {
      _notificationsEnabled =
          settings.get('notificationsEnabled', defaultValue: true);
      _autoGenerateTips = settings.get('autoGenerateTips', defaultValue: false);
      _dailyTipCount = settings.get('dailyTipCount', defaultValue: 1);
    });
  }

  Future<void> _saveSettings() async {
    final settings = Hive.box('settings');
    await settings.put('notificationsEnabled', _notificationsEnabled);
    await settings.put('autoGenerateTips', _autoGenerateTips);
    await settings.put('dailyTipCount', _dailyTipCount);
  }

  void _showTipCountSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Daily Tips Count'),
        message: const Text('How many tips would you like to receive per day?'),
        actions: [1, 2, 3, 5]
            .map((count) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _dailyTipCount = count);
                    _saveSettings();
                    Navigator.pop(context);
                  },
                  child: Text('$count tip${count > 1 ? 's' : ''} per day'),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            CupertinoListSection(
              header: const Text('General Settings'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bell),
                  title: const Text('Enable Notifications'),
                  trailing: CupertinoSwitch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                      _saveSettings();
                      if (!value) {
                        cancelAllScheduledNotifications();
                      }
                    },
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.refresh),
                  title: const Text('Auto-Generate Tips'),
                  subtitle: const Text(
                      'Automatically generate tips for notifications'),
                  trailing: CupertinoSwitch(
                    value: _autoGenerateTips,
                    onChanged: (value) {
                      setState(() => _autoGenerateTips = value);
                      _saveSettings();
                    },
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.number),
                  title: const Text('Daily Tips Count'),
                  subtitle: Text(
                      '$_dailyTipCount tip${_dailyTipCount > 1 ? 's' : ''} per day'),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: _showTipCountSelector,
                ),
              ],
            ),
            CupertinoListSection(
              header: const Text('Configuration'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.time),
                  title: const Text('Notification Schedules'),
                  subtitle: const Text('Manage when you receive tips'),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                        builder: (_) => const NotificationSettingsScreen()),
                  ),
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.lock_shield),
                  title: const Text('API Keys'),
                  subtitle: const Text('Manage API keys for tip generation'),
                  trailing: const Icon(CupertinoIcons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    CupertinoPageRoute(
                        builder: (_) => const ApiSettingsScreen()),
                  ),
                ),
              ],
            ),
            CupertinoListSection(
              header: const Text('Testing'),
              children: [
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.bell_circle),
                  title: const Text('Test Notification'),
                  subtitle: const Text('Send a test notification'),
                  onTap: () async {
                    await scheduleTestNotification();
                    if (mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Test Notification Scheduled'),
                          content: const Text(
                              'A test notification will appear in 5 seconds.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
                CupertinoListTile(
                  leading: const Icon(CupertinoIcons.clear),
                  title: const Text('Clear All Notifications'),
                  subtitle: const Text('Cancel all scheduled notifications'),
                  onTap: () async {
                    await cancelAllScheduledNotifications();
                    if (mounted) {
                      showCupertinoDialog(
                        context: context,
                        builder: (context) => CupertinoAlertDialog(
                          title: const Text('Notifications Cleared'),
                          content: const Text(
                              'All scheduled notifications have been cancelled.'),
                          actions: [
                            CupertinoDialogAction(
                              child: const Text('OK'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
