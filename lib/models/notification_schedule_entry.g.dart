// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_schedule_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NotificationScheduleEntryAdapter
    extends TypeAdapter<NotificationScheduleEntry> {
  @override
  final int typeId = 4;

  @override
  NotificationScheduleEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationScheduleEntry(
      hours: (fields[0] as List).cast<int>(),
      minutes: (fields[1] as List).cast<int>(),
      weekdays: (fields[2] as List?)?.cast<int>(),
      intervalDays: fields[3] as int?,
      startDate: fields[4] as DateTime?,
      endDate: fields[5] as DateTime?,
      enabled: fields[6] as bool,
      topic: fields[7] as String?,
      customSound: fields[8] as String?,
      title: fields[9] as String?,
      messageTemplate: fields[10] as String?,
      vibration: fields[11] as bool,
      colorTag: fields[12] as int?,
      paused: fields[13] as bool,
      snoozeUntil: fields[14] as DateTime?,
      repeat: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NotificationScheduleEntry obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.hours)
      ..writeByte(1)
      ..write(obj.minutes)
      ..writeByte(2)
      ..write(obj.weekdays)
      ..writeByte(3)
      ..write(obj.intervalDays)
      ..writeByte(4)
      ..write(obj.startDate)
      ..writeByte(5)
      ..write(obj.endDate)
      ..writeByte(6)
      ..write(obj.enabled)
      ..writeByte(7)
      ..write(obj.topic)
      ..writeByte(8)
      ..write(obj.customSound)
      ..writeByte(9)
      ..write(obj.title)
      ..writeByte(10)
      ..write(obj.messageTemplate)
      ..writeByte(11)
      ..write(obj.vibration)
      ..writeByte(12)
      ..write(obj.colorTag)
      ..writeByte(13)
      ..write(obj.paused)
      ..writeByte(14)
      ..write(obj.snoozeUntil)
      ..writeByte(15)
      ..write(obj.repeat);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationScheduleEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
