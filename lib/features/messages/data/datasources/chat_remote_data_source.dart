import 'dart:async';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:doctoroncall/core/error/server_exception.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';
import 'package:doctoroncall/features/messages/data/models/message_model.dart';
import 'package:doctoroncall/core/constants/api_constants.dart';

abstract class ChatRemoteDataSource {
  Future<List<ChatContact>> getContacts();
  Future<List<MessageModel>> getMessages(String userId);
  Future<void> markAsRead(String senderId);
  void connectSocket();
  void disconnectSocket();
  void emitSendMessage(String receiverId, String content);
  Stream<MessageModel> get messageStream;
  Stream<String> get messageDeletedStream;
  Stream<dynamic> get notificationStream;
  bool get isConnected;

  // Delete & clear
  void emitDeleteMessage({required String messageId, required String receiverId, required bool forEveryone});
  void emitClearChat({required String receiverId, required bool forEveryone});
  Stream<void> get chatClearedStream;
  Stream<dynamic> get appointmentSyncStream;
  Stream<dynamic> get notificationSyncStream;
  Stream<dynamic> get doctorSyncStream;
  Stream<dynamic> get scheduleSyncStream;

  /// Upload a file/image, returns the saved message JSON from the server
  Future<MessageModel> uploadFile({required String filePath, required String receiverId, required String type});

  // Call signaling
  void emitCallUser({required String userToCall, required dynamic signalData, required String from, required String name, required String callType});
  void emitAnswerCall({required String to, required dynamic signal});
  void emitIceCandidate({required String to, required dynamic candidate});
  void emitEndCall(String to);
  Stream<Map<String, dynamic>> get incomingCallStream;
  Stream<dynamic> get callAcceptedStream;
  Stream<dynamic> get iceCandidateStream;
  Stream<String> get callEndedStream;
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;
  IO.Socket? _socket;
  final StreamController<MessageModel> _messageController = StreamController<MessageModel>.broadcast();
  final StreamController<dynamic> _notificationController = StreamController<dynamic>.broadcast();
  final StreamController<Map<String, dynamic>> _incomingCallController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<dynamic> _callAcceptedController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _iceCandidateController = StreamController<dynamic>.broadcast();
  final StreamController<String> _callEndedController = StreamController<String>.broadcast();
  final StreamController<String> _messageDeletedController = StreamController<String>.broadcast();
  final StreamController<void> _chatClearedController = StreamController<void>.broadcast();
  final StreamController<dynamic> _appointmentSyncController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _notificationSyncController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _doctorSyncController = StreamController<dynamic>.broadcast();
  final StreamController<dynamic> _scheduleSyncController = StreamController<dynamic>.broadcast();

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Stream<MessageModel> get messageStream => _messageController.stream;

  @override
  Stream<dynamic> get notificationStream => _notificationController.stream;

  @override
  bool get isConnected => _socket?.connected ?? false;

  @override
  Stream<Map<String, dynamic>> get incomingCallStream => _incomingCallController.stream;

  @override
  Stream<dynamic> get callAcceptedStream => _callAcceptedController.stream;

  @override
  Stream<dynamic> get iceCandidateStream => _iceCandidateController.stream;

  @override
  Stream<String> get callEndedStream => _callEndedController.stream;

  @override
  Stream<String> get messageDeletedStream => _messageDeletedController.stream;

  @override
  Stream<void> get chatClearedStream => _chatClearedController.stream;

  @override
  Stream<dynamic> get appointmentSyncStream => _appointmentSyncController.stream;

  @override
  Stream<dynamic> get notificationSyncStream => _notificationSyncController.stream;

  @override
  Stream<dynamic> get doctorSyncStream => _doctorSyncController.stream;

  @override
  Stream<dynamic> get scheduleSyncStream => _scheduleSyncController.stream;

