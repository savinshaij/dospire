// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hobby.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HobbyAdapter extends TypeAdapter<Hobby> {
  @override
  final int typeId = 2;

  @override
  Hobby read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Hobby(
      hobbyId: fields[0] as String,
      title: fields[1] as String,
      category: fields[2] as String,
      frequency: fields[3] as HobbyFrequency,
      periodStart: fields[4] as DateTime,
      periodEnd: fields[5] as DateTime,
      selectedWeekdays: (fields[6] as List).cast<int>(),
      colorValue: fields[7] as int?,
      timeHour: fields[8] as int?,
      timeMinute: fields[9] as int?,
      isDone: fields[10] as bool,
      colorIndex: fields[11] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Hobby obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.hobbyId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.frequency)
      ..writeByte(4)
      ..write(obj.periodStart)
      ..writeByte(5)
      ..write(obj.periodEnd)
      ..writeByte(6)
      ..write(obj.selectedWeekdays)
      ..writeByte(7)
      ..write(obj.colorValue)
      ..writeByte(8)
      ..write(obj.timeHour)
      ..writeByte(9)
      ..write(obj.timeMinute)
      ..writeByte(10)
      ..write(obj.isDone)
      ..writeByte(11)
      ..write(obj.colorIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HobbyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class HobbyFrequencyAdapter extends TypeAdapter<HobbyFrequency> {
  @override
  final int typeId = 3;

  @override
  HobbyFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return HobbyFrequency.everyday;
      case 1:
        return HobbyFrequency.someDays;
      default:
        return HobbyFrequency.everyday;
    }
  }

  @override
  void write(BinaryWriter writer, HobbyFrequency obj) {
    switch (obj) {
      case HobbyFrequency.everyday:
        writer.writeByte(0);
        break;
      case HobbyFrequency.someDays:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HobbyFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
