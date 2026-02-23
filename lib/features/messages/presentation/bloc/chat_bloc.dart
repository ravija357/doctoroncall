import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _messageDeletedSubscription;
  StreamSubscription? _chatClearedSubscription;

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    on<LoadContactsRequested>(_onLoadContactsRequested);
    on<LoadMessagesRequested>(_onLoadMessagesRequested);
    on<ConnectSocketRequested>(_onConnectSocketRequested);
    on<DisconnectSocketRequested>(_onDisconnectSocketRequested);
    on<SendMessageRequested>(_onSendMessageRequested);
    on<MessageReceived>(_onMessageReceived);
    on<DeleteMessageRequested>(_onDeleteMessageRequested);
    on<MessageDeleted>(_onMessageDeleted);
    on<ClearChatRequested>(_onClearChatRequested);
    on<ChatCleared>(_onChatCleared);
    on<SendFileRequested>(_onSendFileRequested);
  }

  void _onConnectSocketRequested(ConnectSocketRequested event, Emitter<ChatState> emit) {
    chatRepository.connectSocket();
    _messageSubscription?.cancel();
    _messageSubscription = chatRepository.receiveMessages().listen((message) {
      add(MessageReceived(message: message));
    });

    _messageDeletedSubscription?.cancel();
    _messageDeletedSubscription = chatRepository.messageDeletedStream().listen((messageId) {
      add(MessageDeleted(messageId: messageId));
    });

    _chatClearedSubscription?.cancel();
    _chatClearedSubscription = chatRepository.chatClearedStream().listen((_) {
      add(ChatCleared());
    });
  }

  void _onDisconnectSocketRequested(DisconnectSocketRequested event, Emitter<ChatState> emit) {
    _messageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _chatClearedSubscription?.cancel();
    chatRepository.disconnectSocket();
  }

  Future<void> _onSendMessageRequested(SendMessageRequested event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.sendMessage(event.message);
    } on ServerException catch (e) {
      emit(ChatError(message: e.message));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      final messageExists = currentState.messages.any((m) => m.id == event.message.id);
      if (!messageExists) {
        final updatedMessages = List<Message>.from(currentState.messages)..add(event.message);
        emit(MessagesLoaded(messages: updatedMessages));
      }
    } else if (state is ContactsLoaded) {
      add(LoadContactsRequested());
    }
  }

  void _onDeleteMessageRequested(DeleteMessageRequested event, Emitter<ChatState> emit) {
    chatRepository.deleteMessage(
      messageId: event.messageId,
      receiverId: event.receiverId,
      forEveryone: event.forEveryone,
    );
    // Optimistically remove from local state
    add(MessageDeleted(messageId: event.messageId));
  }

  void _onMessageDeleted(MessageDeleted event, Emitter<ChatState> emit) {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      final updated = currentState.messages.where((m) => m.id != event.messageId).toList();
      emit(MessagesLoaded(messages: updated));
    }
  }

  void _onClearChatRequested(ClearChatRequested event, Emitter<ChatState> emit) {
    chatRepository.clearChat(receiverId: event.receiverId, forEveryone: event.forEveryone);
    add(ChatCleared());
  }

  void _onChatCleared(ChatCleared event, Emitter<ChatState> emit) {
    if (state is MessagesLoaded) {
      emit(const MessagesLoaded(messages: []));
    }
  }

  Future<void> _onSendFileRequested(SendFileRequested event, Emitter<ChatState> emit) async {
    final previousMessages = state is MessagesLoaded
        ? (state as MessagesLoaded).messages
        : <Message>[];
    try {
      emit(FileUploading());
      await chatRepository.uploadFile(
        filePath: event.filePath,
        receiverId: event.receiverId,
        type: event.type,
      );
      // Restore the list — the 'message_sent' socket event will add the confirmed message
      emit(MessagesLoaded(messages: previousMessages));
    } on ServerException catch (e) {
      emit(ChatError(message: e.message));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onLoadContactsRequested(
      LoadContactsRequested event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final contacts = await chatRepository.getContacts();
      emit(ContactsLoaded(contacts: contacts));
    } on ServerException catch (e) {
      emit(ChatError(message: e.message));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onLoadMessagesRequested(
      LoadMessagesRequested event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    try {
      final messages = await chatRepository.getMessages(event.userId);
      emit(MessagesLoaded(messages: messages));
    } on ServerException catch (e) {
      emit(ChatError(message: e.message));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _chatClearedSubscription?.cancel();
    chatRepository.disconnectSocket();
    return super.close();
  }
}
