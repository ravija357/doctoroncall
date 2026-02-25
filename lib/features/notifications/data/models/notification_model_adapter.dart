import 'package:hive/hive.dart';
import 'notification_model.dart';

/// Manually-written Hive TypeAdapter for NotificationModel.
/// The standard hive_generator cannot handle models with hive*-prefixed
/// fields that differ from the constructor parameter names.
class NotificationModelAdapter extends TypeAdapter<NotificationModel> {
  @override
  final int typeId = 3;

  @override
  NotificationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotificationModel(
      id: fields[0] as String,
      message: fields[1] as String,
      type: fields[2] as String,
      relatedId: fields[3] as String?,
      link: fields[4] as String?,
      isRead: fields[5] as bool,
      createdAt: DateTime.parse(fields[6] as String),
    );
  }

  @override
  void write(BinaryWriter writer, NotificationModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.message)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.relatedId)
      ..writeByte(4)
      ..write(obj.link)
      ..writeByte(5)
      ..write(obj.isRead)
      ..writeByte(6)
      ..write(obj.createdAt.toIso8601String());
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
