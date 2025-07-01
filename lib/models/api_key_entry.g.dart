// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApiKeyEntryAdapter extends TypeAdapter<ApiKeyEntry> {
  @override
  final int typeId = 1;

  @override
  ApiKeyEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApiKeyEntry(
      key: fields[0] as String,
      addedAt: fields[1] as DateTime?,
      nickname: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ApiKeyEntry obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.addedAt)
      ..writeByte(2)
      ..write(obj.nickname);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiKeyEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
