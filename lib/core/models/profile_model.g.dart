// GENERATED CODE - MANUAL HIVE ADAPTER

part of 'profile_model.dart';

class ControllerProfileAdapter extends TypeAdapter<ControllerProfile> {
  @override
  final int typeId = 0;

  @override
  ControllerProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ControllerProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      steeringDeadzone: fields[2] as double,
      throttleDeadzone: fields[3] as double,
      brakeDeadzone: fields[4] as double,
      steeringRotationDegrees: fields[5] as int,
      linearityMode: fields[6] as String,
      gyroSteeringEnabled: fields[7] as bool,
      gyroSensitivity: fields[8] as double,
      hapticFeedbackEnabled: fields[9] as bool,
      hardwareVolumePaddles: fields[10] as bool,
      playerId: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ControllerProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.steeringDeadzone)
      ..writeByte(3)
      ..write(obj.throttleDeadzone)
      ..writeByte(4)
      ..write(obj.brakeDeadzone)
      ..writeByte(5)
      ..write(obj.steeringRotationDegrees)
      ..writeByte(6)
      ..write(obj.linearityMode)
      ..writeByte(7)
      ..write(obj.gyroSteeringEnabled)
      ..writeByte(8)
      ..write(obj.gyroSensitivity)
      ..writeByte(9)
      ..write(obj.hapticFeedbackEnabled)
      ..writeByte(10)
      ..write(obj.hardwareVolumePaddles)
      ..writeByte(11)
      ..write(obj.playerId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ControllerProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
