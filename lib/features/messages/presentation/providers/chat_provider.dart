import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';
import 'package:doctoroncall/core/di/injection_container.dart' as di;
import 'package:doctoroncall/features/messages/presentation/bloc/chat_state.dart';

part 'chat_provider.g.dart';

@riverpod
class ChatNotifier extends _$ChatNotifier {
  late final ChatRepository _chatRepository;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _messageDeletedSubscription;
  StreamSubscription? _chatClearedSubscription;
  StreamSubscription? _notificationSyncSubscription;

  @override
  ChatState build() {
    _chatRepository = di.sl<ChatRepository>();

    ref.onDispose(() {
      _cancelSubscriptions();
    });

    return ChatInitial();
  }

  void connectSocket() {
    _chatRepository.connectSocket();
    _cancelSubscriptions();

    _messageSubscription = _chatRepository.receiveMessages().listen((message) {
      _handleMessageReceived(message);
    });

    _messageDeletedSubscription = _chatRepository.messageDeletedStream().listen(
      (messageId) {
        _handleMessageDeleted(messageId);
      },
    );

    _chatClearedSubscription = _chatRepository.chatClearedStream().listen((_) {
      _handleChatCleared();
    });

    _notificationSyncSubscription = _chatRepository
        .notificationSyncStream()
        .listen((data) {
          print('[SOCKET] Chat/Notification Sync Received: $data');
          loadContacts(isBackground: true);
        });
  }

  void disconnectSocket() {
    _cancelSubscriptions();
    _chatRepository.disconnectSocket();
  }

  void _cancelSubscriptions() {
    _messageSubscription?.cancel();
    _messageDeletedSubscription?.cancel();
    _chatClearedSubscription?.cancel();
    _notificationSyncSubscription?.cancel();
  }

  Future<void> loadContacts({bool isBackground = false}) async {
    if (!isBackground && state is! ContactsLoaded && state is! MessagesLoaded) {
      state = ChatLoading();
    }
    try {
      final contacts = await _chatRepository.getContacts();
      if (isBackground && state is MessagesLoaded) {
        return;
      }
      state = ContactsLoaded(contacts: contacts);
    } catch (e) {
      state = ChatError(message: e.toString());
    }
  }

  Future<void> loadMessages(String userId) async {
    try {
      final messages = await _chatRepository.getMessages(userId);
      state = MessagesLoaded(messages: messages, activeChatUserId: userId);
    } catch (e) {
      state = ChatError(message: e.toString());
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      await _chatRepository.sendMessage(message);
    } catch (e) {
      state = ChatError(message: e.toString());
    }
  }

  void _handleMessageReceived(Message message) {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      final messageExists = currentState.messages.any(
        (m) => m.id == message.id,
      );
      if (!messageExists) {
        final updatedMessages = List<Message>.from(currentState.messages)
          ..add(message);
        state = MessagesLoaded(
          messages: updatedMessages,
          activeChatUserId: currentState.activeChatUserId,
        );
      }
    } else {
      loadContacts(isBackground: true);
    }
  }

  void _handleMessageDeleted(String messageId) {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      final updated = currentState.messages
          .where((m) => m.id != messageId)
          .toList();
      state = MessagesLoaded(
        messages: updated,
        activeChatUserId: currentState.activeChatUserId,
      );
    }
  }

  void _handleChatCleared() {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      state = MessagesLoaded(
        messages: const [],
        activeChatUserId: currentState.activeChatUserId,
      );
    }
  }

  Future<void> deleteMessage({
    required String messageId,
    required String receiverId,
    required bool forEveryone,
  }) async {
    _chatRepository.deleteMessage(
      messageId: messageId,
      receiverId: receiverId,
      forEveryone: forEveryone,
    );
    _handleMessageDeleted(messageId);
  }

  Future<void> clearChat({
    required String receiverId,
    required bool forEveryone,
  }) async {
    _chatRepository.clearChat(receiverId: receiverId, forEveryone: forEveryone);
    _handleChatCleared();
  }

  Future<void> sendFile({
    required String filePath,
    required String receiverId,
    required String type,
  }) async {
    final previousMessages = state is MessagesLoaded
        ? (state as MessagesLoaded).messages
        : <Message>[];
    try {
      state = FileUploading();
      await _chatRepository.uploadFile(
        filePath: filePath,
        receiverId: receiverId,
        type: type,
      );
      state = MessagesLoaded(messages: previousMessages);
    } catch (e) {
      state = ChatError(message: e.toString());
    }
  }

  Future<void> markAsRead(String userId) async {
    try {
      await _chatRepository.markAsRead(userId);
      loadContacts(isBackground: true);
    } catch (e) {
      print('[CHAT] Mark as read error: $e');
    }
  }

  void resetActiveChatUserId() {
    if (state is MessagesLoaded) {
      final currentState = state as MessagesLoaded;
      state = MessagesLoaded(
        messages: currentState.messages,
        activeChatUserId: null,
      );
    }
  }
}
