import 'package:hive/hive.dart';

part 'topic_entry.g.dart';

@HiveType(typeId: 2)
class TopicEntry extends HiveObject {
  @HiveField(0)
  String topic;

  TopicEntry({required this.topic});

  @override
  String toString() => 'TopicEntry(topic: $topic)';
}
