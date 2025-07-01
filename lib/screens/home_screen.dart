import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/api_key_entry.dart';
import '../models/topic_entry.dart';
import '../models/tip_entry.dart';
import '../widgets/cupertino_topic_chip.dart';
import '../widgets/tip_card.dart';
import '../widgets/shimmer_tip_list.dart';
import '../widgets/app_stats_widget.dart';
import 'settings_screen.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../services/notifications.dart';
import 'dart:math';
import 'dart:io';
import 'dart:async';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _topicController = TextEditingController();
  final List<TipEntry> _tips = [];
  final Set<int> _favorites = {};
  int? _selectedTopicIndex;
  int _selectedApiKeyIndex = 0;
  bool _loadingTip = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedIndex();
    _loadInitialTopics();
    _loadRecentTips();
  }

  Future<void> _loadSelectedIndex() async {
    final settings = Hive.box('settings');
    setState(() => _selectedApiKeyIndex =
        settings.get('selectedApiKeyIndex', defaultValue: 0));
  }

  Future<void> _loadInitialTopics() async {
    final topicsBox = Hive.box<TopicEntry>('topics');
    if (topicsBox.isEmpty) {
      // Add default topics
      await topicsBox.add(TopicEntry(topic: 'Time Management'));
      await topicsBox.add(TopicEntry(topic: 'Mindfulness'));
      await topicsBox.add(TopicEntry(topic: 'Productivity'));
      await topicsBox.add(TopicEntry(topic: 'Health & Wellness'));
      await topicsBox.add(TopicEntry(topic: 'Personal Growth'));
      await topicsBox.add(TopicEntry(topic: 'Flutter Development'));
      await topicsBox.add(TopicEntry(topic: 'Dart Programming'));
      await topicsBox.add(TopicEntry(topic: 'Code Optimization'));
      await topicsBox.add(TopicEntry(topic: 'UI/UX Design'));
      await topicsBox.add(TopicEntry(topic: 'Git & Version Control'));
    }
  }

  Future<void> _loadRecentTips() async {
    final tipsBox = Hive.box<TipEntry>('tips');
    final allTips = tipsBox.values.toList();
    // Sort by creation date, most recent first
    allTips.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _tips.clear();
      _tips.addAll(allTips.take(10)); // Show only recent 10 tips
    });
  }

  void _showTopicSheet({bool edit = false, int? idx}) {
    final topicsBox = Hive.box<TopicEntry>('topics');
    final topics = topicsBox.values.toList();

    final controller = TextEditingController(
      text: edit && idx != null && idx < topics.length ? topics[idx].topic : '',
    );
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(edit ? 'Edit Topic' : 'Add Topic'),
        message: CupertinoTextField(
          controller: controller,
          placeholder: "Topic name",
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _addOrEditTopic(controller.text, edit: edit, idx: idx);
            },
            child: Text(edit ? 'Update' : 'Add'),
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _addOrEditTopic(String topic,
      {bool edit = false, int? idx}) async {
    topic = topic.trim();
    if (topic.isEmpty) return;

    final topicsBox = Hive.box<TopicEntry>('topics');
    final topics = topicsBox.values.toList();

    if (edit && idx != null && idx < topics.length) {
      topics[idx].topic = topic;
      await topics[idx].save();
      _showSnackbar('Topic updated.');
    } else {
      // Check if topic already exists
      final exists =
          topics.any((t) => t.topic.toLowerCase() == topic.toLowerCase());
      if (!exists) {
        await topicsBox.add(TopicEntry(topic: topic));
        _showSnackbar('Topic "$topic" added.');
      } else {
        _showSnackbar('Topic "$topic" already exists.',
            color: CupertinoColors.systemOrange);
      }
    }
  }

  Future<void> _removeTopic(int index) async {
    final topicsBox = Hive.box<TopicEntry>('topics');
    final topics = topicsBox.values.toList();

    if (index < topics.length) {
      final removed = topics[index].topic;
      await topics[index].delete();
      if (_selectedTopicIndex == index) {
        setState(() => _selectedTopicIndex = null);
      }
      _showSnackbar('Topic "$removed" removed.',
          color: CupertinoColors.systemRed);
    }
  }

  Future<void> _generateTip(String apiKey) async {
    if (_selectedTopicIndex == null) return;

    final topicsBox = Hive.box<TopicEntry>('topics');
    final topics = topicsBox.values.toList();

    if (_selectedTopicIndex! >= topics.length) return;

    setState(() => _loadingTip = true);
    final selectedTopic = topics[_selectedTopicIndex!].topic;
    final prompt = '''
Generate an extremely comprehensive, beginner-friendly, and practical tip about $selectedTopic. This tip will be shown to users who may be complete beginners, so explain every concept clearly and provide extensive educational value.

Please format your response exactly as follows:

## Tip Title
[Create a compelling, descriptive title that clearly indicates what the user will learn]

## The Tip
[Write a detailed, actionable tip that is 400-600 words long. Make it beginner-friendly by:
- Explaining technical terms and concepts in simple language
- Providing step-by-step guidance with clear explanations
- Including real-world examples and use cases
- Explaining WHY each step matters
- Adding context about when and where to apply this tip
If this is a programming/coding topic, include comprehensive code examples with extensive comments explaining every single line of code.]

## Detailed Code Example (Essential for Programming Topics)
```dart
// For programming topics, provide working, production-ready code examples
// Add comprehensive comments explaining EVERY line of code
// Example:
// This line declares a variable called 'userName' which stores text data
String userName = 'John Doe'; // String means text, userName is the variable name

// This function performs a specific task (explain what it does)
void processUserData() {
  // Step 1: Explain what this line does and why it's needed
  if (userName.isEmpty) { // Check if the text is empty (has no characters)
    print('Error: Username cannot be empty'); // Show error message to user
    return; // Exit the function early to prevent errors
  }
  
  // Step 2: Continue with detailed explanations for each line
  // Include before/after comparisons when relevant
  // Show common variations and alternatives
}
```

## Why This Works (Technical Deep Dive)
[Provide a comprehensive explanation covering:
- The underlying principles and theory
- Technical reasons why this approach is effective
- How it solves common problems
- Performance implications and considerations
- Security aspects (if applicable)
- Compatibility and browser/platform considerations
- Memory usage and optimization aspects]

## Step-by-Step Implementation Guide
1. **[First Action]**: [Detailed explanation with specific instructions, expected outcomes, and potential issues to watch for]
2. **[Second Action]**: [Include troubleshooting tips and what to do if something goes wrong]
3. **[Third Action]**: [Explain how to verify the implementation is working correctly]
4. **[Fourth Action]**: [Add testing and validation steps]
5. **[Fifth Action]**: [Include maintenance and monitoring recommendations]

## ⚠️ Important Warnings & Common Mistakes
- **⚠️ Critical Warning**: [Highlight any dangerous pitfalls or critical errors to avoid]
- **❌ Common Mistake #1**: [Describe what beginners often do wrong and why it's problematic]
- **❌ Common Mistake #2**: [Include the correct way to handle this situation]
- **❌ Common Mistake #3**: [Add debugging tips for when things go wrong]
- **🔒 Security Consideration**: [Include any security-related warnings and best practices]

## 🎯 Best Practices & Professional Tips
- **✅ Best Practice #1**: [Share industry-standard approaches and why they're recommended]
- **✅ Best Practice #2**: [Include performance optimization tips]
- **✅ Best Practice #3**: [Add maintainability and code quality considerations]
- **🚀 Pro Tip**: [Share advanced techniques used by experienced developers]
- **📏 Code Quality**: [Include formatting, naming, and organization standards]

## 🔧 Advanced Techniques & Optimizations
- **Advanced Technique #1**: [Share sophisticated approaches for experienced users]
- **Performance Optimization**: [Include specific techniques to improve speed and efficiency]
- **Scalability Considerations**: [Explain how to handle growth and increased load]
- **Error Handling**: [Comprehensive error handling and recovery strategies]
- **Testing Strategy**: [Include unit testing, integration testing approaches]

## 🐛 Troubleshooting Guide
**Common Issues and Solutions:**
- **Problem**: [Describe a typical issue users face]
  **Solution**: [Provide step-by-step resolution]
  **Prevention**: [How to avoid this issue in the future]

- **Problem**: [Another common issue]
  **Solution**: [Detailed fix with code examples if needed]
  **Debug Steps**: [How to identify and diagnose the problem]

## 🔗 Essential Resources & References
- **📚 Official Documentation**: [Include actual clickable links to official docs with descriptive titles]
- **🎥 Video Tutorials**: [Link to high-quality educational videos]
- **📖 In-Depth Guides**: [Comprehensive tutorials and guides]
- **🛠️ Tools & Libraries**: [Recommended tools, IDEs, extensions, and libraries]
- **👥 Community Resources**: [Forums, Discord servers, Stack Overflow tags]
- **📱 Example Projects**: [GitHub repositories with working examples]

## 🎓 Learning Path & Next Steps
1. **Beginner Next Step**: [What to learn next if you're just starting]
2. **Intermediate Challenge**: [More advanced concepts to explore]
3. **Advanced Projects**: [Suggest complex projects to practice these skills]
4. **Related Topics**: [Connected concepts that would be valuable to learn]

## 💡 Real-World Applications
- **Use Case #1**: [Specific industry or project where this is valuable]
- **Use Case #2**: [Another practical application with examples]
- **Case Study**: [Brief example of how this solved a real problem]

CRITICAL REQUIREMENTS:
- Explain every technical term as if the reader has never heard it before
- Include extensive code comments for every single line when showing code
- Provide multiple examples and variations
- Add visual descriptions where code creates UI elements
- Include error messages users might see and how to fix them
- Make the content educational and comprehensive, not just instructional
- Use bullet points, numbered lists, and clear formatting for easy scanning
- Include actual working URLs in the references section
- Add emoji icons to make sections easily identifiable
- Explain the "why" behind every recommendation, not just the "how"
''';

    try {
      final tipText = await fetchGeminiTip(apiKey, prompt);

      // Extract title from the generated tip
      final tipTitle = _extractTitleFromTip(tipText);

      // Save to Hive and local list
      final tipsBox = Hive.box<TipEntry>('tips');
      final tipEntry = TipEntry(
        tip: tipText,
        createdAt: DateTime.now(),
        isFavorite: false,
        references: [
          'Topic: $selectedTopic',
          'Generated via Gemini AI',
          'Title: $tipTitle'
        ],
      );
      await tipsBox.add(tipEntry);

      setState(() => _tips.insert(0, tipEntry));

      // Navigate directly to the tip preview
      _navigateToTipPreview(tipEntry, tipTitle);

      // Schedule notification if enabled (handle errors gracefully)
      try {
        await _scheduleRandomTipNotification();
      } catch (e) {
        // Handle notification scheduling errors gracefully
        print('Notification scheduling failed: $e');
        if (e.toString().contains('exact_alarms') ||
            e.toString().contains('Exact alarms permission')) {
          _showSnackbar(
              'Tip saved! Notification scheduling requires exact alarms permission in settings.',
              color: CupertinoColors.systemOrange);
        } else {
          _showSnackbar('Tip saved! Notification scheduling unavailable.',
              color: CupertinoColors.systemOrange);
        }
      }
    } catch (e) {
      // Handle error but don't show technical details
      String errorMessage = 'Failed to generate tip. Please try again.';
      if (e.toString().contains('API')) {
        errorMessage = 'API error. Please check your API key.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }

      _showSnackbar(errorMessage, color: CupertinoColors.systemRed);
    } finally {
      setState(() => _loadingTip = false);
    }
  }

  Future<void> _scheduleRandomTipNotification() async {
    final settings = Hive.box('settings');
    final notificationsEnabled =
        settings.get('notificationsEnabled', defaultValue: true);

    if (notificationsEnabled) {
      try {
        // Schedule the current tip for a random time later today
        if (_tips.isNotEmpty) {
          final random = Random();
          final randomTip = _tips[random.nextInt(_tips.length)];

          // Schedule for 2-6 hours from now
          final hoursFromNow = 2 + random.nextInt(4);
          final scheduledTime =
              DateTime.now().add(Duration(hours: hoursFromNow));

          await scheduleDailyTipNotification(
            randomTip.tip,
            references: randomTip.references,
            hour: scheduledTime.hour,
            minute: scheduledTime.minute,
          );

          _showSnackbar(
              'Tip scheduled for ${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}!',
              color: CupertinoColors.systemGreen);
        }
      } catch (e) {
        // Handle exact alarms permission issue gracefully
        print('Notification scheduling failed: $e');
        _showSnackbar(
            'Tip saved! Notification scheduling requires additional permissions.',
            color: CupertinoColors.systemOrange);
      }
    }
  }

  Future<void> _generateRandomTip() async {
    final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');
    final topicsBox = Hive.box<TopicEntry>('topics');
    final apiKeys = apiKeyBox.values.toList();
    final topics = topicsBox.values.toList();

    if (apiKeys.isEmpty || topics.isEmpty) {
      _showSnackbar('Please add topics and API keys first',
          color: CupertinoColors.systemRed);
      return;
    }

    final selectedIdx = (_selectedApiKeyIndex >= apiKeys.length)
        ? (apiKeys.isEmpty ? 0 : apiKeys.length - 1)
        : _selectedApiKeyIndex;

    setState(() => _loadingTip = true);

    try {
      final random = Random();
      final randomTopic = topics[random.nextInt(topics.length)];
      final prompt = '''
Generate an extremely comprehensive, beginner-friendly, and practical tip about ${randomTopic.topic}. This tip will be shown to users who may be complete beginners, so explain every concept clearly and provide extensive educational value.

Please format your response exactly as follows:

## Tip Title
[Create a compelling, descriptive title that clearly indicates what the user will learn]

## The Tip
[Write a detailed, actionable tip that is 400-600 words long. Make it beginner-friendly by:
- Explaining technical terms and concepts in simple language
- Providing step-by-step guidance with clear explanations
- Including real-world examples and use cases
- Explaining WHY each step matters
- Adding context about when and where to apply this tip
If this is a programming/coding topic, include comprehensive code examples with extensive comments explaining every single line of code.]

## Detailed Code Example (Essential for Programming Topics)
```dart
// For programming topics, provide working, production-ready code examples
// Add comprehensive comments explaining EVERY line of code
// Example:
// This line declares a variable called 'userName' which stores text data
String userName = 'John Doe'; // String means text, userName is the variable name

// This function performs a specific task (explain what it does)
void processUserData() {
  // Step 1: Explain what this line does and why it's needed
  if (userName.isEmpty) { // Check if the text is empty (has no characters)
    print('Error: Username cannot be empty'); // Show error message to user
    return; // Exit the function early to prevent errors
  }
  
  // Step 2: Continue with detailed explanations for each line
  // Include before/after comparisons when relevant
  // Show common variations and alternatives
}
```

## Why This Works (Technical Deep Dive)
[Provide a comprehensive explanation covering:
- The underlying principles and theory
- Technical reasons why this approach is effective
- How it solves common problems
- Performance implications and considerations
- Security aspects (if applicable)
- Compatibility and browser/platform considerations
- Memory usage and optimization aspects]

## Step-by-Step Implementation Guide
1. **[First Action]**: [Detailed explanation with specific instructions, expected outcomes, and potential issues to watch for]
2. **[Second Action]**: [Include troubleshooting tips and what to do if something goes wrong]
3. **[Third Action]**: [Explain how to verify the implementation is working correctly]
4. **[Fourth Action]**: [Add testing and validation steps]
5. **[Fifth Action]**: [Include maintenance and monitoring recommendations]

## ⚠️ Important Warnings & Common Mistakes
- **⚠️ Critical Warning**: [Highlight any dangerous pitfalls or critical errors to avoid]
- **❌ Common Mistake #1**: [Describe what beginners often do wrong and why it's problematic]
- **❌ Common Mistake #2**: [Include the correct way to handle this situation]
- **❌ Common Mistake #3**: [Add debugging tips for when things go wrong]
- **🔒 Security Consideration**: [Include any security-related warnings and best practices]

## 🎯 Best Practices & Professional Tips
- **✅ Best Practice #1**: [Share industry-standard approaches and why they're recommended]
- **✅ Best Practice #2**: [Include performance optimization tips]
- **✅ Best Practice #3**: [Add maintainability and code quality considerations]
- **🚀 Pro Tip**: [Share advanced techniques used by experienced developers]
- **📏 Code Quality**: [Include formatting, naming, and organization standards]

## 🔧 Advanced Techniques & Optimizations
- **Advanced Technique #1**: [Share sophisticated approaches for experienced users]
- **Performance Optimization**: [Include specific techniques to improve speed and efficiency]
- **Scalability Considerations**: [Explain how to handle growth and increased load]
- **Error Handling**: [Comprehensive error handling and recovery strategies]
- **Testing Strategy**: [Include unit testing, integration testing approaches]

## 🐛 Troubleshooting Guide
**Common Issues and Solutions:**
- **Problem**: [Describe a typical issue users face]
  **Solution**: [Provide step-by-step resolution]
  **Prevention**: [How to avoid this issue in the future]

- **Problem**: [Another common issue]
  **Solution**: [Detailed fix with code examples if needed]
  **Debug Steps**: [How to identify and diagnose the problem]

## 🔗 Essential Resources & References
- **📚 Official Documentation**: [Include actual clickable links to official docs with descriptive titles]
- **🎥 Video Tutorials**: [Link to high-quality educational videos]
- **📖 In-Depth Guides**: [Comprehensive tutorials and guides]
- **🛠️ Tools & Libraries**: [Recommended tools, IDEs, extensions, and libraries]
- **👥 Community Resources**: [Forums, Discord servers, Stack Overflow tags]
- **📱 Example Projects**: [GitHub repositories with working examples]

## 🎓 Learning Path & Next Steps
1. **Beginner Next Step**: [What to learn next if you're just starting]
2. **Intermediate Challenge**: [More advanced concepts to explore]
3. **Advanced Projects**: [Suggest complex projects to practice these skills]
4. **Related Topics**: [Connected concepts that would be valuable to learn]

## 💡 Real-World Applications
- **Use Case #1**: [Specific industry or project where this is valuable]
- **Use Case #2**: [Another practical application with examples]
- **Case Study**: [Brief example of how this solved a real problem]

CRITICAL REQUIREMENTS:
- Explain every technical term as if the reader has never heard it before
- Include extensive code comments for every single line when showing code
- Provide multiple examples and variations
- Add visual descriptions where code creates UI elements
- Include error messages users might see and how to fix them
- Make the content educational and comprehensive, not just instructional
- Use bullet points, numbered lists, and clear formatting for easy scanning
- Include actual working URLs in the references section
- Add emoji icons to make sections easily identifiable
- Explain the "why" behind every recommendation, not just the "how"
''';

      final tipText = await fetchGeminiTip(apiKeys[selectedIdx].key, prompt);

      // Extract title from the generated tip
      final tipTitle = _extractTitleFromTip(tipText);

      // Save to Hive and local list
      final tipsBox = Hive.box<TipEntry>('tips');
      final tipEntry = TipEntry(
        tip: tipText,
        createdAt: DateTime.now(),
        isFavorite: false,
        references: [
          'Topic: ${randomTopic.topic}',
          'Random Generation',
          'Generated via Gemini AI',
          'Title: $tipTitle'
        ],
      );
      await tipsBox.add(tipEntry);

      setState(() => _tips.insert(0, tipEntry));

      // Navigate directly to the tip preview
      _navigateToTipPreview(tipEntry, tipTitle);
    } catch (e) {
      // Handle error but don't show technical details
      String errorMessage = 'Failed to generate random tip. Please try again.';
      if (e.toString().contains('API')) {
        errorMessage = 'API error. Please check your API key.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }

      _showSnackbar(errorMessage, color: CupertinoColors.systemRed);
    } finally {
      setState(() => _loadingTip = false);
    }
  }

  void _toggleFavorite(int index) {
    setState(() {
      if (_favorites.contains(index)) {
        _favorites.remove(index);
      } else {
        _favorites.add(index);
      }
    });
  }

  void _openSettings() async {
    await Navigator.push(context,
        CupertinoPageRoute(builder: (context) => const SettingsScreen()));
    _loadSelectedIndex();
  }

  void _showSnackbar(String msg, {Color color = CupertinoColors.activeBlue}) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(msg),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showHelpGuide() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('How to Use Daily Tips'),
        message: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Notifications Guide',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                '- Set up one or more notification schedules in Settings > Notification Settings.\n'
                '- You can choose daily, weekly, or every N days.\n'
                '- For each schedule, pick specific times or enable random time.\n'
                '- You can set different times for each day of the week.\n'
                '- Use pause/snooze to temporarily stop notifications.\n'
                '- Test notifications with the bell icon next to each schedule.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 14),
              Text(
                'App Usage',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 6),
              Text(
                '- Add your API key in Settings > API Key Management.\n'
                '- Add or edit topics for personalized tips.\n'
                '- Tap "Generate Tip" to get a new tip for the selected topic.\n'
                '- View, favorite, or delete tips in the list.\n'
                '- Access your full tip history with the "View Tips History" button.\n'
                '- Use the Settings screen to customize notifications and more.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 14),
              Text(
                'Need more help? Visit the app website or contact support.',
                style: TextStyle(
                    fontSize: 13, color: CupertinoColors.inactiveGray),
              ),
            ],
          ),
        ),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Close'),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  String _extractTitleFromTip(String tipText) {
    // Extract the title from markdown formatted tip
    final lines = tipText.split('\n');
    for (final line in lines) {
      // Look for "## Tip Title" followed by the actual title
      if (line.startsWith('## Tip Title')) {
        // Find the next non-empty line after "## Tip Title"
        final titleIndex = lines.indexOf(line);
        for (int i = titleIndex + 1; i < lines.length; i++) {
          final titleLine = lines[i].trim();
          if (titleLine.isNotEmpty &&
              !titleLine.startsWith('#') &&
              !titleLine.startsWith('[') &&
              !titleLine.startsWith('*')) {
            return titleLine.replaceAll(
                RegExp(r'[\[\]"]'), ''); // Remove brackets and quotes
          }
        }
      }
      // Also check for direct title lines that start with ## (but not sections)
      if (line.startsWith('## ') &&
          !line.contains('Tip Title') &&
          !line.contains('The Tip') &&
          !line.contains('Why It Works') &&
          !line.contains('Code Example') &&
          !line.contains('Quick Action') &&
          !line.contains('Advanced Tips') &&
          !line.contains('Resources')) {
        return line.substring(3).trim(); // Remove "## " prefix
      }
    }

    // Fallback: try to find first meaningful line
    for (final line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isNotEmpty &&
          !cleanLine.startsWith('#') &&
          !cleanLine.startsWith('[') &&
          !cleanLine.startsWith('Generate a comprehensive') &&
          cleanLine.length > 10) {
        return cleanLine.substring(0, math.min(50, cleanLine.length)) +
            (cleanLine.length > 50 ? '...' : '');
      }
    }

    return 'Daily Tip'; // Ultimate fallback
  }

  String _extractTitleFromReferences(TipEntry tip) {
    // Extract title from references or fall back to extracted title from tip content
    if (tip.references != null) {
      for (final ref in tip.references!) {
        if (ref.startsWith('Title: ')) {
          return ref.substring(7); // Remove 'Title: ' prefix
        }
      }
    }

    // Fallback: extract title from tip content
    return _extractTitleFromTip(tip.tip);
  }

  void _navigateToTipPreview(TipEntry tipEntry, String tipTitle) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => FullTipView(
          topic: tipTitle,
          text: tipEntry.tip,
          date: tipEntry.createdAt.toLocal().toString().split(" ")[0],
          references: tipEntry.references,
          isFavorite: tipEntry.isFavorite,
          onFavorite: () {
            tipEntry.isFavorite = !tipEntry.isFavorite;
            tipEntry.save();
            // Note: setState won't work here as we're in a different context
            // The state will be updated when we return to the main screen
          },
          onDelete: () async {
            await tipEntry.delete();
            Navigator.of(context).pop(); // Go back after deletion
            // Remove from local list when we return to the main screen
            Future.delayed(Duration.zero, () {
              setState(() {
                _tips.remove(tipEntry);
              });
            });
          },
          onCopy: () => _copyTipToClipboard(tipEntry.tip),
        ),
      ),
    );
  }

  void _copyTipToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackbar('Tip copied to clipboard!',
        color: CupertinoColors.systemGreen);
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyBox = Hive.box<ApiKeyEntry>('apiKeys');

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Daily Tips'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.question_circle),
              onPressed: _showHelpGuide,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings),
              onPressed: _openSettings,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: ValueListenableBuilder(
            valueListenable: Hive.box<TopicEntry>('topics').listenable(),
            builder: (context, Box<TopicEntry> topicBox, _) {
              return ValueListenableBuilder(
                valueListenable: apiKeyBox.listenable(),
                builder: (context, Box<ApiKeyEntry> apiBox, _) {
                  final apiKeys = apiBox.values.toList();
                  final topics = topicBox.values.toList();
                  final hasApiKeys = apiKeys.isNotEmpty;
                  final selectedIdx = (_selectedApiKeyIndex >= apiKeys.length)
                      ? (apiKeys.isEmpty ? 0 : apiKeys.length - 1)
                      : _selectedApiKeyIndex;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Stats
                      const AppStatsWidget(),

                      Row(
                        children: [
                          const Text('Topics',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(CupertinoIcons.add),
                            onPressed: () => _showTopicSheet(),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 46,
                        child: topics.isEmpty
                            ? const Center(
                                child: Text('No topics yet. Add one!',
                                    style: TextStyle(
                                        color: CupertinoColors.inactiveGray)))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: topics.length,
                                itemBuilder: (context, index) =>
                                    CupertinoTopicChip(
                                  label: topics[index].topic,
                                  selected: _selectedTopicIndex == index,
                                  onTap: () => setState(
                                      () => _selectedTopicIndex = index),
                                  onDelete: () => _removeTopic(index),
                                  onLongPress: () =>
                                      _showTopicSheet(edit: true, idx: index),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton.filled(
                              child: Text(_loadingTip
                                  ? 'Generating...'
                                  : 'Generate Tip'),
                              onPressed: _selectedTopicIndex == null ||
                                      !hasApiKeys ||
                                      selectedIdx >= apiKeys.length ||
                                      _loadingTip ||
                                      topics.isEmpty
                                  ? null
                                  : () =>
                                      _generateTip(apiKeys[selectedIdx].key),
                              disabledColor: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CupertinoButton(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            color: CupertinoColors.systemGrey5,
                            child: const Icon(CupertinoIcons.shuffle,
                                color: CupertinoColors.activeBlue),
                            onPressed:
                                !hasApiKeys || _loadingTip || topics.isEmpty
                                    ? null
                                    : _generateRandomTip,
                          ),
                        ],
                      ),
                      if (!hasApiKeys)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.info,
                                  color: CupertinoColors.systemRed, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Please add an API key in settings to generate tips.',
                                  style: TextStyle(
                                      color: CupertinoColors.systemRed,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text('Your Tips',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Icon(CupertinoIcons.bell),
                            onPressed: () async {
                              await _scheduleRandomTipNotification();
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: _loadingTip
                            ? const ShimmerTipList()
                            : _tips.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(CupertinoIcons.bubble_left,
                                            size: 48,
                                            color: CupertinoColors.systemGrey),
                                        const Text('No tips yet.',
                                            style: TextStyle(
                                                color: CupertinoColors
                                                    .inactiveGray)),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _tips.length,
                                    itemBuilder: (context, index) {
                                      final tip = _tips[index];
                                      final isFavorite =
                                          _favorites.contains(index);
                                      return EnhancedTipCard(
                                        title: _extractTitleFromReferences(tip),
                                        content: tip.tip,
                                        date: tip.createdAt
                                            .toLocal()
                                            .toString()
                                            .split(" ")[0],
                                        isFavorite: isFavorite,
                                        references: tip.references,
                                        onTap: () => _navigateToTipPreview(tip,
                                            _extractTitleFromReferences(tip)),
                                        onFavorite: () =>
                                            _toggleFavorite(index),
                                        onDelete: () async {
                                          // Delete from Hive first
                                          await tip.delete();
                                          // Then remove from local list
                                          setState(() => _tips.removeAt(index));
                                        },
                                      );
                                    },
                                  ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<String> fetchGeminiTip(String apiKey, String prompt) async {
  try {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      // Add configuration for better responses
      'generationConfig': {
        'temperature': 0.7,
        'topK': 40,
        'topP': 0.95,
        'maxOutputTokens': 8192,
      },
      'safetySettings': [
        {
          'category': 'HARM_CATEGORY_HARASSMENT',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
        {
          'category': 'HARM_CATEGORY_HATE_SPEECH',
          'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
        },
      ]
    });

    final response = await http
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Daily Tips App/1.0',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 30)); // Add timeout

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check for API errors or safety blocks
      if (data.containsKey('error')) {
        final error = data['error'];
        String errorMessage = 'API Error: ';

        if (error['code'] == 400) {
          errorMessage +=
              'Invalid request. Please check your API key and try again.';
        } else if (error['code'] == 403) {
          errorMessage +=
              'API key access denied. Please verify your API key has the correct permissions.';
        } else if (error['code'] == 429) {
          errorMessage +=
              'Rate limit exceeded. Please wait a moment and try again.';
        } else if (error['code'] == 500) {
          errorMessage += 'Server error. Please try again in a few minutes.';
        } else {
          errorMessage += error['message'] ?? 'Unknown error occurred.';
        }

        throw Exception(errorMessage);
      }

      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final candidate = candidates[0];

        // Check if content was blocked by safety filters
        if (candidate.containsKey('finishReason') &&
            candidate['finishReason'] == 'SAFETY') {
          throw Exception(
              'Content was blocked by safety filters. Please try a different topic or rephrase your request.');
        }

        // Check if we have valid content
        if (candidate.containsKey('content') &&
            candidate['content'].containsKey('parts') &&
            candidate['content']['parts'].isNotEmpty) {
          final text = candidate['content']['parts'][0]['text'];
          if (text != null && text.toString().trim().isNotEmpty) {
            return text.toString();
          }
        }
      }

      throw Exception(
          'No valid content returned by Gemini API. Please try again.');
    } else if (response.statusCode == 401) {
      throw Exception(
          'Invalid API key. Please check your API key in settings.');
    } else if (response.statusCode == 403) {
      throw Exception(
          'API access forbidden. Please verify your API key has Gemini access enabled.');
    } else if (response.statusCode == 429) {
      throw Exception(
          'Rate limit exceeded. Please wait a few minutes before trying again.');
    } else if (response.statusCode >= 500) {
      throw Exception(
          'Server error (${response.statusCode}). Please try again later.');
    } else {
      // Try to parse error details from response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage =
            errorData['error']?['message'] ?? 'Unknown API error';
        throw Exception('API Error (${response.statusCode}): $errorMessage');
      } catch (_) {
        throw Exception(
            'API Error (${response.statusCode}): ${response.reasonPhrase}');
      }
    }
  } on TimeoutException {
    throw Exception(
        'Request timed out. Please check your internet connection and try again.');
  } on SocketException {
    throw Exception('Network error. Please check your internet connection.');
  } on FormatException {
    throw Exception('Invalid response format from API. Please try again.');
  } catch (e) {
    // Re-throw our custom exceptions as-is
    if (e.toString().startsWith('Exception: ')) {
      rethrow;
    }
    // Wrap unexpected errors
    throw Exception('Unexpected error: ${e.toString()}');
  }
}
