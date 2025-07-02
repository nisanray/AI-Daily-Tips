import 'package:hive/hive.dart';
import 'gemini_model.dart';

part 'api_key_entry.g.dart';

/// Represents a Gemini API key entry in Hive.
///
/// ```yaml
/// typeId: 1
/// fields:
///   - key: String
///   - addedAt: DateTime
///   - nickname: String?
///   - modelId: String
/// ```
@HiveType(typeId: 1)
class ApiKeyEntry extends HiveObject {
  @HiveField(0)
  String key;

  @HiveField(1)
  DateTime addedAt;

  @HiveField(2)
  String? nickname;

  @HiveField(3)
  String modelId;

  ApiKeyEntry({
    required this.key, 
    DateTime? addedAt, 
    this.nickname,
    String? modelId,
  }) : addedAt = addedAt ?? DateTime.now(),
       modelId = modelId ?? GeminiModel.defaultModel.id;

  @override
  String toString() =>
      'ApiKeyEntry(key: $key, nickname: $nickname, addedAt: $addedAt, modelId: $modelId)';
      
  /// Get the associated Gemini model
  GeminiModel get model => GeminiModel.getModelById(modelId) ?? GeminiModel.defaultModel;
}
