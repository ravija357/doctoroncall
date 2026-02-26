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
  StreamSubscription? _notificationSyncSubscription;

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
    on<MarkAsReadRequested>(_onMarkAsReadRequested);
    on<ResetActiveChatUserId>(_onResetActiveChatUserId);
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

    _notificationSyncSubscription?.cancel();
    _notificationSyncSubscription = chatRepository.notificationSyncStream().listen((data) {
      print('[SOCKET] Chat/Notification Sync Received: $data');
      // Always treat sync ping as a background action
      add(const LoadContactsRequested(isBackground: true));
    });
  }

  void _onDisconnectSocketRequested(DisconnectSocketRequested event, Emitter<ChatState> emit) {
    _messageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _chatClearedSubscription?.cancel();
    _notificationSyncSubscription?.cancel();
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
        emit(MessagesLoaded(
          messages: updatedMessages,
          activeChatUserId: currentState.activeChatUserId,
        ));
      }
    } else if (state is ContactsLoaded) {
      add(const LoadContactsRequested(isBackground: true));
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
      emit(MessagesLoaded(
        messages: updated,
        activeChatUserId: currentState.activeChatUserId,
      ));
    }
  }

  void _onClearChatRequested(ClearChatRequested event, Emitter<ChatState> emit) {
    chatRepository.clearChat(receiverId: event.receiverId, forEveryone: event.forEveryone);
    add(ChatCleared());
  }

  void _onChatCleared(ChatCleared event, Emitter<ChatState> emit) {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      emit(MessagesLoaded(
        messages: const [],
        activeChatUserId: currentState.activeChatUserId,
      ));
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
    // Avoid showing a loading spinner if we already have data or if it's a background refresh
    if (!event.isBackground && state is! ContactsLoaded && state is! MessagesLoaded) {
      emit(ChatLoading());
    }
    try {
      final contacts = await chatRepository.getContacts();
      
      // If it's a background refresh, only emit if we're not in an active chat
      if (event.isBackground && state is MessagesLoaded) {
        print('[CHAT] Skipping background ContactsLoaded emission because user is in a chat.');
        return;
      }
      
      emit(ContactsLoaded(contacts: contacts));
    } on ServerException catch (e) {
      emit(ChatError(message: e.message));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onLoadMessagesRequested(
      LoadMessagesRequested event, Emitter<ChatState> emit) async {
    try {
      final messages = await chatRepository.getMessages(event.userId);
      emit(MessagesLoaded(
        messages: messages,
        activeChatUserId: event.userId,
      ));
    } on ServerException catch (e) {
      emit(ChatError(message: e.message));
    } catch (e) {
      emit(ChatError(message: e.toString()));
    }
  }

  Future<void> _onMarkAsReadRequested(
      MarkAsReadRequested event, Emitter<ChatState> emit) async {
    try {
      await chatRepository.markAsRead(event.userId);
      // After marking as read, refresh contacts in background
      add(const LoadContactsRequested(isBackground: true));
    } on ServerException catch (e) {
      // Non-critical if mark as read fails, but we can log or emit error
      print('[CHAT] Mark as read failed: ${e.message}');
    } catch (e) {
      print('[CHAT] Mark as read error: $e');
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _chatClearedSubscription?.cancel();
    _notificationSyncSubscription?.cancel();
    chatRepository.disconnectSocket();
    return super.close();
  }

  void _onResetActiveChatUserId(ResetActiveChatUserId event, Emitter<ChatState> emit) {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      emit(MessagesLoaded(
        messages: currentState.messages,
        activeChatUserId: null,
      ));
    }
  }
}
