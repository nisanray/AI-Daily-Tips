// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tip_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TipEntryAdapter extends TypeAdapter<TipEntry> {
  @override
  final int typeId = 3;

  @override
  TipEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TipEntry(
      tip: fields[0] as String,
      createdAt: fields[1] as DateTime?,
      references: (fields[2] as List?)?.cast<String>(),
      isFavorite: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, TipEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.tip)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.references)
      ..writeByte(3)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