  @override
  void connectSocket() async {
    if (_socket != null && _socket!.connected) {
      return;
    }
    
    final userId = await apiClient.secureStorage.read(key: 'user_id');
    if (userId == null) {
      return;
    }

    print('[SOCKET] Attempting to connect for user: $userId');
    
    _socket = IO.io(ApiConstants.baseUrl, IO.OptionBuilder()
        .setTransports(['websocket', 'polling']) // Prefer websocket
        .setAuth({'userId': userId})
        .enableForceNew()
        .disableAutoConnect()
        .build());
    
    _socket?.onConnect((_) {
      print('[SOCKET] Connected to server');
    });
    
    _socket?.onConnectError((data) {
      print('[SOCKET] Connection Error: $data');
    });
    
    _socket?.onDisconnect((reason) {
      print('[SOCKET] Disconnected: $reason');
    });
    
    _socket?.onError((data) {
      print('[SOCKET] Error: $data');
    });
    
    _socket?.on('error', (data) {
      print('[SOCKET] Server Error Event: $data');
    });
    
    _socket?.connect();

    _socket?.on('receive_message', (data) {
      if (data != null) {
        _messageController.add(MessageModel.fromJson(data));
      }
    });

    _socket?.on('message_sent', (data) {
      if (data != null) {
        _messageController.add(MessageModel.fromJson(data));
      }
    });

    _socket?.on('receive_notification', (data) {
      if (data != null) {
        _notificationController.add(data);
      }
    });

    // Call signaling events
    _socket?.on('call_user', (data) {
      if (data != null) {
        _incomingCallController.add(Map<String, dynamic>.from(data));
      }
    });

    _socket?.on('call_accepted', (signal) {
      if (signal != null) {
        _callAcceptedController.add(signal);
      }
    });

    _socket?.on('ice_candidate', (candidate) {
      if (candidate != null) {
        _iceCandidateController.add(candidate);
      }
    });

    _socket?.on('end_call', (data) {
      _callEndedController.add(data?.toString() ?? '');
    });

    // Delete & clear events
    _socket?.on('message_deleted', (messageId) {
      if (messageId != null) {
        _messageDeletedController.add(messageId.toString());
      }
    });

    _socket?.on('chat_cleared', (data) {
      _chatClearedController.add(null);
    });

    _socket?.on('appointment_sync', (data) {
      print('[SOCKET] Appointment Sync Received: $data');
      _appointmentSyncController.add(data);
    });

    _socket?.on('notification_sync', (data) {
      print('[SOCKET] Notification Sync Received: $data');
      _notificationSyncController.add(data);
    });

    _socket?.on('profile_sync', (data) {
      print('[SOCKET] Profile Sync Received: $data');
      _doctorSyncController.add(data);
    });

    _socket?.on('doctor_profile_updated', (data) {
      print('[SOCKET] Global Doctor Profile Updated Received: $data');
      _doctorSyncController.add(data);
    });

    _socket?.on('doctor_rating_updated', (data) {
      print('[SOCKET] Global Doctor Rating Updated Received: $data');
      _doctorSyncController.add(data);
    });

    _socket?.on('schedule_sync', (data) {
      print('[SOCKET] Schedule Sync Received: $data');
      _scheduleSyncController.add(data);
    });

    // Server sends 'message_sent' back to sender as confirmation after DB save.
    // Route through messageStream so the sender sees the message with the real MongoDB ID.
    _socket?.on('message_sent', (data) {
      if (data != null && !_messageController.isClosed) {
        _messageController.add(MessageModel.fromJson(data));
      }
    });
  }

  @override
  void disconnectSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ---- Delete & Clear ----

  @override
  void emitDeleteMessage({required String messageId, required String receiverId, required bool forEveryone}) {
    _socket?.emit('delete_message', {
      'messageId': messageId,
      'receiverId': receiverId,
      'type': forEveryone ? 'everyone' : 'me',
    });
  }

  @override
  void emitClearChat({required String receiverId, required bool forEveryone}) {
    _socket?.emit('clear_chat', {
      'receiverId': receiverId,
      'type': forEveryone ? 'everyone' : 'me',
    });
  }

