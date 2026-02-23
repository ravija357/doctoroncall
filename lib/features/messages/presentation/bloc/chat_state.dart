import 'package:equatable/equatable.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ContactsLoaded extends ChatState {
  final List<ChatContact> contacts;

  const ContactsLoaded({required this.contacts});

  @override
  List<Object?> get props => [contacts];
}

class MessagesLoaded extends ChatState {
  final List<Message> messages;

  const MessagesLoaded({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}

class FileUploading extends ChatState {}
