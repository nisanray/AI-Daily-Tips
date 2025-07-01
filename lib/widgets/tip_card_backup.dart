// // Import statements for Flutter framework and external packages
// import 'package:flutter/cupertino.dart'; // Cupertino (iOS-style) widgets and design
// import 'package:flutter/services.dart'; // Platform services like clipboard and haptic feedback
// import 'package:flutter_markdown/flutter_markdown.dart'; // Markdown rendering widget
// import 'package:url_launcher/url_launcher.dart'; // URL launching functionality
// import 'scrolling_title.dart'; // Custom scrolling title widget for long text
// import '../utils/tip_utils.dart'; // Utility functions for tip formatting

// /// TipCard Widget - A card component that displays a tip/advice in a list format
// /// This is a StatelessWidget which means it doesn't maintain any internal state
// /// that can change over time. All data comes from external sources (parameters).
// class TipCard extends StatelessWidget {
//   // Properties (final means they can't be changed after widget creation)
//   final String topic; // The main subject/title of the tip
//   final String text; // The full content/body of the tip in markdown format
//   final String date; // When the tip was created (formatted as string)
//   final bool isFavorite; // Whether user has marked this tip as favorite
//   final VoidCallback
//       onFavorite; // Function to call when favorite button is pressed
//   final Future<void> Function()?
//       onDelete; // Optional function for deleting the tip
//   final List<String>? references; // Optional list of reference sources

//   /// Constructor - Creates a new TipCard instance
//   /// 'required' means these parameters must be provided when creating the widget
//   /// 'this.' syntax automatically assigns the parameter to the property
//   const TipCard({
//     super.key, // Unique identifier for this widget (inherited from parent)
//     required this.topic,
//     required this.text,
//     required this.date,
//     required this.isFavorite,
//     required this.onFavorite,
//     this.onDelete, // Optional parameter (can be null)
//     this.references, // Optional parameter (can be null)
//   });

//   /// Private method to copy tip content to device clipboard
//   /// The underscore prefix (_) makes this method private to this class
//   void _copyToClipboard(BuildContext context) {
//     // Provide tactile feedback to user - makes device vibrate slightly
//     HapticFeedback.lightImpact();

//     // Copy the tip text to system clipboard so user can paste it elsewhere
//     Clipboard.setData(ClipboardData(text: text));

//     // Show a confirmation dialog using iOS-style alert
//     showCupertinoDialog(
//       context: context, // Current screen context for showing dialog
//       builder: (context) => CupertinoAlertDialog(
//         title: const Text('Copied! 📋'), // Dialog title with emoji
//         content: const Text('Tip copied to clipboard'), // Explanation message
//         actions: [
//           // Dialog button for user to dismiss the alert
//           CupertinoDialogAction(
//             child: const Text('OK'), // Button text
//             onPressed: () {
//               HapticFeedback
//                   .selectionClick(); // Feedback when button is pressed
//               Navigator.of(context).pop(); // Close the dialog
//             },
//           ),
//         ],
//       ),
//     );
//   }

//   /// Private method to navigate to the full tip view screen
//   void _showFullTip(BuildContext context) {
//     // Navigate to a new screen using iOS-style page transition
//     Navigator.of(context).push(
//       CupertinoPageRoute(
//         builder: (context) => FullTipView(
//           // Pass all necessary data to the full tip view
//           topic: topic,
//           text: text,
//           date: date,
//           references: references,
//           isFavorite: isFavorite,
//           onFavorite: onFavorite,
//           onDelete: onDelete,
//           onCopy: () => _copyToClipboard(context), // Pass copy function
//         ),
//       ),
//     );
//   }

//   /// Private method to generate a preview text from the full tip content
//   /// This creates a shortened version for display in the list card
//   String _getPreviewText(String text) {
//     // Remove markdown formatting to get clean text for preview
//     String preview =
//         text.replaceAll(RegExp(r'#+\s*'), ''); // Remove headers (#, ##, ###)
//     preview = preview.replaceAll(
//         RegExp(r'\*\*([^*]+)\*\*'), r'$1'); // Remove bold formatting
//     preview = preview.replaceAll(
//         RegExp(r'\*([^*]+)\*'), r'$1'); // Remove italic formatting
//     preview =
//         preview.replaceAll(RegExp(r'- '), '• '); // Replace dashes with bullets

