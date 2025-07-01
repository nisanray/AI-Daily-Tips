// Import statements - these bring in external functionality
import 'package:flutter/cupertino.dart'; // iOS-style UI components
import 'package:flutter/services.dart'; // Device services like clipboard
import 'package:hive/hive.dart'; // Local database functionality
import 'package:hive_flutter/hive_flutter.dart'; // Flutter-specific Hive features
import '../models/tip_entry.dart'; // Our custom tip data model
import '../widgets/scrolling_title.dart'; // Custom scrolling title widget
import '../utils/tip_utils.dart'; // Utility functions for tips
// import './tip_view_screen.dart'; // Import the tip view screen

// Define a StatefulWidget because we need to manage state (search, favorites)
// StatefulWidget allows the UI to change and update dynamically
class TipsHistoryScreen extends StatefulWidget {
  // Constructor - creates an instance of this screen
  // {super.key} passes the key parameter to the parent class
  const TipsHistoryScreen({super.key});

  @override
  // createState() method creates the mutable state for this widget
  // It returns an instance of _TipsHistoryScreenState
  State<TipsHistoryScreen> createState() => _TipsHistoryScreenState();
}

// The State class contains the actual logic and data for our screen
// The underscore (_) makes this class private to this file
class _TipsHistoryScreenState extends State<TipsHistoryScreen> {
  // TextEditingController manages the text input in our search field
  // It allows us to read what the user types and control the text
  final TextEditingController _searchController = TextEditingController();

  // String variable to store the current search query
  // This will be used to filter the tips list
  String _searchQuery = '';

  // Set to store favorite tip indices for quick lookup
  // Set is more efficient than List for checking if item exists
  final Set<int> _favorites = {};

