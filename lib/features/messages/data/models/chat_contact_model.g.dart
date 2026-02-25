// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_contact_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChatContactAdapter extends TypeAdapter<ChatContact> {
  @override
  final int typeId = 4;

  @override
  ChatContact read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatContact(
      id: fields[0] as String,
      name: fields[1] as String,
      image: fields[2] as String?,
      role: fields[3] as String,
      email: fields[4] as String,
      lastMessage: fields[5] as String?,
      lastMessageTime: fields[6] as DateTime?,
      unread: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ChatContact obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.image)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.lastMessage)
      ..writeByte(6)
      ..write(obj.lastMessageTime)
      ..writeByte(7)
      ..write(obj.unread);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatContactAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
