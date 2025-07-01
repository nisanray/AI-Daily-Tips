import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tip_entry.dart';
import '../models/topic_entry.dart';
import '../screens/tips_history_screen.dart';

class AppStatsWidget extends StatelessWidget {
  const AppStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<TipEntry>('tips').listenable(),
      builder: (context, Box<TipEntry> tipsBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<TopicEntry>('topics').listenable(),
          builder: (context, Box<TopicEntry> topicsBox, _) {
            final totalTips = tipsBox.length;
            final totalTopics = topicsBox.length;
            final favoriteTips =
                tipsBox.values.where((tip) => tip.isFavorite).length;

            final today = DateTime.now();
            final todayTips = tipsBox.values
                .where((tip) =>
                    tip.createdAt.year == today.year &&
                    tip.createdAt.month == today.month &&
                    tip.createdAt.day == today.day)
                .length;

            return Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => const TipsHistoryScreen(),
                          ),
                        );
                      },
                      child: _StatItem(
                        icon: CupertinoIcons.bubble_left_bubble_right,
                        label: 'Total Tips',
                        value: '$totalTips',
                        isClickable: true,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: CupertinoIcons.tag,
                      label: 'Topics',
                      value: '$totalTopics',
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: CupertinoIcons.heart_fill,
                      label: 'Favorites',
                      value: '$favoriteTips',
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      icon: CupertinoIcons.today,
                      label: 'Today',
                      value: '$todayTips',
                      color: CupertinoColors.systemGreen,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  final bool isClickable;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: isClickable
          ? BoxDecoration(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: CupertinoColors.activeBlue.withOpacity(0.2),
                width: 1,
              ),
            )
          : BoxDecoration(
              color: CupertinoColors.systemGrey6.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color ??
                (isClickable
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.activeBlue),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isClickable ? CupertinoColors.activeBlue : null,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isClickable
                  ? CupertinoColors.activeBlue
                  : CupertinoColors.secondaryLabel,
            ),
            textAlign: TextAlign.center,
          ),
          if (isClickable) ...[
            const SizedBox(height: 2),
            const Text(
              'Tap to view',
              style: TextStyle(
                fontSize: 9,
                color: CupertinoColors.activeBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