//     // Check if the tip contains code blocks and add an indicator
//     bool hasCode = text.contains('```'); // Look for code block markers
//     String codeIndicator =
//         hasCode ? '💻 ' : ''; // Add computer emoji if code present

//     // Split text into lines and find the first meaningful paragraph
//     List<String> lines = preview.split('\n');
//     String firstParagraph = lines.where((line) => line.trim().isNotEmpty).first;

//     // Truncate if too long, keeping it readable
//     if (firstParagraph.length > 120) {
//       return '$codeIndicator${firstParagraph.substring(0, 120)}...';
//     }
//     return '$codeIndicator$firstParagraph';
//   }

//   /// The build method - this is called by Flutter to create the widget's UI
//   /// BuildContext provides information about where this widget fits in the widget tree
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       // Add spacing around each card for visual separation
//       padding: const EdgeInsets.symmetric(vertical: 6),
//       child: Dismissible(
//         // Unique key for each card to handle swipe-to-delete properly
//         key: Key('tip_card_${topic}_${date}_${text.hashCode}'),

//         // Allow swiping from right to left only if delete function is provided
//         direction: onDelete != null
//             ? DismissDirection.endToStart // Right to left swipe
//             : DismissDirection.none, // No swiping allowed

//         // What happens when user completes the swipe gesture
//         onDismissed: (_) async {
//           if (onDelete != null) {
//             await onDelete!(); // Execute the delete function
//           }
//         },

//         // The background shown during swipe (red delete indicator)
//         background: Container(
//           alignment: Alignment.centerRight, // Align to right side
//           color: CupertinoColors.destructiveRed, // iOS red color for deletion
//           child: const Padding(
//             padding: EdgeInsets.only(right: 24.0),
//             child: Icon(CupertinoIcons.delete, color: CupertinoColors.white),
//           ),
//         ),

//         // The main card content
//         child: GestureDetector(
//           // Handle tap to open full tip view
//           onTap: () {
//             // Provide haptic feedback when user taps the card
//             HapticFeedback.selectionClick();
//             _showFullTip(context); // Navigate to full tip view
//           },

//           // Add subtle animation and improved visual feedback
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 150), // Smooth animation
//             child: CupertinoListTile(
//               // Leading icon - circular avatar with first letter of topic
//               leading: Container(
//                 width: 40,
//                 height: 40,
//                 decoration: BoxDecoration(
//                   // Gradient background for more visual appeal
//                   gradient: LinearGradient(
//                     colors: [
//                       CupertinoColors.activeBlue.withOpacity(0.1),
//                       CupertinoColors.activeBlue.withOpacity(0.2),
//                     ],
//                     begin: Alignment.topLeft,
//                     end: Alignment.bottomRight,
//                   ),
//                   shape: BoxShape.circle, // Make it circular
//                   border: Border.all(
//                     color: CupertinoColors.activeBlue.withOpacity(0.3),
//                     width: 1.5,
//                   ),
//                 ),
//                 child: Center(
//                   child: Text(
//                     // Show first letter of topic, fallback to 'T' if empty
//                     topic.isNotEmpty ? topic[0].toUpperCase() : 'T',
//                     style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 18,
//                         color: CupertinoColors.activeBlue),
//                   ),
//                 ),
//               ),

//               // Main title - the topic of the tip
//               title: Text(
//                 topic, // Display the topic/title directly
//                 maxLines: 2, // Allow up to 2 lines
//                 overflow: TextOverflow.ellipsis, // Add ... if text is too long
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w600, // Semi-bold text
//                   fontSize: 16,
//                   letterSpacing: 0.1, // Slight letter spacing for readability
//                 ),
//               ),

//               // Subtitle - preview text, date, and metadata
//               subtitle: Text(
//                 '${_getPreviewText(text)} • $date • ${TipUtils.formatTipMetadata(text)}',
//                 maxLines: 2, // Allow up to 2 lines
//                 overflow: TextOverflow.ellipsis, // Add ... if text is too long
//                 style: const TextStyle(
//                   fontSize: 13,
//                   color: CupertinoColors.systemGrey,
//                   height: 1.3, // Line height for better readability
//                 ),
//               ),

