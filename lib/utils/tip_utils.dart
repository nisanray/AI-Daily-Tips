/// Utility functions for enhancing the tip reading experience
class TipUtils {
  /// Calculates estimated reading time for a tip
  /// Average reading speed: 200-250 words per minute
  /// Returns reading time in minutes
  static int calculateReadingTime(String text) {
    // Remove markdown formatting for accurate word count
    String cleanText = text
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Remove headers
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1') // Remove bold
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1') // Remove italic
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1') // Remove inline code
        .replaceAll(RegExp(r'```[\s\S]*?```'), '') // Remove code blocks
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1'); // Remove links

    List<String> words = cleanText
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().isNotEmpty)
        .toList();

    int wordCount = words.length;
    int readingTimeMinutes =
        (wordCount / 225).ceil(); // 225 words per minute average

    return readingTimeMinutes < 1 ? 1 : readingTimeMinutes;
  }

  /// Extracts programming language from code blocks
  static List<String> extractProgrammingLanguages(String text) {
    RegExp codeBlockRegex = RegExp(r'```(\w+)');
    Iterable<RegExpMatch> matches = codeBlockRegex.allMatches(text);

    return matches
        .map((match) => match.group(1)!)
        .where((lang) => lang.isNotEmpty)
        .toSet() // Remove duplicates
        .toList();
  }

  /// Counts the number of code blocks in the tip
  static int countCodeBlocks(String text) {
    return RegExp(r'```[\s\S]*?```').allMatches(text).length;
  }

  /// Determines the difficulty level based on content analysis
  static String getDifficultyLevel(String text) {
    int codeBlocks = countCodeBlocks(text);
    List<String> advancedKeywords = [
      'advanced',
      'complex',
      'architecture',
      'design pattern',
      'performance',
      'optimization',
      'scalability',
      'microservices',
      'algorithm',
      'data structure',
      'concurrent',
      'async',
      'threading'
    ];

    int advancedKeywordCount = 0;
    String lowerText = text.toLowerCase();
    for (String keyword in advancedKeywords) {
      if (lowerText.contains(keyword)) {
        advancedKeywordCount++;
      }
    }

    if (codeBlocks >= 3 || advancedKeywordCount >= 5) {
      return 'Advanced';
    } else if (codeBlocks >= 1 || advancedKeywordCount >= 2) {
      return 'Intermediate';
    } else {
      return 'Beginner';
    }
  }

  /// Formats the tip metadata for display
  static String formatTipMetadata(String text) {
    int readingTime = calculateReadingTime(text);
    String difficulty = getDifficultyLevel(text);
    List<String> languages = extractProgrammingLanguages(text);

    List<String> metadata = [];
    metadata.add('$readingTime min read');
    metadata.add(difficulty);

    if (languages.isNotEmpty) {
      metadata.add(languages.take(2).join(', ')); // Show up to 2 languages
    }

    return metadata.join(' • ');
  }
}
