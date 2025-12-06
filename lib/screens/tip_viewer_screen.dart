import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/scrolling_title.dart';

/// Screen for viewing a single tip in detail
/// Displays the full tip content with markdown formatting
/// Follows the Cupertino design pattern consistent with the rest of the app
class TipViewerScreen extends StatefulWidget {
  final String tip;
  final String? title;
  final String? topic;
  final List<String>? references;
  final bool showActions;

  const TipViewerScreen({
    super.key,
    required this.tip,
    this.title,
    this.topic,
    this.references,
    this.showActions = true,
  });

  @override
  State<TipViewerScreen> createState() => _TipViewerScreenState();
}

class _TipViewerScreenState extends State<TipViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 10 && !_isScrolled) {
      setState(() => _isScrolled = true);
    } else if (_scrollController.offset <= 10 && _isScrolled) {
      setState(() => _isScrolled = false);
    }
  }

  String _extractTitle() {
    if (widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }

    // Extract title from tip content
    final lines = widget.tip.split('\n');
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

    return 'Your Daily Tip';
  }

  Future<void> _shareTip() async {
    await Clipboard.setData(ClipboardData(text: widget.tip));
    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Tip Copied'),
          content: const Text('The tip has been copied to your clipboard.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  String _formatTipMetadata() {
    final wordCount = widget.tip.split(RegExp(r'\s+')).length;
    final readingTime = (wordCount / 200).ceil();
    return 'Reading time: $readingTime min • $wordCount words';
  }

  @override
  Widget build(BuildContext context) {
    final displayTitle = _extractTitle();

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: ScrollingTitle(
          text: displayTitle,
        ),
        trailing: widget.showActions
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _shareTip,
                child: const Icon(CupertinoIcons.share),
              )
            : null,
      ),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border(
                    bottom: BorderSide(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic Badge
                    if (widget.topic != null && widget.topic!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.activeBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.topic!,
                          style: const TextStyle(
                            color: CupertinoColors.activeBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    // Title
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.label,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Metadata
                    Text(
                      _formatTipMetadata(),
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tip Content
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: MarkdownBody(
                  data: widget.tip,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                    h2: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.label,
                    ),
                    h3: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                    p: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: CupertinoColors.label.resolveFrom(context),
                    ),
                    code: TextStyle(
                      backgroundColor:
                          CupertinoColors.systemGrey6.resolveFrom(context),
                      color: CupertinoColors.systemRed.resolveFrom(context),
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6.resolveFrom(context),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: CupertinoColors.systemGrey5.resolveFrom(context),
                      ),
                    ),
                    blockquote: TextStyle(
                      color:
                          CupertinoColors.secondaryLabel.resolveFrom(context),
                      fontStyle: FontStyle.italic,
                    ),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color:
                              CupertinoColors.systemGrey3.resolveFrom(context),
                          width: 4,
                        ),
                      ),
                    ),
                    listBullet: const TextStyle(
                      fontSize: 16,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  onTapLink: (text, href, title) async {
                    if (href != null) {
                      final uri = Uri.parse(href);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                ),
              ),
            ),
            // References Section
            if (widget.references != null && widget.references!.isNotEmpty)
              SliverToBoxAdapter(
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: CupertinoColors.systemGrey5.resolveFrom(context),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'References',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...widget.references!.map(
                        (ref) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(
                                child: Text(
                                  ref,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.secondaryLabel
                                        .resolveFrom(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Bottom Spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 40),
            ),
          ],
        ),
      ),
    );
  }
}
