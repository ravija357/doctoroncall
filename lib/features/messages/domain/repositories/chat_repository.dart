import 'package:doctoroncall/features/messages/domain/entities/message.dart';

abstract class ChatRepository {
  Future<List<Message>> getMessageHistory(String userId, String otherUserId);
  Future<void> sendMessage(Message message);
  Stream<Message> receiveMessages();
}
