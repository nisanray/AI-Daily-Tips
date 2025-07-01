// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TopicEntryAdapter extends TypeAdapter<TopicEntry> {
  @override
  final int typeId = 2;

  @override
  TopicEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TopicEntry(
      topic: fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TopicEntry obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.topic);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopicEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
