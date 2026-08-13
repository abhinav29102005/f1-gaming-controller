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
      playerId: fields[11] as int? ?? 0,
      swapPaddleShifters: fields[12] as bool? ?? false,
      invertGyro: fields[13] as bool? ?? false,
      gyroDeadzone: fields[14] as double? ?? 0.02,
      // Field 15 added for layoutMode — defaults to 'f1_racing' for old saved profiles
      layoutMode: fields[15] as String? ?? 'f1_racing',
    );
  }

  @override
  void write(BinaryWriter writer, ControllerProfile obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.playerId)
      ..writeByte(12)
      ..write(obj.swapPaddleShifters)
      ..writeByte(13)
      ..write(obj.invertGyro)
      ..writeByte(14)
      ..write(obj.gyroDeadzone)
      ..writeByte(15)
      ..write(obj.layoutMode);
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
