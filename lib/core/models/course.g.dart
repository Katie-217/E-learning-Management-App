// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseAdapter extends TypeAdapter<Course> {
  @override
  final int typeId = 0;

  @override
  Course read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Course(
      id: fields[0] as String,
      name: fields[1] as String,
      code: fields[2] as String,
      instructor: fields[3] as String,
      description: fields[4] as String,
      credits: fields[5] as int,
      semester: fields[6] as String,
      status: fields[7] as CourseStatus,
      imageUrl: fields[8] as String,
      progress: fields[9] as double,
      totalStudents: fields[10] as int,
      startDate: fields[11] as DateTime,
      endDate: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Course obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.code)
      ..writeByte(3)
      ..write(obj.instructor)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.credits)
      ..writeByte(6)
      ..write(obj.semester)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.imageUrl)
      ..writeByte(9)
      ..write(obj.progress)
      ..writeByte(10)
      ..write(obj.totalStudents)
      ..writeByte(11)
      ..write(obj.startDate)
      ..writeByte(12)
      ..write(obj.endDate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CourseStatusAdapter extends TypeAdapter<CourseStatus> {
  @override
  final int typeId = 1;

  @override
  CourseStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CourseStatus.active;
      case 1:
        return CourseStatus.completed;
      case 2:
        return CourseStatus.paused;
      case 3:
        return CourseStatus.archived;
      default:
        return CourseStatus.active;
    }
  }

  @override
  void write(BinaryWriter writer, CourseStatus obj) {
    switch (obj) {
      case CourseStatus.active:
        writer.writeByte(0);
        break;
      case CourseStatus.completed:
        writer.writeByte(1);
        break;
      case CourseStatus.paused:
        writer.writeByte(2);
        break;
      case CourseStatus.archived:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
