import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/scrolling_title.dart';

/// Utility class for formatting tip-related information
class TipUtils {
  /// Formats tip metadata for display in UI components
  /// Returns a formatted string with reading time estimate and word count
  static String formatTipMetadata(String tipText) {
    final wordCount = tipText.split(RegExp(r'\s+')).length;
    final readingTime =
        (wordCount / 200).ceil(); // Assuming 200 words per minute
    return 'Reading time: $readingTime min • $wordCount words';
  }

  /// Extracts sections from tip text for better organization
  static Map<String, String> extractTipSections(String tipText) {
    final sections = <String, String>{};
    final lines = tipText.split('\n');
    String currentSection = 'content';
    final buffer = StringBuffer();

    for (final line in lines) {
      if (line.startsWith('## ')) {
        // Save previous section
        if (buffer.isNotEmpty) {
          sections[currentSection] = buffer.toString().trim();
          buffer.clear();
        }
        // Start new section
        currentSection = line.substring(3).toLowerCase().replaceAll(' ', '_');
      } else {
        buffer.writeln(line);
      }
    }

    // Save last section
    if (buffer.isNotEmpty) {
      sections[currentSection] = buffer.toString().trim();
    }

    return sections;
  }

  /// Determines if the tip contains code examples
  static bool hasCodeExamples(String tipText) {
    return tipText.contains('```') || tipText.contains('`');
  }

  /// Extracts code blocks from the tip text
  static List<String> extractCodeBlocks(String tipText) {
    final codeBlocks = <String>[];
    final regex = RegExp(r'```[\s\S]*?```', multiLine: true);
    final matches = regex.allMatches(tipText);

    for (final match in matches) {
      codeBlocks.add(match.group(0)!);
    }

    return codeBlocks;
  }
}

/// Enhanced tip card widget with improved UX and visual design
class EnhancedTipCard extends StatelessWidget {
  final String title;
  final String content;
  final String date;
  final List<String>? references;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final Future<void> Function()? onDelete;

  const EnhancedTipCard({
    super.key,
    required this.title,
    required this.content,
    required this.date,
    this.references,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasCode = TipUtils.hasCodeExamples(content);
    final metadata = TipUtils.formatTipMetadata(content);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with title and favorite button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onFavorite();
                    },
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: isFavorite ? 1.2 : 1.0,
                      child: Icon(
                        isFavorite
                            ? CupertinoIcons.heart_fill
                            : CupertinoIcons.heart,
                        color: isFavorite
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemGrey,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Content preview
              Text(
                _getContentPreview(content),
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 16),

              // Footer with metadata and indicators
              Row(
                children: [
                  if (hasCode) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            CupertinoIcons.doc_text,
                            size: 12,
                            color: CupertinoColors.systemPurple,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Code',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.systemPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      metadata,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            CupertinoColors.tertiaryLabel.resolveFrom(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    // Remove markdown formatting and extract first paragraph
    final cleaned = content
        .replaceAll(RegExp(r'#{1,6}\s'), '') // Remove headers
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Remove bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Remove italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Remove inline code
        .replaceAll(
            RegExp(r'```[\s\S]*?```'), '[Code Example]') // Replace code blocks
        .replaceAll(RegExp(r'\n\s*\n'), ' ') // Replace double newlines
        .replaceAll(RegExp(r'\n'), ' ') // Replace single newlines
        .trim();

    return cleaned.length > 150 ? '${cleaned.substring(0, 150)}...' : cleaned;
  }
}

/// Full screen tip view with enhanced UX and comprehensive display
class FullTipView extends StatelessWidget {
  final String topic;
  final String text;
  final String date;
  final List<String>? references;
  final bool isFavorite;
  final VoidCallback onFavorite;
  final Future<void> Function()? onDelete;
  final VoidCallback onCopy;

  const FullTipView({
    super.key,
    required this.topic,
    required this.text,
    required this.date,
    this.references,
    required this.isFavorite,
    required this.onFavorite,
    this.onDelete,
    required this.onCopy,
  });

  /// Clean up tip text for better display by removing redundant titles
  String _cleanTipTextForDisplay(String tipText) {
    final lines = tipText.split('\n');
    final cleanedLines = <String>[];
    bool skipNext = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line == '## Tip Title') {
        skipNext = true;
        continue;
      }

      if (skipNext && line.isNotEmpty && !line.startsWith('#')) {
        skipNext = false;
        continue;
      }

      cleanedLines.add(lines[i]);
    }

    return cleanedLines.join('\n');
  }

  /// Show error dialog for links that cannot be opened
  void _showLinkErrorDialog(BuildContext context, String href) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Unable to Open Link'),
        content:
            Text('Could not open: $href\n\nWould you like to copy the link?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Copy Link'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: href));
              Navigator.of(context).pop();