  @override
  void initState() {
    // initState() is called once when the widget is first created
    // super.initState() calls the parent class initialization
    super.initState();

    // Add a listener to the search controller
    // This function will be called every time the user types
    _searchController.addListener(() {
      // setState() tells Flutter to rebuild the UI with new data
      setState(() {
        // Update our search query with the current text field value
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Load favorite tips from storage when screen opens
    _loadFavorites();
  }

  @override
  void dispose() {
    // dispose() is called when the widget is permanently removed
    // We must clean up resources to prevent memory leaks
    _searchController.dispose(); // Clean up the text controller
    super.dispose(); // Clean up parent resources
  }

  // Async function to load favorite tips from local storage
  Future<void> _loadFavorites() async {
    // Get the Hive box containing our tips data
    final tipsBox = Hive.box<TipEntry>('tips');

    // Loop through all tips and check which ones are favorites
    for (int i = 0; i < tipsBox.length; i++) {
      // Get the tip at current index
      final tip = tipsBox.getAt(i);

      // If tip exists and is marked as favorite, add to our set
      if (tip != null && tip.isFavorite) {
        _favorites.add(i);
      }
    }

    // Update the UI with the loaded favorites
    setState(() {});
  }

  // Function to toggle favorite status of a tip
  Future<void> _toggleFavorite(int index, TipEntry tip) async {
    // Add haptic feedback for better user experience
    HapticFeedback.lightImpact();

    // Toggle the favorite status in our local set
    if (_favorites.contains(index)) {
      _favorites.remove(index); // Remove from favorites
      tip.isFavorite = false; // Update the tip object
    } else {
      _favorites.add(index); // Add to favorites
      tip.isFavorite = true; // Update the tip object
    }

    // Save the updated tip to the database
    await tip.save();

    // Update the UI to reflect the change
    setState(() {});
  }

  // Function to extract and format the tip title for display
  String _extractTipTitle(TipEntry tip) {
    // Check if tip has references with a title
    if (tip.references != null) {
      for (final ref in tip.references!) {
        // Look for a reference that starts with 'Title: '
        if (ref.startsWith('Title: ')) {
          // Return the title without the 'Title: ' prefix
          return ref.substring(7);
        }
      }
    }

    // If no title in references, extract from tip content
    return _extractTitleFromContent(tip.tip);
  }

  // Function to extract title from tip markdown content
  String _extractTitleFromContent(String tipText) {
    // Split the tip text into individual lines
    final lines = tipText.split('\n');

    // Loop through each line to find the title
    for (final line in lines) {
      // Check if line starts with markdown header (##)
      if (line.startsWith('## Tip Title')) {
        // Find the next non-empty line after "## Tip Title"
        final titleIndex = lines.indexOf(line);
        for (int i = titleIndex + 1; i < lines.length; i++) {
          final titleLine = lines[i].trim();
          // If we find a non-empty line that's not a header, that's our title
          if (titleLine.isNotEmpty && !titleLine.startsWith('#')) {
            // Remove any markdown formatting characters
            return titleLine.replaceAll(RegExp(r'[\[\]"]'), '');
          }
        }
      }
      // Also check for direct markdown headers (but not section headers)
      if (line.startsWith('## ') &&
          !line.contains('Tip Title') &&
          !line.contains('The Tip') &&
          !line.contains('Why It Works')) {
        // Return the header text without the '## ' prefix
        return line.substring(3).trim();
      }
    }

    // If no title found, return a generic fallback
    return 'Daily Tip';
  }

  // Function to get preview text from tip content
  String _getPreviewText(String text) {
    // Remove markdown formatting for clean preview
    String preview = text.replaceAll(RegExp(r'#+\s*'), ''); // Remove headers
    preview =
        preview.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1'); // Remove bold
    preview =
        preview.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1'); // Remove italic
    preview =
        preview.replaceAll(RegExp(r'- '), '• '); // Replace dashes with bullets

    // Check if tip contains code blocks
    bool hasCode = text.contains('```');
    String codeIndicator = hasCode ? '💻 ' : '';

    // Split into lines and find first meaningful paragraph
    List<String> lines = preview.split('\n');
    String firstParagraph = lines.where((line) => line.trim().isNotEmpty).first;

    // Truncate if too long and add ellipsis
    if (firstParagraph.length > 100) {
      return '$codeIndicator${firstParagraph.substring(0, 100)}...';
    }
    return '$codeIndicator$firstParagraph';
  }

  // Function to filter tips based on search query
  List<TipEntry> _filterTips(List<TipEntry> tips) {
    // If no search query, return all tips
    if (_searchQuery.isEmpty) {
      return tips;
    }

    // Filter tips that match the search query
    return tips.where((tip) {
      // Get the tip title and content in lowercase for case-insensitive search
      final title = _extractTipTitle(tip).toLowerCase();
      final content = tip.tip.toLowerCase();

      // Check if search query matches title or content
      return title.contains(_searchQuery) || content.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // FutureBuilder handles asynchronous operations (opening database)
    // It rebuilds the UI based on the state of the Future
    return FutureBuilder(
      // Check if Hive box is already open, if not, open it
      future: Hive.isBoxOpen('tips')
          ? Future.value() // Box is open, return completed future
          : Hive.openBox<TipEntry>('tips'), // Box not open, open it

      // Builder function creates the UI based on future state
      builder: (context, snapshot) {
        // Check if the future is still loading
        if (snapshot.connectionState != ConnectionState.done) {
          // Show loading screen while waiting for database
          return const CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text('Tips History'), // Static title while loading
            ),
            child: Center(
              // CupertinoActivityIndicator is iOS-style loading spinner
              child: CupertinoActivityIndicator(),
            ),
          );
        }

        // Database is ready, get the tips box
        final tipsBox = Hive.box<TipEntry>('tips');

        // CupertinoPageScaffold provides iOS-style page structure
        return CupertinoPageScaffold(
          // Navigation bar at the top of the screen
          navigationBar: const CupertinoNavigationBar(
            // ScrollingTitle will scroll if text is too long for app bar
            middle: ScrollingTitle(
              text: 'Tips History', // The title text
              scrollSpeed: 40.0, // Pixels per second scroll speed
              pauseWhenFits: true, // Only scroll if title doesn't fit
            ),
          ),
          // SafeArea ensures content doesn't overlap system UI
          child: SafeArea(
            // ValueListenableBuilder rebuilds when Hive data changes
            // This provides real-time updates when tips are added/removed
            child: ValueListenableBuilder(
              valueListenable: tipsBox.listenable(), // Listen to box changes

              // Builder creates UI with current data
              builder: (context, Box<TipEntry> box, _) {
                // Convert box values to list and reverse for newest-first order
                final allTips = box.values.toList().reversed.toList();

                // Filter tips based on current search query
                final filteredTips = _filterTips(allTips);

                // If no tips exist, show empty state
                if (allTips.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon to make empty state more visual
                        Icon(
                          CupertinoIcons.bubble_left,
                          size: 48,
                          color: CupertinoColors.systemGrey,
                        ),
                        SizedBox(height: 16), // Spacing between icon and text
                        Text(
                          'No tips yet.',
                          style: TextStyle(
                            color: CupertinoColors.inactiveGray,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tips you save will appear here.',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Main content: search + tips list
                return Column(
                  children: [
                    // Search bar section
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, // Left and right padding
                        vertical: 12, // Top and bottom padding
                      ),
                      child: CupertinoSearchTextField(
                        controller:
                            _searchController, // Connect to our controller
                        placeholder: 'Search tips...', // Hint text
                        // onChanged is called every time user types
                        onChanged: (value) {
                          // The listener we added in initState will handle this
                        },
                      ),
                    ),

                    // Show search results count if searching
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Text(
                              '${filteredTips.length} result${filteredTips.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(), // Push clear button to right
                            CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Text('Clear'),
                              onPressed: () {
                                _searchController.clear(); // Clear search
                                HapticFeedback
                                    .selectionClick(); // Haptic feedback
                              },
                            ),
                          ],
                        ),
                      ),

                    // Tips list section
                    Expanded(
                      // ListView.builder efficiently creates list items on demand
                      child: ListView.builder(
                        padding: const EdgeInsets.all(
                            16), // Padding around entire list
                        itemCount:
                            filteredTips.length, // Number of items to show

                        // itemBuilder creates each list item
                        itemBuilder: (context, index) {
                          final tip =
                              filteredTips[index]; // Get tip for this index
                          final originalIndex =
                              allTips.indexOf(tip); // Find original index
                          final isFavorite = _favorites.contains(originalIndex);
                          final tipTitle = _extractTipTitle(tip);

                          // Dismissible allows swipe-to-delete functionality
                          return Dismissible(
                            // Unique key for each dismissible item
                            key: Key(
                                'tip_${tip.hashCode}_${tip.createdAt.millisecondsSinceEpoch}'),
                            direction: DismissDirection
                                .endToStart, // Swipe left to right

                            // Background shown when swiping
                            background: Container(
                              alignment:
                                  Alignment.centerRight, // Align to right
                              color:
                                  CupertinoColors.systemRed, // Red background
                              child: const Padding(
                                padding: EdgeInsets.only(right: 24.0),
                                child: Icon(
                                  CupertinoIcons.delete,
                                  color: CupertinoColors.white,
                                ),
                              ),
                            ),

                            // Called when item is dismissed (swiped away)
                            onDismissed: (_) async {
                              // Add haptic feedback for delete action
                              HapticFeedback.mediumImpact();

                              // Remove from favorites set if it was favorited
                              _favorites.remove(originalIndex);

                              // Delete from database - this will trigger ValueListenableBuilder
                              await tip.delete();
                            },

                            // The actual tip card content
                            child: GestureDetector(
                              onTap: () {
                                // Navigate to TipViewScreen on tap
                                // Navigator.push(
                                //   context,
                                //   CupertinoPageRoute(
                                //     builder: (context) => TipViewScreen(tip: tip),
                                //   ),
                                // );
                              },
                              child: Container(
                                // Margin between cards
                                margin: const EdgeInsets.only(bottom: 12),
                                padding:
                                    const EdgeInsets.all(16), // Internal padding

                                // Card styling
                                decoration: BoxDecoration(
                                  color: CupertinoColors
                                      .systemGrey6, // Background color
                                  borderRadius: BorderRadius.circular(
                                      12), // Rounded corners

                                  // Subtle shadow for depth
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          CupertinoColors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),

                                // Card content
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start, // Align left
                                  children: [
                                    // Title and favorite button row
                                    Row(
                                      children: [
                                        // Tip title (expandable)
                                        Expanded(
                                          child: Text(
                                            tipTitle, // Use extracted title
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: CupertinoColors.label,
                                            ),
                                            maxLines: 2, // Allow up to 2 lines
                                            overflow: TextOverflow
                                                .ellipsis, // Add ... if too long
                                          ),
                                        ),

                                        // Favorite button
                                        CupertinoButton(
                                          padding:
                                              EdgeInsets.zero, // No extra padding
                                          minSize:
                                              32, // Minimum touch target size
                                          child: Icon(
                                            // Show filled or empty heart based on favorite status
                                            isFavorite
                                                ? CupertinoIcons.heart_fill
                                                : CupertinoIcons.heart,
                                            color: isFavorite
                                                ? CupertinoColors.systemRed
                                                : CupertinoColors.systemGrey,
                                          ),
                                          // Toggle favorite when pressed
                                          onPressed: () =>
                                              _toggleFavorite(originalIndex, tip),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8), // Spacing

                                    // Tip preview text
                                    Text(
                                      _getPreviewText(tip.tip),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: CupertinoColors.systemGrey,
                                        height:
                                            1.4, // Line height for readability
                                      ),
                                      maxLines:
                                          3, // Show up to 3 lines of preview
                                      overflow: TextOverflow.ellipsis,
                                    ),

                                    const SizedBox(height: 8), // Spacing

                                    // Metadata row (date, reading time, difficulty)
                                    Row(
                                      children: [
                                        // Creation date
                                        Text(
                                          tip.createdAt
                                              .toLocal()
                                              .toString()
                                              .split(
                                                  ' ')[0], // Just the date part
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: CupertinoColors.systemGrey2,
                                          ),
                                        ),

                                        const Text(
                                          ' • ', // Separator
                                          style: TextStyle(
                                            color: CupertinoColors.systemGrey2,
                                          ),
                                        ),

                                        // Tip metadata (reading time, difficulty, etc.)
                                        Text(
                                          TipUtils.formatTipMetadata(tip.tip),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: CupertinoColors.systemGrey2,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Show references if they exist
                                    if (tip.references != null &&
                                        tip.references!.isNotEmpty) ...[
                                      const SizedBox(
                                          height:
                                              12), // Extra spacing before references

                                      const Text(
                                        'References:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: CupertinoColors.label,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // Loop through and display each reference
                                      ...tip.references!.take(3).map((ref) =>
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 2),
                                            child: GestureDetector(
                                              // Make references tappable
                                              onTap: () {
                                                // Show reference in dialog
                                                showCupertinoDialog(
                                                  context: context,
                                                  builder: (_) =>
                                                      CupertinoAlertDialog(
                                                    title:
                                                        const Text('Reference'),
                                                    content: Text(ref),
                                                    actions: [
                                                      CupertinoDialogAction(
                                                        child: const Text('Copy'),
                                                        onPressed: () {
                                                          Navigator.pop(context);
                                                          // Copy reference to clipboard
                                                          Clipboard.setData(
                                                              ClipboardData(
                                                                  text: ref));
                                                          // Haptic feedback for copy action
                                                          HapticFeedback
                                                              .lightImpact();
                                                        },
                                                      ),
                                                      CupertinoDialogAction(
                                                        child:
                                                            const Text('Close'),
                                                        onPressed: () =>
                                                            Navigator.pop(
                                                                context),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                              child: Text(
                                                ref.length > 50
                                                    ? '${ref.substring(0, 50)}...'
                                                    : ref,
                                                style: const TextStyle(
                                                  color:
                                                      CupertinoColors.activeBlue,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          )),

                                      // Show "and X more" if there are more than 3 references
                                      if (tip.references!.length > 3)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            'and ${tip.references!.length - 3} more...',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.systemGrey,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ]),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );
    }
}
