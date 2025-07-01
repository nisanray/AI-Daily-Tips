import 'package:flutter/cupertino.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerTipList extends StatelessWidget {
  const ShimmerTipList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 3,
      itemBuilder: (context, i) => Shimmer.fromColors(
        baseColor: CupertinoColors.systemGrey4,
        highlightColor: CupertinoColors.systemGrey6,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Container(width: 40, height: 40, color: CupertinoColors.white),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 16, width: 120, color: CupertinoColors.white),
                    const SizedBox(height: 10),
                    Container(
                        height: 12, width: 80, color: CupertinoColors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
