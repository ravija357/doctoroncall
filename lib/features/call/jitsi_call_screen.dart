import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Launches a Jitsi Meet call and immediately pops the Flutter route so the
/// native Jitsi view owns the screen without a stale Flutter context underneath.
/// This prevents "Lost connection to device" crashes when Jitsi dismisses.
class JitsiCallScreen extends StatefulWidget {
  final String roomName;
  final bool isVideo;
  final String remoteUserId;

  const JitsiCallScreen({
    super.key,
    required this.roomName,
    required this.isVideo,
    required this.remoteUserId,
  });

  @override
  State<JitsiCallScreen> createState() => _JitsiCallScreenState();
}

class _JitsiCallScreenState extends State<JitsiCallScreen> {
  final _jitsiMeetPlugin = JitsiMeet();
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame callback so Navigator is fully settled before we pop
    WidgetsBinding.instance.addPostFrameCallback((_) => _launchCall());
  }

  Future<void> _launchCall() async {
    if (_launching) return;
    _launching = true;

    // Build user info from Hive
    String displayName = 'User';
    String email = '';
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    if (userData is Map) {
      final first = userData['firstName'] ?? '';
      final last = userData['lastName'] ?? '';
      displayName = '$first $last'.trim().isNotEmpty ? '$first $last'.trim() : 'User';
      email = userData['email'] ?? '';
    } else {
      final first = box.get('firstName', defaultValue: '');
      final last = box.get('lastName', defaultValue: '');
      displayName = '$first $last'.trim().isNotEmpty ? '$first $last'.trim() : 'User';
      email = box.get('email', defaultValue: '');
    }

    final options = JitsiMeetConferenceOptions(
      serverURL: "https://jitsi.riot.im",
      room: widget.roomName,
      configOverrides: {
        "startWithAudioMuted": false,
        "startWithVideoMuted": !widget.isVideo,
        "prejoinPageEnabled": false,
        "disableModeratorIndicator": true,
      },
      featureFlags: {
        "welcomePageEnabled": false,
        "prejoinPageEnabled": false,
        "unsafeRoomWarningEnabled": false,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: displayName,
        email: email,
      ),
    );

    // Capture remoteUserId before popping so closure doesn't hold a stale context
    final remoteId = widget.remoteUserId;

    // ⚠️ Pop FIRST so Flutter navigation stack is clean when Jitsi takes over
    if (mounted) Navigator.of(context).pop();

    final listener = JitsiMeetEventListener(
      conferenceTerminated: (url, error) {
        debugPrint("[Jitsi] conferenceTerminated: url=$url, error=$error");
        // Only emit socket signal — no Navigator.pop() here (context is gone)
        try {
          sl<ChatRepository>().emitEndCall(remoteId);
        } catch (_) {}
      },
      conferenceJoined: (url) {
        debugPrint("[Jitsi] conferenceJoined: $url");
      },
    );

    try {
      await _jitsiMeetPlugin.join(options, listener);
    } catch (e) {
      debugPrint("[Jitsi] join error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Brief loading screen shown only while the post-frame callback fires
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF6AA9D8)),
            SizedBox(height: 20),
            Text(
              'Connecting to call…',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

