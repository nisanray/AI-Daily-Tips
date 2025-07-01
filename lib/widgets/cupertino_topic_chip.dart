import 'package:flutter/cupertino.dart';

class CupertinoTopicChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onLongPress;

  const CupertinoTopicChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDelete,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? CupertinoColors.activeBlue
              : CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    color: selected
                        ? CupertinoColors.white
                        : CupertinoColors.black)),
            if (onDelete != null) ...[
              const SizedBox(width: 2),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(CupertinoIcons.clear_circled_solid,
                    size: 18, color: CupertinoColors.systemGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
