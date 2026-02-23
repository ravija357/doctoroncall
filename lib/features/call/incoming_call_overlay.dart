import 'package:flutter/material.dart';
import 'package:doctoroncall/features/call/call_screen.dart';

/// Show an incoming call dialog. Returns true if accepted, false if declined.
Future<bool?> showIncomingCallDialog(
  BuildContext context, {
  required String callerName,
  required String callerId,
  required String localUserId,
  required Map<String, dynamic> offer,
  required bool isVideo,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _IncomingCallDialog(
      callerName: callerName,
      callerId: callerId,
      localUserId: localUserId,
      offer: offer,
      isVideo: isVideo,
    ),
  );
}

class _IncomingCallDialog extends StatelessWidget {
  final String callerName;
  final String callerId;
  final String localUserId;
  final Map<String, dynamic> offer;
  final bool isVideo;

  const _IncomingCallDialog({
    required this.callerName,
    required this.callerId,
    required this.localUserId,
    required this.offer,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated ring icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade400],
                ),
              ),
              child: Icon(
                isVideo ? Icons.videocam : Icons.phone,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Incoming ${isVideo ? "Video" : "Audio"} Call',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Accept / Decline buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Decline
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(false),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text('Decline', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                // Accept
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop(true);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CallScreen(
                          remoteUserId: callerId,
                          remoteUserName: callerName,
                          isVideo: isVideo,
                          isCaller: false,
                          localUserId: localUserId,
                          incomingOffer: offer,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isVideo ? Icons.videocam : Icons.phone,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('Accept', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
