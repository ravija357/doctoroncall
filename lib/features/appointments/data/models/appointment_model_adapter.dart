import 'package:hive/hive.dart';
import 'appointment_model.dart';

/// Manually-written Hive TypeAdapter for AppointmentModel.
/// Standalone file — build_runner will not overwrite this.
class AppointmentModelAdapter extends TypeAdapter<AppointmentModel> {
  @override
  final int typeId = 1;

  @override
  AppointmentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppointmentModel(
      id: fields[0] as String?,
      doctorId: fields[1] as String? ?? '',
      patientId: fields[2] as String? ?? '',
      dateTime: DateTime.tryParse(fields[3] as String? ?? '') ?? DateTime.now(),
      status: fields[4] as String? ?? 'pending',
      notes: fields[5] as String?,
      startTime: fields[6] as String? ?? '',
      endTime: fields[7] as String? ?? '',
      reason: fields[8] as String?,
      doctorName: fields[9] as String?,
      specialization: fields[10] as String?,
      hospital: fields[11] as String?,
      doctorImage: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AppointmentModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.doctorId)
      ..writeByte(2)
      ..write(obj.patientId)
      ..writeByte(3)
      ..write(obj.dateTime.toIso8601String())
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.notes)
      ..writeByte(6)
      ..write(obj.startTime)
      ..writeByte(7)
      ..write(obj.endTime)
      ..writeByte(8)
      ..write(obj.reason)
      ..writeByte(9)
      ..write(obj.doctorName)
      ..writeByte(10)
      ..write(obj.specialization)
      ..writeByte(11)
      ..write(obj.hospital)
      ..writeByte(12)
      ..write(obj.doctorImage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppointmentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
