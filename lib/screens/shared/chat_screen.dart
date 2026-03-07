import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/messages/presentation/providers/chat_provider.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_state.dart';
import 'package:doctoroncall/features/messages/domain/entities/message.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/core/constants/api_constants.dart';
import 'package:doctoroncall/features/call/jitsi_call_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late Timer _statusTimer;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(chatNotifierProvider.notifier);
      notifier.connectSocket();
      notifier.loadMessages(widget.otherUserId);
      notifier.markAsRead(widget.otherUserId);
    });

    _statusTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final connected = sl<ChatRepository>().isSocketConnected;
      if (connected != _isConnected) setState(() => _isConnected = connected);
    });
  }

  @override
  void dispose() {
    _statusTimer.cancel();
    _messageController.dispose();
    // Reset active chat ID
    ref.read(chatNotifierProvider.notifier).resetActiveChatUserId();
    super.dispose();
  }

  // ─────────────────────────────────── Build ────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<ChatState>(chatNotifierProvider, (previous, next) {
      if (next is MessagesLoaded) {
        final state = next;
        if (state.messages.isNotEmpty &&
            state.messages.last.senderId == widget.otherUserId) {
          ref
              .read(chatNotifierProvider.notifier)
              .markAsRead(widget.otherUserId);
        }
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? theme.cardColor
                    : Colors.black.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_left,
                color: isDark ? theme.iconTheme.color : theme.primaryColor,
                size: 28,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.otherUserName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  if (_isConnected)
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone_rounded, color: theme.primaryColor),
            tooltip: 'Audio Call',
            onPressed: () => _startCall(isVideo: false),
          ),
          IconButton(
            icon: Icon(Icons.videocam_rounded, color: theme.primaryColor),
            tooltip: 'Video Call',
            onPressed: () => _startCall(isVideo: true),
          ),
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
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  isDark
                      ? theme.dividerColor.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final state = ref.watch(chatNotifierProvider);
          return Column(
            children: [
              // File uploading indicator
              if (state is FileUploading)
                Container(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Uploading…',
                        style: TextStyle(
                          color: theme.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              // Message list
              Expanded(
                child: (() {
                  if (state is ChatLoading) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: theme.primaryColor,
                      ),
                    );
                  } else if (state is ChatError) {
                    return Center(child: Text(state.message));
                  } else if (state is MessagesLoaded) {
                    final messages = state.messages.reversed.toList();
                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: isDark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Start the conversation!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final message = messages[index];
                              final isMe =
                                  message.senderId != widget.otherUserId;
                              return _MessageBubble(
                                message: message,
                                isMe: isMe,
                                otherUserId: widget.otherUserId,
                                onDelete: (forEveryone) {
                                  if (message.id != null) {
                                    ref
                                        .read(chatNotifierProvider.notifier)
                                        .deleteMessage(
                                          messageId: message.id!,
                                          receiverId: widget.otherUserId,
                                          forEveryone: forEveryone,
                                        );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        if (ref
                                .watch(chatNotifierProvider.notifier)
                                .typingUserId ==
                            widget.otherUserId)
                          Padding(
                            padding: const EdgeInsets.only(left: 20, bottom: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.otherUserName} is typing...',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.primaryColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                })(),
              ),
              // Input bar
              _buildInputBar(theme, isDark),
            ],
          );
        },
      ),
    );
  }

  void _startCall({required bool isVideo}) async {
    final apiClient = sl<ApiClient>();
    final localUserId =
        await apiClient.secureStorage.read(key: 'user_id') ?? '';
    if (!mounted) return;

    final roomName =
        'doc-call-$localUserId-${DateTime.now().millisecondsSinceEpoch}';
    final chatRepo = sl<ChatRepository>();

    // Get sender name for call
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    String senderName = 'User';
    if (userData is Map) {
      senderName =
          '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    } else {
      senderName =
          '${box.get('firstName', defaultValue: '')} ${box.get('lastName', defaultValue: '')}'
              .trim();
    }
    if (senderName.isEmpty) senderName = 'User';

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

  // ─────────────────────────────────── Input bar ────────────────────────────

  Widget _buildInputBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
        ],
        border: isDark
            ? Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              )
            : null,
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(Icons.attach_file_rounded, color: theme.primaryColor),
            tooltip: 'Send file',
            onPressed: _pickAndSendFile,
          ),
          IconButton(
            icon: Icon(Icons.image_rounded, color: theme.primaryColor),
            tooltip: 'Send image',
            onPressed: _pickAndSendImage,
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? theme.dividerColor.withValues(alpha: 0.1)
                      : Colors.grey.shade200,
                ),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onChanged: (text) {
                  if (text.isNotEmpty) {
                    ref
                        .read(chatNotifierProvider.notifier)
                        .emitTyping(widget.otherUserId);
                  } else {
                    ref
                        .read(chatNotifierProvider.notifier)
                        .emitStopTyping(widget.otherUserId);
                  }
                },
                onSubmitted: (_) {
                  ref
                      .read(chatNotifierProvider.notifier)
                      .emitStopTyping(widget.otherUserId);
                  _sendMessage(context);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: theme.primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () {
                  ref
                      .read(chatNotifierProvider.notifier)
                      .emitStopTyping(widget.otherUserId);
                  _sendMessage(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    ref.read(chatNotifierProvider.notifier).sendMessage(message);
  }

  Future<void> _pickAndSendImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.single.path != null && mounted) {
      ref
          .read(chatNotifierProvider.notifier)
          .sendFile(
            filePath: result.files.single.path!,
            receiverId: widget.otherUserId,
            type: 'image',
          );
    }
  }

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'txt',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'zip',
      ],
    );
    if (result != null && result.files.single.path != null && mounted) {
      ref
          .read(chatNotifierProvider.notifier)
          .sendFile(
            filePath: result.files.single.path!,
            receiverId: widget.otherUserId,
            type: 'file',
          );
    }
  }

  void _showClearChatConfirm({required bool forEveryone}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Clear Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          forEveryone
              ? 'This will permanently delete all messages for both you and ${widget.otherUserName}.'
              : 'This will clear the chat only for you.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: Text(
              'Clear',
              style: TextStyle(
                color: forEveryone ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(chatNotifierProvider.notifier)
                  .clearChat(
                    receiverId: widget.otherUserId,
                    forEveryone: forEveryone,
                  );
            },
          ),
        ],
      ),
    );
  }
}

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
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            if (isMe)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_forever,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Delete for everyone',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Remove from both sides'),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(true);
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.orange,
                  size: 20,
                ),
              ),
              title: const Text(
                'Delete for me',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Only removed from your view'),
              onTap: () {
                Navigator.pop(context);
                onDelete(false);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isImage = message.type == 'image';
    final isFile = message.type == 'file';

    return GestureDetector(
      onLongPress: () => _showDeleteMenu(context),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: isImage
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isImage
                ? Colors.transparent
                : (isMe
                      ? theme.primaryColor
                      : (isDark ? theme.cardColor : Colors.grey.shade100)),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: isMe
                  ? const Radius.circular(20)
                  : const Radius.circular(4),
              bottomRight: isMe
                  ? const Radius.circular(4)
                  : const Radius.circular(20),
            ),
            boxShadow: isImage
                ? null
                : [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
            border: isDark && !isMe && !isImage
                ? Border.all(color: theme.dividerColor.withValues(alpha: 0.1))
                : null,
          ),
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
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
                    fontSize: 15,
                    color: isMe
                        ? Colors.white
                        : theme.textTheme.bodyLarge?.color,
                    height: 1.4,
                  ),
                ),
              if (!isImage) ...[
                const SizedBox(height: 6),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey.shade500,
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
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 60, color: Colors.grey),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const SizedBox(
                width: 200,
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              ),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final String fileName;
  final String fileUrl;
  final bool isMe;
  const _FileBubble({
    required this.fileName,
    required this.fileUrl,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => OpenFilex.open(fileUrl),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            color: isMe ? Colors.white : const Color(0xFF6AA9D8),
            size: 28,
          ),
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
