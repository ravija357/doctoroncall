import 'package:equatable/equatable.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

class LoadContactsRequested extends ChatEvent {}

class LoadMessagesRequested extends ChatEvent {
  final String userId;

  const LoadMessagesRequested({required this.userId});

  @override
  List<Object> get props => [userId];
}

class SendMessageRequested extends ChatEvent {
  final Message message;

  const SendMessageRequested({required this.message});

  @override
  List<Object> get props => [message];
}

class ConnectSocketRequested extends ChatEvent {}

class DisconnectSocketRequested extends ChatEvent {}

class MessageReceived extends ChatEvent {
  final Message message;

  const MessageReceived({required this.message});

  @override
  List<Object> get props => [message];
}

/// Delete a specific message (forEveryone = false means "for me only")
class DeleteMessageRequested extends ChatEvent {
  final String messageId;
  final String receiverId;
  final bool forEveryone;

  const DeleteMessageRequested({
    required this.messageId,
    required this.receiverId,
    required this.forEveryone,
  });

  @override
  List<Object> get props => [messageId, receiverId, forEveryone];
}

/// Fired when the socket reports a message was deleted
class MessageDeleted extends ChatEvent {
  final String messageId;

  const MessageDeleted({required this.messageId});

  @override
  List<Object> get props => [messageId];
}

/// Clear all chat history with a user
class ClearChatRequested extends ChatEvent {
  final String receiverId;
  final bool forEveryone;

  const ClearChatRequested({required this.receiverId, required this.forEveryone});

  @override
  List<Object> get props => [receiverId, forEveryone];
}

/// Fired when the socket reports chat was cleared
class ChatCleared extends ChatEvent {}

/// Upload an image or file and send it as a message
class SendFileRequested extends ChatEvent {
  final String filePath;
  final String receiverId;
  final String type; // 'image' | 'file'

  const SendFileRequested({
    required this.filePath,
    required this.receiverId,
    required this.type,
  });

  @override
  List<Object> get props => [filePath, receiverId, type];
}
