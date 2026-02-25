import 'package:hive/hive.dart';
import 'doctor_model.dart';

/// Manually-written Hive TypeAdapter for DoctorModel.
/// The standard hive_generator cannot handle models with hive*-prefixed
/// fields that differ from the constructor parameter names.
class DoctorModelAdapter extends TypeAdapter<DoctorModel> {
  @override
  final int typeId = 2;

  @override
  DoctorModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DoctorModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      firstName: fields[2] as String,
      lastName: fields[3] as String,
      image: fields[4] as String?,
      specialization: fields[5] as String,
      experience: fields[6] as int,
      bio: fields[7] as String,
      fees: fields[8] as double,
      hospital: fields[9] as String?,
      averageRating: fields[10] as double,
      totalReviews: fields[11] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DoctorModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.image)
      ..writeByte(5)
      ..write(obj.specialization)
      ..writeByte(6)
      ..write(obj.experience)
      ..writeByte(7)
      ..write(obj.bio)
      ..writeByte(8)
      ..write(obj.fees)
      ..writeByte(9)
      ..write(obj.hospital)
      ..writeByte(10)
      ..write(obj.averageRating)
      ..writeByte(11)
      ..write(obj.totalReviews);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DoctorModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