//               // Action buttons on the right side
//               trailing: Row(
//                 mainAxisSize: MainAxisSize.min, // Only take needed space
//                 children: [
//                   // Copy button
//                   CupertinoButton(
//                     padding: EdgeInsets.zero, // Remove default padding
//                     minSize: 32, // Minimum touch target size
//                     child: Container(
//                       padding: const EdgeInsets.all(6),
//                       decoration: BoxDecoration(
//                         color: CupertinoColors.systemGrey6,
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: const Icon(
//                         CupertinoIcons.doc_on_clipboard,
//                         color: CupertinoColors.systemGrey,
//                         size: 18,
//                       ),
//                     ),
//                     onPressed: () {
//                       HapticFeedback.lightImpact(); // Haptic feedback
//                       _copyToClipboard(context);
//                     },
//                   ),

//                   const SizedBox(width: 8), // Space between buttons

//                   // Favorite button
//                   CupertinoButton(
//                     padding: EdgeInsets.zero,
//                     minSize: 32,
//                     child: AnimatedSwitcher(
//                       duration: const Duration(milliseconds: 200),
//                       child: Container(
//                         key: ValueKey(isFavorite), // Key for animation
//                         padding: const EdgeInsets.all(6),
//                         decoration: BoxDecoration(
//                           color: isFavorite
//                               ? CupertinoColors.systemRed.withOpacity(0.1)
//                               : CupertinoColors.systemGrey6,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(
//                           isFavorite
//                               ? CupertinoIcons
//                                   .heart_fill // Filled heart for favorites
//                               : CupertinoIcons
//                                   .heart, // Empty heart for non-favorites
//                           color: isFavorite
//                               ? CupertinoColors.systemRed
//                               : CupertinoColors.inactiveGray,
//                           size: 18,
//                         ),
//                       ),
//                     ),
//                     onPressed: () {
//                       // Add haptic feedback for favorite toggle
//                       HapticFeedback.lightImpact();
//                       onFavorite(); // Call the favorite toggle function
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// CupertinoListTile - A custom list tile widget that mimics iOS list design
// /// This creates a consistent look across the app matching iOS design guidelines
// class CupertinoListTile extends StatelessWidget {
//   // Widget properties for the different parts of the list tile
//   final Widget leading; // Widget shown on the left (usually an icon or avatar)
//   final Widget title; // Main text content
//   final Widget? subtitle; // Optional secondary text (nullable with ?)
//   final Widget? trailing; // Optional widget on the right (usually buttons)

//   /// Constructor for creating a CupertinoListTile
//   const CupertinoListTile({
//     Key? key, // Optional unique identifier
//     required this.leading, // Must provide a leading widget
//     required this.title, // Must provide a title widget
//     this.subtitle, // Optional subtitle
//     this.trailing, // Optional trailing widget
//   }) : super(key: key);

//   /// Build method for CupertinoListTile - creates the visual layout
//   @override
//   Widget build(BuildContext context) {
//     // Create a list of child widgets to display in a row
//     final children = <Widget>[
//       leading, // Left-side widget (icon/avatar)
//       const SizedBox(width: 12), // Fixed spacing between leading and content

//       // Expanded makes the content take all available space
//       Expanded(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start, // Align text to left
//           children: [
//             title, // Main title text
//             // Only show subtitle if it exists (not null)
//             if (subtitle != null) ...[
//               const SizedBox(height: 2), // Small gap between title and subtitle
//               DefaultTextStyle(
//                 // Apply default styling to subtitle
//                 style: TextStyle(
//                     fontSize: 13, color: CupertinoColors.inactiveGray),
//                 child:
//                     subtitle!, // The ! tells Dart we know subtitle is not null here
//               ),
//             ]
//           ],
//         ),
//       ),
//       // Only show trailing widget if it exists
//       if (trailing != null) trailing!,
//     ];

//     // Return the container that holds all the content
//     return Container(
//       // Internal spacing within the container
//       padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
//       decoration: BoxDecoration(
//         // Background color that adapts to light/dark mode
//         color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
//         borderRadius: BorderRadius.circular(15), // Rounded corners
//         // Add subtle shadow for depth
//         boxShadow: [
//           BoxShadow(
//             color: CupertinoColors.systemGrey.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       // Row arranges children horizontally
//       child: Row(
//         crossAxisAlignment:
//             CrossAxisAlignment.center, // Center items vertically
//         children: children, // All the widgets we defined above
//       ),
//     );
//   }
// }

// /// FullTipView - A full-screen view for displaying complete tip content
// /// This shows the entire tip with markdown formatting, actions, and metadata
// class FullTipView extends StatelessWidget {
//   // Properties for the full tip display
//   final String topic; // The tip's main subject/title
//   final String text; // Complete tip content in markdown format
//   final String date; // Creation date as formatted string
//   final List<String>? references; // Optional reference sources
//   final bool isFavorite; // Current favorite status
//   final VoidCallback onFavorite; // Function to toggle favorite status
//   final Future<void> Function()? onDelete; // Optional delete function
//   final VoidCallback onCopy; // Function to copy tip content

//   /// Constructor for FullTipView
//   const FullTipView({
//     required this.topic,
//     required this.text,
//     required this.date,
//     this.references,
//     required this.isFavorite,
//     required this.onFavorite,
//     this.onDelete,
//     required this.onCopy,
//   });

//   /// Private method to clean up tip text for better display
//   /// Removes redundant title sections that are already shown in the navigation bar
//   String _cleanTipTextForDisplay(String tipText) {
//     // Split the text into individual lines for processing
//     final lines = tipText.split('\n');
//     final cleanedLines = <String>[]; // List to store cleaned lines
//     bool skipNext =
//         false; // Flag to skip the next line after finding "## Tip Title"

//     // Process each line of the tip text
//     for (int i = 0; i < lines.length; i++) {
//       final line = lines[i].trim(); // Remove leading/trailing whitespace

//       // Look for the "## Tip Title" markdown header
//       if (line == '## Tip Title') {
//         skipNext = true; // Mark that we should skip the next non-empty line
//         continue; // Don't include this line in output
//       }

//       // If we're in skip mode and find a non-empty line that's not a header
//       if (skipNext && line.isNotEmpty && !line.startsWith('#')) {
//         skipNext = false; // Turn off skip mode
//         continue; // Don't include this line (it's the redundant title)
//       }

//       // Add the line to our cleaned output
//       cleanedLines.add(lines[i]); // Keep original line with formatting
//     }

//     return cleanedLines.join('\n'); // Rejoin all lines back into text
//   }

//   /// Private method to show error dialog when a link cannot be opened
//   /// Provides user-friendly error handling with option to copy link
//   void _showLinkErrorDialog(BuildContext context, String href) {
//     showCupertinoDialog(
//       context: context,
//       builder: (context) => CupertinoAlertDialog(
//         title: const Text('Unable to Open Link'),
//         content: Text(
//             'Could not open: $href\n\nWould you like to copy the link to your clipboard?'),
//         actions: [
//           // First option: Copy the link to clipboard
//           CupertinoDialogAction(
//             child: const Text('Copy Link'),
//             onPressed: () {
//               // Copy the problematic link to clipboard
//               Clipboard.setData(ClipboardData(text: href));
//               Navigator.of(context).pop(); // Close error dialog

//               // Show confirmation that link was copied
//               showCupertinoDialog(
//                 context: context,
//                 builder: (context) => CupertinoAlertDialog(
//                   content: const Text('Link copied to clipboard!'),
//                   actions: [
//                     CupertinoDialogAction(
//                       child: const Text('OK'),
//                       onPressed: () => Navigator.of(context).pop(),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           // Second option: Just cancel and close dialog
//           CupertinoDialogAction(
//             child: const Text('Cancel'),
//             onPressed: () => Navigator.of(context).pop(),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Build method for FullTipView - creates the complete tip display screen
//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       // Enhanced navigation bar with improved styling
//       navigationBar: CupertinoNavigationBar(
//         backgroundColor: CupertinoColors.systemBackground.resolveFrom(context).withOpacity(0.9),
//         border: Border(
//           bottom: BorderSide(
//             color: CupertinoColors.systemGrey4.resolveFrom(context),
//             width: 0.5,
//           ),
//         ),
//         // Use ScrollingTitle for long titles that exceed appbar width
//         middle: ScrollingTitle(
//           text: topic,
//           scrollSpeed: 50.0, // Smooth scroll speed for readability
//           pauseWhenFits: true, // Only scroll if title is too long to fit
//           style: const TextStyle(
//             fontWeight: FontWeight.w600,
//             fontSize: 17,
//           ),
//         ),
//         // Enhanced action buttons with better visual hierarchy
//         trailing: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Copy button with enhanced visual feedback
//             CupertinoButton(
//               padding: EdgeInsets.zero,
//               child: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: CupertinoColors.systemBlue.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: CupertinoColors.systemBlue.withOpacity(0.2),
//                     width: 1,
//                   ),
//                 ),
//                 child: const Icon(
//                   CupertinoIcons.doc_on_clipboard,
//                   size: 20,
//                   color: CupertinoColors.systemBlue,
//                 ),
//               ),
//               onPressed: () {
//                 HapticFeedback.lightImpact(); // Tactile feedback
//                 onCopy(); // Execute copy function
                
//                 // Show enhanced copy confirmation
//                 showCupertinoDialog(
//                   context: context,
//                   builder: (context) => CupertinoAlertDialog(
//                     content: Row(
//                       mainAxisSize: MainAxisSize.min,
//                       children: const [
//                         Icon(CupertinoIcons.checkmark_circle_fill, 
//                              color: CupertinoColors.systemGreen, size: 20),
//                         SizedBox(width: 8),
//                         Text('Tip copied to clipboard!'),
//                       ],
//                     ),
//                     actions: [
//                       CupertinoDialogAction(
//                         child: const Text('OK'),
//                         onPressed: () => Navigator.of(context).pop(),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),

//             const SizedBox(width: 8),

//             // Enhanced favorite button with smooth animations
//             CupertinoButton(
//               padding: EdgeInsets.zero,
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 curve: Curves.easeInOut,
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: isFavorite
//                       ? CupertinoColors.systemRed.withOpacity(0.15)
//                       : CupertinoColors.systemGrey6.withOpacity(0.5),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: isFavorite 
//                         ? CupertinoColors.systemRed.withOpacity(0.3)
//                         : CupertinoColors.systemGrey4,
//                     width: 1,
//                   ),
//                 ),
//                 child: AnimatedScale(
//                   duration: const Duration(milliseconds: 200),
//                   scale: isFavorite ? 1.1 : 1.0,
//                   child: Icon(
//                     isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
//                     color: isFavorite ? CupertinoColors.systemRed : CupertinoColors.systemGrey,
//                     size: 20,
//                   ),
//                 ),
//               ),
//               onPressed: () {
//                 HapticFeedback.lightImpact();
//                 onFavorite();
//               },
//             ),
//           ],
//         ),
//       ),
//       // Enhanced main content with improved scrolling and padding
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               CupertinoColors.systemBackground.resolveFrom(context),
//               CupertinoColors.systemGroupedBackground.resolveFrom(context).withOpacity(0.3),
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               // Scrollable content area with enhanced styling
//               Expanded(
//                 child: SingleChildScrollView(
//                   physics: const BouncingScrollPhysics(),
//                   padding: const EdgeInsets.all(20.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Enhanced tip metadata banner
//                       Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.all(18),
//                         margin: const EdgeInsets.only(bottom: 24),
//                         decoration: BoxDecoration(
//                           gradient: LinearGradient(
//                             colors: [
//                               CupertinoColors.systemBlue.withOpacity(0.08),
//                               CupertinoColors.systemBlue.withOpacity(0.12),
//                             ],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(16),
//                           border: Border.all(
//                             color: CupertinoColors.systemBlue.withOpacity(0.25),
//                             width: 1,
//                           ),
//                           boxShadow: [
//                             BoxShadow(
//                               color: CupertinoColors.systemBlue.withOpacity(0.1),
//                               blurRadius: 15,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: CupertinoColors.systemBlue.withOpacity(0.15),
//                                 borderRadius: BorderRadius.circular(8),
//                               ),
//                               child: const Icon(
//                                 CupertinoIcons.lightbulb,
//                                 size: 20,
//                                 color: CupertinoColors.systemBlue,
//                               ),
//                             ),
//                             const SizedBox(width: 16),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Learning Tip',
//                                     style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.w600,
//                                       color: CupertinoColors.systemBlue,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Text(
//                                     TipUtils.formatTipMetadata(text),
//                                     style: TextStyle(
//                                       fontSize: 14,
//                                       color: CupertinoColors.secondaryLabel.resolveFrom(context),
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                       // Main markdown content with improved styling
//                       MarkdownBody(
//                       data: _cleanTipTextForDisplay(text),
//                       // Handle link taps with robust error handling
//                       onTapLink: (text, href, title) async {
//                         if (href != null && href.isNotEmpty) {
//                           try {
//                             final url = Uri.parse(href);

//                             // Check if the URL can be launched and launch it
//                             if (await canLaunchUrl(url)) {
//                               await launchUrl(url,
//                                   mode: LaunchMode.externalApplication);
//                             } else {
//                               _showLinkErrorDialog(context, href);
//                             }
//                           } catch (e) {
//                             // If that fails, try without checking canLaunchUrl
//                             try {
//                               final url = Uri.parse(href);
//                               await launchUrl(url);
//                             } catch (e2) {
//                               _showLinkErrorDialog(context, href);
//                             }
//                           }
//                         }
//                       },
//                       // Enhanced markdown styling for better readability
//                       styleSheet: MarkdownStyleSheet(
//                         // Header styles with proper hierarchy
//                         h1: const TextStyle(
//                           fontSize: 26,
//                           fontWeight: FontWeight.bold,
//                           color: CupertinoColors.label,
//                           height: 1.3,
//                         ),
//                         h2: const TextStyle(
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                           color: CupertinoColors.label,
//                           height: 1.3,
//                         ),
//                         h3: const TextStyle(
//                           fontSize: 19,
//                           fontWeight: FontWeight.w600,
//                           color: CupertinoColors.label,
//                           height: 1.3,
//                         ),

//                         // Body text with comfortable reading settings
//                         p: const TextStyle(
//                           fontSize: 16,
//                           height: 1.6, // Improved line height for readability
//                           color: CupertinoColors.label,
//                           letterSpacing: 0.2,
//                         ),

//                         // List styling
//                         listBullet: const TextStyle(
//                           fontSize: 16,
//                           color: CupertinoColors.activeBlue,
//                           fontWeight: FontWeight.w600,
//                         ),

//                         // Inline code styling (fixed black background issue)
//                         code: TextStyle(
//                           fontFamily: 'SF Mono', // iOS system monospace font
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500,
//                           backgroundColor:
//                               CupertinoColors.systemGrey5.resolveFrom(context),
//                           color: CupertinoColors.systemPurple,
//                         ),

//                         // Code block styling (ENHANCED: Better UX with copy functionality)
//                         codeblockDecoration: BoxDecoration(
//                           // Use adaptive background that works in light/dark mode
//                           color: CupertinoColors.systemGrey6.resolveFrom(context),
//                           borderRadius: BorderRadius.circular(12),
//                           border: Border.all(
//                             color: CupertinoColors.systemGrey4.resolveFrom(context),
//                             width: 1,
//                           ),
//                           // Enhanced shadow for depth
//                           boxShadow: [
//                             BoxShadow(
//                               color: CupertinoColors.systemGrey.withOpacity(0.15),
//                               blurRadius: 10,
//                               offset: const Offset(0, 3),
//                             ),
//                           ],
//                         ),
//                         codeblockPadding: const EdgeInsets.all(20),

//                         // Quote styling
//                         blockquote: const TextStyle(
//                           fontSize: 16,
//                           fontStyle: FontStyle.italic,
//                           color: CupertinoColors.systemGrey,
//                           height: 1.5,
//                         ),
//                         blockquoteDecoration: BoxDecoration(
//                           color: CupertinoColors.systemGrey6.withOpacity(0.5),
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border(
//                             left: BorderSide(
//                               color: CupertinoColors.activeBlue,
//                               width: 4,
//                             ),
//                           ),
//                         ),
//                         blockquotePadding: const EdgeInsets.all(16),

//                         // Link styling
//                         a: const TextStyle(
//                           color: CupertinoColors.activeBlue,
//                           decoration: TextDecoration.underline,
//                           fontWeight: FontWeight.w500,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 32), // Extra space before metadata

//                     // Enhanced metadata section with better visual hierarchy
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         // Subtle gradient background
//                         gradient: LinearGradient(
//                           colors: [
//                             CupertinoColors.systemGroupedBackground
//                                 .resolveFrom(context),
//                             CupertinoColors.systemGrey6
//                                 .resolveFrom(context)
//                                 .withOpacity(0.5),
//                           ],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                         border: Border.all(
//                           color:
//                               CupertinoColors.systemGrey4.resolveFrom(context),
//                           width: 0.5,
//                         ),
//                         // Enhanced shadow
//                         boxShadow: [
//                           BoxShadow(
//                             color: CupertinoColors.systemGrey.withOpacity(0.08),
//                             blurRadius: 12,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Creation date with enhanced styling
//                           Row(
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(6),
//                                 decoration: BoxDecoration(
//                                   color: CupertinoColors.systemGrey5,
//                                   borderRadius: BorderRadius.circular(6),
//                                 ),
//                                 child: const Icon(
//                                   CupertinoIcons.calendar,
//                                   size: 16,
//                                   color: CupertinoColors.systemGrey,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Text(
//                                 'Created: $date',
//                                 style: const TextStyle(
//                                   fontSize: 15,
//                                   color: CupertinoColors.secondaryLabel,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),

//                           // References section (if available)
//                           if (references != null && references!.isNotEmpty) ...[
//                             const SizedBox(height: 16),
//                             Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: CupertinoColors.activeBlue
//                                         .withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(6),
//                                   ),
//                                   child: const Icon(
//                                     CupertinoIcons.tag,
//                                     size: 16,
//                                     color: CupertinoColors.activeBlue,
//                                   ),
//                                 ),
//                                 const SizedBox(width: 12),
//                                 const Text(
//                                   'References:',
//                                   style: TextStyle(
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.w600,
//                                     color: CupertinoColors.label,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                             const SizedBox(height: 12),

//                             // List each reference with improved styling
//                             ...references!.map((ref) => Container(
//                                   margin: const EdgeInsets.only(bottom: 8),
//                                   child: Row(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const SizedBox(
//                                           width: 34), // Align with icon above
//                                       Container(
//                                         width: 4,
//                                         height: 4,
//                                         margin: const EdgeInsets.only(
//                                             top: 8, right: 12),
//                                         decoration: BoxDecoration(
//                                           color: CupertinoColors.activeBlue,
//                                           borderRadius:
//                                               BorderRadius.circular(2),
//                                         ),
//                                       ),
//                                       Expanded(
//                                         child: Text(
//                                           ref,
//                                           style: const TextStyle(
//                                             fontSize: 14,
//                                             color:
//                                                 CupertinoColors.secondaryLabel,
//                                             height: 1.4,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 )),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             // Enhanced bottom delete button section (if delete function provided)
//             if (onDelete != null)
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 // Add subtle top border to separate from content
//                 decoration: BoxDecoration(
//                   color: CupertinoColors.systemGroupedBackground
//                       .resolveFrom(context),
//                   border: Border(
//                     top: BorderSide(
//                       color: CupertinoColors.systemGrey4.resolveFrom(context),
//                       width: 0.5,
//                     ),
//                   ),
//                 ),
//                 child: SizedBox(
//                   width: double.infinity,
//                   child: CupertinoButton(
//                     // Enhanced button styling with gradient
//                     color: CupertinoColors.destructiveRed,
//                     borderRadius: BorderRadius.circular(12),
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     onPressed: () {
//                       // Add haptic feedback for delete action
//                       HapticFeedback.mediumImpact();

//                       // Show confirmation dialog with enhanced styling
//                       showCupertinoDialog(
//                         context: context,
//                         builder: (context) => CupertinoAlertDialog(
//                           title: const Text(
//                             'Delete Tip',
//                             style: TextStyle(fontWeight: FontWeight.w600,colo),
//                           ),
//                           content: const Text(
//                             'Are you sure you want to delete this tip? This action cannot be undone.',
//                             style: TextStyle(fontSize: 15),
//                           ),
//                           actions: [
//                             // Cancel button
//                             CupertinoDialogAction(
//                               child: const Text(
//                                 'Cancel',
//                                 style: TextStyle(fontWeight: FontWeight.w500),
//                               ),
//                               onPressed: () => Navigator.of(context).pop(),
//                             ),
//                             // Delete button with destructive styling
//                             CupertinoDialogAction(
//                               isDestructiveAction: true,
//                               child: const Text(
//                                 'Delete',
//                                 style: TextStyle(fontWeight: FontWeight.w600),
//                               ),
//                               onPressed: () async {
//                                 // Add haptic feedback for destructive action
//                                 HapticFeedback.heavyImpact();
//                                 Navigator.of(context).pop(); // Close dialog
//                                 Navigator.of(context).pop(); // Close tip view
//                                 await onDelete!(); // Execute delete function
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: const [
//                         Icon(
//                           CupertinoIcons.delete,
//                           size: 18,
//                           color: CupertinoColors.white,
//                         ),
//                         SizedBox(width: 8),
//                         Text(
//                           'Delete Tip',
//                           style: TextStyle(
//                             fontWeight: FontWeight.w600,
//                             fontSize: 16,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