  @override
  Future<MessageModel> uploadFile({required String filePath, required String receiverId, required String type}) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      // POST to /api/messages/upload (Dio base URL already includes /api)
      final response = await apiClient.dio.post('/messages/upload', data: formData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final fileUrl = response.data['fileUrl']?.toString() ?? '';
        final originalName = response.data['filename']?.toString() ?? fileName;

        // Emit via socket so the receiver gets it too
        if (_socket?.connected == true) {
          _socket!.emit('send_message', {
            'receiverId': receiverId,
            'content': fileUrl,    // file URL as content
            'type': type,          // 'image' or 'file'
            'fileUrl': fileUrl,
            'fileName': originalName,
          });
        }

        // Build a local MessageModel for the sender's UI
        final userId = await apiClient.secureStorage.read(key: 'user_id') ?? '';
        return MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: userId,
          receiverId: receiverId,
          content: fileUrl,
          timestamp: DateTime.now(),
          type: type,
          fileUrl: fileUrl,
          fileName: originalName,
        );
      } else {
        throw ServerException(message: 'File upload failed');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ?? 'Upload failed',
      );
    } catch (e) {
      throw ServerException(message: 'Upload error: ${e.runtimeType}');
    }
  }

  // ---- Call Signaling Emit Methods ----

  @override
  void emitCallUser({
    required String userToCall,
    required dynamic signalData,
    required String from,
    required String name,
    required String callType,
  }) {
    _socket?.emit('call_user', {
      'userToCall': userToCall,
      'signalData': signalData,
      'from': from,
      'name': name,
      'callType': callType,
    });
  }

  @override
  void emitAnswerCall({required String to, required dynamic signal}) {
    _socket?.emit('answer_call', {'to': to, 'signal': signal});
  }

  @override
  void emitIceCandidate({required String to, required dynamic candidate}) {
    _socket?.emit('ice_candidate', {'to': to, 'candidate': candidate});
  }

  @override
  void emitEndCall(String to) {
    _socket?.emit('end_call', {'to': to});
  }

  @override
  void emitSendMessage(String receiverId, String content) {
    if (_socket != null && _socket!.connected) {
      print('[SOCKET] Emitting message to $receiverId');
      _socket!.emit('send_message', {
        'receiverId': receiverId,
        'content': content,
        'type': 'text',
      });
    } else {
      print('[SOCKET] Not connected. Attempting to connect...');
      connectSocket();
      throw ServerException(message: 'Socket is not connected. Trying to reconnect...');
    }
  }

  @override
  Future<List<ChatContact>> getContacts() async {
    try {
      final response = await apiClient.dio.get('/messages/contacts');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> contactsJson = response.data['data'];
        return contactsJson.map((json) => ChatContact.fromJson(json)).toList();
      } else {
        throw ServerException(message: 'Failed to fetch contacts');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data['message'] ?? e.message ?? 'Failed to connect to server',
      );
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<MessageModel>> getMessages(String userId) async {
    try {
      final response = await apiClient.dio.get('/messages/$userId');

      if (response.statusCode == 200) {
        // Handle both: plain list OR {success, data:[...]} envelope
        List<dynamic> messagesJson;
        if (response.data is List) {
          messagesJson = response.data as List<dynamic>;
        } else if (response.data is Map && response.data['data'] is List) {
          messagesJson = response.data['data'] as List<dynamic>;
        } else {
          messagesJson = [];
        }

        return messagesJson
            .where((json) => json is Map<String, dynamic>)
            .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(message: 'Failed to fetch messages');
      }
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ??
            e.message ??
            'Failed to connect to server',
      );
    } catch (e) {
      throw ServerException(message: 'Message loading error: ${e.runtimeType}');
    }
  }

  @override
  Future<void> markAsRead(String senderId) async {
    try {
      await apiClient.dio.put('/messages/read/$senderId');
    } on DioException catch (e) {
      throw ServerException(
        message: e.response?.data?['message']?.toString() ??
            e.message ??
            'Failed to mark messages as read',
      );
    } catch (e) {
      throw ServerException(message: 'Mark as read error: ${e.runtimeType}');
    }
  }
}
