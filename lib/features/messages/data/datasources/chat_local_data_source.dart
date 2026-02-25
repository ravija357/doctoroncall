import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';

class ChatLocalDataSource {
  Box get _box => Hive.box(HiveBoxes.chatContacts);

  /// Get cached contacts
  List<ChatContact> getCachedContacts() {
    final raw = _box.get('contacts_list');
    if (raw == null) return [];
    final List<dynamic> list = raw;
    return list
        .map((e) => ChatContact.fromHiveMap(Map<dynamic, dynamic>.from(e)))
        .toList();
  }

  /// Cache contacts list
  Future<void> cacheContacts(List<ChatContact> contacts) async {
    await _box.put(
      'contacts_list',
      contacts.map((c) => c.toHiveMap()).toList(),
    );
  }

  /// Clear all cached contacts
  Future<void> clearCache() async {
    await _box.clear();
  }
}