              // Show confirmation
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  content: const Text('Link copied to clipboard!'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              );
            },
          ),
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      // Enhanced navigation bar with gradient background
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground
            .resolveFrom(context)
            .withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey4.resolveFrom(context),
            width: 0.33,
          ),
        ),
        // Scrolling title for long topic names
        middle: ScrollingTitle(
          text: topic,
          scrollSpeed: 60.0,
          pauseWhenFits: true,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        // Action buttons
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Copy button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.lightImpact();
                onCopy();

                // Show success feedback
                showCupertinoDialog(
                  context: context,
                  builder: (context) => CupertinoAlertDialog(
                    content: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(CupertinoIcons.checkmark_circle_fill,
                            color: CupertinoColors.systemGreen, size: 18),
                        SizedBox(width: 8),
                        Text('Copied!'),
                      ],
                    ),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('OK'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: CupertinoColors.systemBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  CupertinoIcons.doc_on_clipboard,
                  size: 18,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Favorite button
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                HapticFeedback.lightImpact();
                onFavorite();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isFavorite
                      ? CupertinoColors.systemRed.withOpacity(0.15)
                      : CupertinoColors.systemGrey6.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFavorite
                        ? CupertinoColors.systemRed.withOpacity(0.4)
                        : CupertinoColors.systemGrey4,
                    width: 1,
                  ),
                ),
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: isFavorite ? 1.1 : 1.0,
                  child: Icon(
                    isFavorite
                        ? CupertinoIcons.heart_fill
                        : CupertinoIcons.heart,
                    color: isFavorite
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGrey,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Main content with gradient background
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CupertinoColors.systemBackground.resolveFrom(context),
              CupertinoColors.systemGroupedBackground
                  .resolveFrom(context)
                  .withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main scrollable content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tip metadata banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CupertinoColors.systemBlue.withOpacity(0.08),
                              CupertinoColors.systemBlue.withOpacity(0.12),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: CupertinoColors.systemBlue.withOpacity(0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  CupertinoColors.systemBlue.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBlue
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.lightbulb,
                                size: 20,
                                color: CupertinoColors.systemBlue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Learning Tip',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.systemBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    TipUtils.formatTipMetadata(text),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.secondaryLabel
                                          .resolveFrom(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Enhanced markdown content
                      MarkdownBody(
                        data: _cleanTipTextForDisplay(text),
                        selectable:
                            false, // Prevent text selection to avoid "selected" appearance
                        onTapLink: (text, href, title) async {
                          if (href != null && href.isNotEmpty) {
                            try {
                              final url = Uri.parse(href);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                _showLinkErrorDialog(context, href);
                              }
                            } catch (e) {
                              try {
                                final url = Uri.parse(href);
                                await launchUrl(url);
                              } catch (e2) {
                                _showLinkErrorDialog(context, href);
                              }
                            }
                          }
                        },
                        styleSheet: MarkdownStyleSheet(
                          // Headers with enhanced styling
                          h1: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label,
                            height: 1.3,
                          ),
                          h2: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: CupertinoColors.label,
                            height: 1.3,
                          ),
                          h3: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                            height: 1.3,
                          ),

                          // Body text optimized for readability
                          p: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: CupertinoColors.label,
                            letterSpacing: 0.2,
                          ),

                          // Enhanced list styling
                          listBullet: const TextStyle(
                            fontSize: 16,
                            color: CupertinoColors.activeBlue,
                            fontWeight: FontWeight.w600,
                          ),

                          // Inline code with proper contrast
                          code: TextStyle(
                            fontFamily: 'SF Mono',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            backgroundColor: CupertinoColors.systemGrey5
                                .resolveFrom(context),
                            color: CupertinoColors.systemPurple,
                          ),

                          // FIXED: Code blocks with proper theming
                          codeblockDecoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6
                                .resolveFrom(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: CupertinoColors.systemGrey4
                                  .resolveFrom(context),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.systemGrey
                                    .withOpacity(0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          codeblockPadding: const EdgeInsets.all(20),

                          // Quote styling
                          blockquote: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: CupertinoColors.systemGrey,
                            height: 1.5,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                            border: const Border(
                              left: BorderSide(
                                color: CupertinoColors.activeBlue,
                                width: 4,
                              ),
                            ),
                          ),
                          blockquotePadding: const EdgeInsets.all(16),

                          // Link styling
                          a: const TextStyle(
                            color: CupertinoColors.activeBlue,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Enhanced metadata section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              CupertinoColors.systemGroupedBackground
                                  .resolveFrom(context),
                              CupertinoColors.systemGrey6
                                  .resolveFrom(context)
                                  .withOpacity(0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: CupertinoColors.systemGrey4
                                .resolveFrom(context),
                            width: 0.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  CupertinoColors.systemGrey.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Creation date
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey5,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.calendar,
                                    size: 16,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Created: $date',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: CupertinoColors.secondaryLabel,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            // References section
                            if (references != null &&
                                references!.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.activeBlue
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.tag,
                                      size: 16,
                                      color: CupertinoColors.activeBlue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'References:',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.label,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Reference list
                              ...references!.map((ref) => Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(width: 34),
                                        Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.only(
                                              top: 8, right: 12),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.activeBlue,
                                            borderRadius:
                                                BorderRadius.circular(2),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            ref,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: CupertinoColors
                                                  .secondaryLabel,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Delete button section
              if (onDelete != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGroupedBackground
                        .resolveFrom(context),
                    border: Border(
                      top: BorderSide(
                        color: CupertinoColors.systemGrey4.resolveFrom(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.destructiveRed,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      onPressed: () {
                        HapticFeedback.mediumImpact();

                        showCupertinoDialog(
                          context: context,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text(
                              'Delete Tip',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            content: const Text(
                              'Are you sure you want to delete this tip? This action cannot be undone.',
                              style: TextStyle(fontSize: 15),
                            ),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              CupertinoDialogAction(
                                isDestructiveAction: true,
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                onPressed: () async {
                                  HapticFeedback.heavyImpact();
                                  Navigator.of(context).pop();
                                  Navigator.of(context).pop();
                                  await onDelete!();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            CupertinoIcons.delete,
                            size: 18,
                            color: CupertinoColors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Delete Tip',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
