import 'package:hive/hive.dart';

part 'api_key_entry.g.dart';

/// Represents a Gemini API key entry in Hive.
///
/// ```yaml
/// typeId: 1
/// fields:
///   - key: String
///   - addedAt: DateTime
/// ```
@HiveType(typeId: 1)
class ApiKeyEntry extends HiveObject {
  @HiveField(0)
  String key;

  @HiveField(1)
  DateTime addedAt;

  @HiveField(2)
  String? nickname;

  ApiKeyEntry({required this.key, DateTime? addedAt, this.nickname})
      : addedAt = addedAt ?? DateTime.now();

  @override
  String toString() =>
      'ApiKeyEntry(key: $key, nickname: $nickname, addedAt: $addedAt)';
}
