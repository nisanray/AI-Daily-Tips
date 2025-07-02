/// Gemini model configuration for API calls
class GeminiModel {
  final String id;
  final String displayName;
  final String description;
  final bool isRecommended;
  final int maxTokens;
  final double costPerToken; // Relative cost indicator

  const GeminiModel({
    required this.id,
    required this.displayName,
    required this.description,
    this.isRecommended = false,
    this.maxTokens = 8192,
    this.costPerToken = 1.0,
  });

  /// Available Gemini models
  static const List<GeminiModel> availableModels = [
    GeminiModel(
      id: 'gemini-2.0-flash-exp',
      displayName: 'Gemini 2.0 Flash (Experimental)',
      description: 'Latest experimental model with enhanced performance',
      isRecommended: true,
      maxTokens: 8192,
      costPerToken: 1.0,
    ),
    GeminiModel(
      id: 'gemini-1.5-flash',
      displayName: 'Gemini 1.5 Flash',
      description: 'Fast and efficient model for quick responses',
      maxTokens: 8192,
      costPerToken: 0.5,
    ),
    GeminiModel(
      id: 'gemini-1.5-flash-8b',
      displayName: 'Gemini 1.5 Flash 8B',
      description: 'Lightweight version optimized for speed',
      maxTokens: 8192,
      costPerToken: 0.3,
    ),
    GeminiModel(
      id: 'gemini-1.5-pro',
      displayName: 'Gemini 1.5 Pro',
      description: 'Advanced model with superior reasoning capabilities',
      maxTokens: 32768,
      costPerToken: 2.0,
    ),
    GeminiModel(
      id: 'gemini-2.0-flash',
      displayName: 'Gemini 2.0 Flash',
      description: 'Stable version of the latest generation model',
      maxTokens: 8192,
      costPerToken: 1.0,
    ),
  ];

  /// Get model by ID
  static GeminiModel? getModelById(String id) {
    try {
      return availableModels.firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get recommended model
  static GeminiModel get recommendedModel {
    return availableModels.firstWhere(
      (model) => model.isRecommended,
      orElse: () => availableModels.first,
    );
  }

  /// Get default model (for backward compatibility)
  static GeminiModel get defaultModel {
    return getModelById('gemini-2.0-flash') ?? recommendedModel;
  }

  /// Generate API URL for this model
  String generateApiUrl(String apiKey) {
    return 'https://generativelanguage.googleapis.com/v1beta/models/$id:generateContent?key=$apiKey';
  }

  /// Get display info with cost indicator
  String get displayInfo {
    final costIndicator = costPerToken <= 0.5
        ? '💚 Low cost'
        : costPerToken <= 1.0
            ? '💛 Standard'
            : '🔶 Premium';
    return '$displayName • $costIndicator';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GeminiModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => displayName;
}
