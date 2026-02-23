import 'package:doctoroncall/features/messages/domain/entities/message.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';

abstract class ChatRepository {
  Future<List<ChatContact>> getContacts();
  Future<List<Message>> getMessages(String userId);
  Future<void> sendMessage(Message message);
  Stream<Message> receiveMessages();
  Stream<String> messageDeletedStream();
  Stream<void> chatClearedStream();
  void connectSocket();
  void disconnectSocket();
  bool get isSocketConnected;

  void deleteMessage({required String messageId, required String receiverId, required bool forEveryone});
  void clearChat({required String receiverId, required bool forEveryone});

  /// Upload a file and return a message object with fileUrl populated
  Future<Message> uploadFile({required String filePath, required String receiverId, required String type});
}
