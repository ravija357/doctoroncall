import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_bloc.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_event.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_state.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/core/constants/api_constants.dart';
import 'package:doctoroncall/features/call/jitsi_call_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Timer _statusTimer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(ConnectSocketRequested());
    context.read<ChatBloc>().add(LoadMessagesRequested(userId: widget.otherUserId));
    context.read<ChatBloc>().add(MarkAsReadRequested(userId: widget.otherUserId));

    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final connected = sl<ChatRepository>().isSocketConnected;
      if (connected != _isConnected) setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    _statusTimer.cancel();
    _messageController.dispose();
    // Reset active chat ID so SnackBar notifications for this user can resume
    context.read<ChatBloc>().add(ResetActiveChatUserId());
    super.dispose();
  }

  // ─────────────────────────────────── Build ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.otherUserName,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        actions: [
          // Audio call
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: Color(0xFF6AA9D8)),
            tooltip: 'Audio Call',
            onPressed: () => _startCall(isVideo: false),
          ),
          // Video call
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: Color(0xFF6AA9D8)),
            tooltip: 'Video Call',
            onPressed: () => _startCall(isVideo: true),
          ),
          // Three-dot menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_me') {
                _showClearChatConfirm(forEveryone: false);
              } else if (value == 'clear_all') {
                _showClearChatConfirm(forEveryone: true);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'clear_me',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Clear for me'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Clear for everyone'),
                  ],
                ),
              ),
            ],
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: BlocListener<ChatBloc, ChatState>(
        listenWhen: (p, c) => c is MessagesLoaded,
        listener: (context, state) {
          if (state is MessagesLoaded) {
            // Check if the last message in the loaded list is from the other user
            if (state.messages.isNotEmpty && state.messages.last.senderId == widget.otherUserId) {
              context.read<ChatBloc>().add(MarkAsReadRequested(userId: widget.otherUserId));
            }
          }
        },
        child: Column(
          children: [
            // File uploading indicator
            BlocBuilder<ChatBloc, ChatState>(
              buildWhen: (p, c) => c is FileUploading || p is FileUploading,
              builder: (_, state) {
                if (state is FileUploading) {
                  return Container(
                    color: const Color(0xFF6AA9D8).withValues(alpha: 0.1),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    child: const Row(
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6AA9D8))),
                        SizedBox(width: 10),
                        Text('Uploading…', style: TextStyle(color: Color(0xFF6AA9D8), fontSize: 13)),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            // Message list
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8)));
                  } else if (state is ChatError) {
                    return Center(child: Text(state.message));
                  } else if (state is MessagesLoaded) {
                    final messages = state.messages.reversed.toList();
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'Start the conversation!',
                          style: TextStyle(fontFamily: 'PlayfairDisplay', color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderId != widget.otherUserId;
                        return _MessageBubble(
                          message: message,
                          isMe: isMe,
                          otherUserId: widget.otherUserId,
                          onDelete: (forEveryone) {
                            if (message.id != null) {
                              context.read<ChatBloc>().add(DeleteMessageRequested(
                                messageId: message.id!,
                                receiverId: widget.otherUserId,
                                forEveryone: forEveryone,
                              ));
                            }
                          },
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            // Input bar
            _buildInputBar(context),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────── Input bar ────────────────────────────

  Widget _buildInputBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach button
          IconButton(
            icon: const Icon(Icons.attach_file_rounded, color: Color(0xFF6AA9D8)),
            tooltip: 'Send file',
            onPressed: _pickAndSendFile,
          ),
          // Image button
          IconButton(
            icon: const Icon(Icons.image_rounded, color: Color(0xFF6AA9D8)),
            tooltip: 'Send image',
            onPressed: _pickAndSendImage,
          ),
          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(context),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          CircleAvatar(
            backgroundColor: const Color(0xFF6AA9D8),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(context),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────── Actions ──────────────────────────────

  void _sendMessage(BuildContext context) {
    if (_messageController.text.trim().isEmpty) return;
    final content = _messageController.text.trim();
    _messageController.clear();

    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'me',
      receiverId: widget.otherUserId,
      content: content,
      timestamp: DateTime.now(),
    );
    context.read<ChatBloc>().add(SendMessageRequested(message: message));
  }

  Future<void> _pickAndSendImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null && mounted) {
      context.read<ChatBloc>().add(SendFileRequested(
        filePath: result.files.single.path!,
        receiverId: widget.otherUserId,
        type: 'image',
      ));
    }
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx', 'zip'],
    );
    if (result != null && result.files.single.path != null && mounted) {
      context.read<ChatBloc>().add(SendFileRequested(
        filePath: result.files.single.path!,
        receiverId: widget.otherUserId,
        type: 'file',
      ));
    }
  }

  void _showClearChatConfirm({required bool forEveryone}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Chat'),
        content: Text(
          forEveryone
              ? 'This will permanently delete all messages for both you and ${widget.otherUserName}.'
              : 'This will clear the chat only for you.',
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.pop(ctx)),
          TextButton(
            child: Text(
              'Clear',
              style: TextStyle(color: forEveryone ? Colors.red : Colors.orange),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<ChatBloc>().add(ClearChatRequested(
                receiverId: widget.otherUserId,
                forEveryone: forEveryone,
              ));
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startCall({required bool isVideo}) async {
    final apiClient = sl<ApiClient>();
    final localUserId = await apiClient.secureStorage.read(key: 'user_id') ?? '';
    if (!mounted) return;

    final roomName = 'doc-call-$localUserId-${DateTime.now().millisecondsSinceEpoch}';
    final chatRepo = sl<ChatRepository>();
    
    // Get sender name for call 
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    String senderName = 'User';
    if (userData is Map) {
      senderName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    } else {
      senderName = '${box.get('firstName', defaultValue: '')} ${box.get('lastName', defaultValue: '')}'.trim();
    }
    if (senderName.isEmpty) senderName = 'User';

    // Instead of raw WebRTC, emit jitsi_invite
    try {
      chatRepo.emitCallUser(
        userToCall: widget.otherUserId,
        signalData: {'type': 'jitsi_invite', 'roomName': roomName},
        from: localUserId,
        name: senderName,
        callType: isVideo ? 'video' : 'audio',
      );
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JitsiCallScreen(
          roomName: roomName,
          isVideo: isVideo,
          remoteUserId: widget.otherUserId,
        ),
      ),
    );
  }
}

// ────────────────────────────────── Message Bubble ────────────────────────────

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String otherUserId;
  final void Function(bool forEveryone) onDelete;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.otherUserId,
    required this.onDelete,
  });

  void _showDeleteMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('Delete for everyone'),
                subtitle: const Text('Remove from both sides'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(true);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.orange),
              title: const Text('Delete for me'),
              subtitle: const Text('Only removed from your view'),
              onTap: () {
                Navigator.pop(context);
                onDelete(false);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isImage = message.type == 'image';
    final isFile = message.type == 'file';

    return GestureDetector(
      onLongPress: () => _showDeleteMenu(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
          padding: isImage
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isImage ? Colors.transparent : (isMe ? const Color(0xFF6AA9D8) : Colors.white),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(2),
              bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(18),
            ),
            boxShadow: isImage
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Content
              if (isImage && message.fileUrl != null)
                _ImageBubble(fileUrl: message.fileUrl!)
              else if (isFile && message.fileUrl != null)
                _FileBubble(
                  fileName: message.fileName ?? 'File',
                  fileUrl: message.fileUrl!,
                  isMe: isMe,
                )
              else
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              // Timestamp
              if (!isImage) ...[
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white.withValues(alpha: 0.7) : Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ImageBubble extends StatelessWidget {
  final String fileUrl;
  const _ImageBubble({required this.fileUrl});

  @override
  Widget build(BuildContext context) {
    final url = fileUrl.startsWith('http')
        ? fileUrl
        : '${ApiConstants.baseUrl}$fileUrl';
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        url,
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: Colors.grey),
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const SizedBox(width: 200, height: 140, child: Center(child: CircularProgressIndicator())),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final String fileName;
  final String fileUrl;
  final bool isMe;
  const _FileBubble({required this.fileName, required this.fileUrl, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => OpenFilex.open(fileUrl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_rounded,
              color: isMe ? Colors.white : const Color(0xFF6AA9D8), size: 28),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              fileName,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                decoration: TextDecoration.underline,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
