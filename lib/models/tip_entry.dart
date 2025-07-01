import 'package:hive/hive.dart';

part 'tip_entry.g.dart';

@HiveType(typeId: 3)
class TipEntry extends HiveObject {
  @HiveField(0)
  String tip;

  @HiveField(1)
  DateTime createdAt;

  @HiveField(2)
  List<String>? references;

  @HiveField(3)
  bool isFavorite;

  TipEntry(
      {required this.tip,
      DateTime? createdAt,
      this.references,
      this.isFavorite = false})
      : createdAt = createdAt ?? DateTime.now();

  @override
  String toString() =>
      'TipEntry(tip: $tip, createdAt: $createdAt, references: $references, isFavorite: $isFavorite)';
}
