import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<List<ChatContact>> getContacts() async {
    try {
      final contacts = await remoteDataSource.getContacts();
      // Cache on success
      await localDataSource.cacheContacts(contacts);
      return contacts;
    } catch (e) {
      // Fallback to cache
      final cached = localDataSource.getCachedContacts();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  @override
  Future<List<Message>> getMessages(String userId) => remoteDataSource.getMessages(userId);

  @override
  Future<void> sendMessage(Message message) async {
    remoteDataSource.emitSendMessage(message.receiverId, message.content);
  }

  @override
  Stream<Message> receiveMessages() => remoteDataSource.messageStream;

  @override
  Stream<String> messageDeletedStream() => remoteDataSource.messageDeletedStream;

  @override
  Stream<void> chatClearedStream() => remoteDataSource.chatClearedStream;

  @override
  void connectSocket() => remoteDataSource.connectSocket();

  @override
  void disconnectSocket() => remoteDataSource.disconnectSocket();

  @override
  bool get isSocketConnected => remoteDataSource.isConnected;

  @override
  void deleteMessage({required String messageId, required String receiverId, required bool forEveryone}) {
    remoteDataSource.emitDeleteMessage(messageId: messageId, receiverId: receiverId, forEveryone: forEveryone);
  }

  @override
  void clearChat({required String receiverId, required bool forEveryone}) {
    remoteDataSource.emitClearChat(receiverId: receiverId, forEveryone: forEveryone);
  }

  @override
  Future<Message> uploadFile({required String filePath, required String receiverId, required String type}) {
    return remoteDataSource.uploadFile(filePath: filePath, receiverId: receiverId, type: type);
  }
}
