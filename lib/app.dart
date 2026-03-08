import 'dart:async';
import 'package:doctoroncall/features/call/incoming_call_overlay.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/screens/auth/role_selection_screen.dart';
import 'package:doctoroncall/screens/patient/patient_main_screen.dart';
import 'package:doctoroncall/screens/doctor/doctor_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:doctoroncall/core/theme/theme_service.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/theme_data/theme_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/auth/presentation/providers/auth_provider.dart';
import 'package:doctoroncall/features/notifications/presentation/providers/notification_provider.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_state.dart';
import 'package:doctoroncall/core/providers/lock_provider.dart';
import 'package:doctoroncall/screens/shared/app_lock_screen.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService().themeMode,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'doctoroncall',
          debugShowCheckedModeBanner: false,
          theme: getApplicationTheme(),
          darkTheme: getApplicationTheme(isDark: true),
          themeMode: mode,
          home: const _IncomingCallWrapper(),
        );
      },
    );
  }
}

/// Wraps the main content and listens for incoming call events globally.
class _IncomingCallWrapper extends ConsumerStatefulWidget {
  const _IncomingCallWrapper();

  @override
  ConsumerState<_IncomingCallWrapper> createState() =>
      _IncomingCallWrapperState();
}

class _IncomingCallWrapperState extends ConsumerState<_IncomingCallWrapper>
    with WidgetsBindingObserver {
  StreamSubscription? _incomingCallSub;
  StreamSubscription? _messageSub;
  StreamSubscription? _notificationSub;
  StreamSubscription? _profileSyncSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Trigger initial auth check
    Future.microtask(() => ref.read(authProvider.notifier).checkAuthStatus());

    // Start listening for signals once socket may connect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForIncomingCalls();
      _listenForMessages();
      _listenForNotifications();
      _listenForProfileSync();
    });
  }

  AppLifecycleState? _lastState;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-lock the app if it was paused and is now resumed.
    if (state == AppLifecycleState.resumed &&
        _lastState == AppLifecycleState.paused) {
      final lockNotifier = ref.read(lockProvider.notifier);
      final lastUnlock = lockNotifier.lastUnlockTime;
      final now = DateTime.now();

      // Grace period of 2 seconds to avoid re-locking if resumed just after prompt closes
      final isRecentlyUnlocked =
          lastUnlock != null && now.difference(lastUnlock).inSeconds < 2;

      if (!lockNotifier.isAuthenticating && !isRecentlyUnlocked) {
        lockNotifier.lock();
      }
    }
    _lastState = state;
  }

  void _listenForProfileSync() {
    final dataSource = sl<ChatRemoteDataSource>();
    _profileSyncSub = dataSource.doctorSyncStream.listen((data) async {
      if (!mounted) return;

      final box = Hive.box(HiveBoxes.users);
      final currentUser = box.get('currentUser');

      if (currentUser is Map) {
        // Update Hive
        final updatedUserMap = Map<String, dynamic>.from(currentUser);
        if (data is Map) {
          data.forEach((key, value) {
            if (key == 'image') {
              updatedUserMap['profileImage'] = value;
            } else {
              updatedUserMap[key] = value;
            }
          });
          await box.put('currentUser', updatedUserMap);

          // Trigger theme update if preferences changed
          if (data.containsKey('preferences')) {
            final prefs = data['preferences'] as Map?;
            if (prefs != null) {
              final isDark = prefs['darkMode'] as bool? ?? false;
              await ThemeService().updateTheme(isDark);
            }
          }
        }
      }
    });
  }

  void _listenForIncomingCalls() {
    final dataSource = sl<ChatRemoteDataSource>();
    _incomingCallSub = dataSource.incomingCallStream.listen((data) async {
      if (!mounted) return;
      // Get local user id for answering
      final apiClient = sl<ApiClient>();
      final localUserId =
          await apiClient.secureStorage.read(key: 'user_id') ?? '';

      if (!mounted) return;
      final signal = data['signal'] as Map<String, dynamic>?;
      final from = data['from']?.toString() ?? '';
      final name = data['name']?.toString() ?? 'Unknown';
      final callType = data['callType']?.toString() ?? 'audio';
      final isVideo = callType == 'video';

      if (signal == null || from.isEmpty) return;

      // Extract Jitsi room name if it's a Jitsi invite
      String? roomName;
      if (signal['type'] == 'jitsi_invite') {
        roomName = signal['roomName'] as String?;
      }

      await showIncomingCallDialog(
        context,
        callerName: name,
        callerId: from,
        localUserId: localUserId,
        offer: signal,
        isVideo: isVideo,
        roomName: roomName,
      );
    });
  }

  void _listenForMessages() {
    final dataSource = sl<ChatRemoteDataSource>();
    _messageSub = dataSource.messageStream.listen((message) {
      debugPrint('[SOCKET] Message received: ${message.content}');
      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        if (message.senderId == authState.user.id) return;
      }

      _showPremiumToast(
        title: 'New Message',
        content: message.content,
        icon: Icons.forum_rounded,
      );
    });
  }

  void _listenForNotifications() {
    final dataSource = sl<ChatRemoteDataSource>();
    _notificationSub = dataSource.notificationStream.listen((data) {
      debugPrint('[SOCKET] Notification received: $data');
      if (!mounted) return;

      // Check if notifications are enabled in preferences
      final box = Hive.box(HiveBoxes.users);
      final userData = box.get('currentUser');
      bool enabled = true;
      if (userData is Map && userData['preferences'] is Map) {
        enabled = userData['preferences']['notifications'] as bool? ?? true;
      }

      if (!enabled) return;

      if (data is Map) {
        final message = data['message']?.toString() ?? 'You have a new alert';
        final type = data['type']?.toString() ?? 'INFO';

        IconData icon = Icons.notifications_active_rounded;
        if (type == 'SUCCESS') icon = Icons.check_circle_rounded;
        if (type == 'WARNING') icon = Icons.warning_rounded;
        if (type == 'ERROR') icon = Icons.error_rounded;

        _showPremiumToast(title: 'Notification', content: message, icon: icon);
      }
    });
  }

  OverlayEntry? _toastEntry;

  void _showPremiumToast({
    required String title,
    required String content,
    required IconData icon,
  }) {
    _toastEntry?.remove();
    _toastEntry = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _PremiumToast(
        title: title,
        content: content,
        icon: icon,
        onDismiss: () {
          if (_toastEntry == entry) {
            entry.remove();
            _toastEntry = null;
          }
        },
      ),
    );

    _toastEntry = entry;
    overlay.insert(entry);

    // Auto dismiss after 4s
    Future.delayed(const Duration(seconds: 4), () {
      if (_toastEntry == entry) {
        entry.remove();
        _toastEntry = null;
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _incomingCallSub?.cancel();
    _messageSub?.cancel();
    _notificationSub?.cancel();
    _profileSyncSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth status to handle socket connection and navigation
    final authState = ref.watch(authProvider);

    // Global listener for socket connection
    ref.listen(authProvider, (previous, next) {
      if (next is AuthAuthenticated && (previous is! AuthAuthenticated)) {
        sl<ChatRemoteDataSource>().connectSocket();
        ref.read(notificationNotifierProvider.notifier).loadNotifications();
      } else if (next is AuthUnauthenticated) {
        sl<ChatRemoteDataSource>().disconnectSocket();
      }
    });

    // Watch lock status
    final lockState = ref.watch(lockProvider);
    if (lockState.value == true) {
      return const AppLockScreen();
    }

    if (authState is AuthAuthenticated) {
      return authState.user.role.toUpperCase() == 'DOCTOR'
          ? const DoctorMainScreen()
          : const PatientMainScreen();
    }
    if (authState is AuthLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6AA9D8)),
        ),
      );
    }
    return const RoleSelectionScreen();
  }
}

// ──────────────────────────────────────────────────────────
// Premium sliding toast  (iOS-style push notification)
// ──────────────────────────────────────────────────────────
class _PremiumToast extends StatefulWidget {
  final String title;
  final String content;
  final IconData icon;
  final VoidCallback onDismiss;

  const _PremiumToast({
    required this.title,
    required this.content,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_PremiumToast> createState() => _PremiumToastState();
}

class _PremiumToastState extends State<_PremiumToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.4)),
    );
    _controller.forward();
  }

  Future<void> _dismiss() async {
    await _controller.reverse(from: 1);
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    return Positioned(
      top: safeTop + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF32789D), Color(0xFF4889A8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4889A8).withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Icon bubble
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    // Message text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.content.length > 70
                                ? '${widget.content.substring(0, 70)}…'
                                : widget.content,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss X
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
