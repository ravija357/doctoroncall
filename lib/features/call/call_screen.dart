import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:doctoroncall/features/call/call_service.dart';
import 'package:doctoroncall/core/di/injection_container.dart';

class CallScreen extends StatefulWidget {
  final String remoteUserId;
  final String remoteUserName;
  final bool isVideo;
  final bool isCaller;
  final String localUserId;
  final Map<String, dynamic>? incomingOffer;

  const CallScreen({
    super.key,
    required this.remoteUserId,
    required this.remoteUserName,
    required this.isVideo,
    required this.isCaller,
    required this.localUserId,
    this.incomingOffer,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // Nullable so we can guard against uninitialised access
  CallService? _callService;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  bool _isMuted = false;
  bool _isCameraOff = false;
  bool _callConnected = false;
  bool _isInitialising = true;

  StreamSubscription? _remoteConnectedSub;
  StreamSubscription? _endSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Request permissions first
    await [Permission.camera, Permission.microphone].request();

    // Initialise renderers
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    // Create service and hand it the renderers so it can set srcObject directly
    final service = sl<CallService>();
    service.localRenderer = _localRenderer;
    service.remoteRenderer = _remoteRenderer;

    // Listen for remote connection and call ended events
    _remoteConnectedSub = service.onRemoteConnected.listen((_) {
      if (mounted) setState(() => _callConnected = true);
    });

    _endSub = service.onCallEnded.listen((_) {
      if (mounted) _navigateBack();
    });

    if (!mounted) return;
    if (widget.isCaller) {
      await service.startCall(
        remoteUserId: widget.remoteUserId,
        remoteName: widget.remoteUserName,
        localUserId: widget.localUserId,
        isVideo: widget.isVideo,
      );
    } else if (widget.incomingOffer != null) {
      await service.answerCall(
        callerId: widget.remoteUserId,
        offer: widget.incomingOffer!,
        isVideo: widget.isVideo,
      );
    }

    if (mounted) {
      setState(() {
        _callService = service;
        _isInitialising = false;
      });
    }
  }

  void _navigateBack() {
    if (mounted) Navigator.of(context).pop();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _localRenderer.srcObject?.getAudioTracks().forEach((t) => t.enabled = !_isMuted);
  }

  void _toggleCamera() {
    setState(() => _isCameraOff = !_isCameraOff);
    _localRenderer.srcObject?.getVideoTracks().forEach((t) => t.enabled = !_isCameraOff);
  }

  void _endCall() {
    _callService?.endCall(widget.remoteUserId);
    _navigateBack();
  }

  @override
  void dispose() {
    _remoteConnectedSub?.cancel();
    _endSub?.cancel();
    _callService?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent accidental back, must use end call
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _endCall();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Stack(
          children: [
            // ------ BACKGROUND / AVATAR (always shown, hidden by video when connected) ------
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.purple.shade400],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.remoteUserName.isNotEmpty
                              ? widget.remoteUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 48,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.remoteUserName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _isInitialising
                          ? 'Starting...'
                          : _callConnected
                              ? (widget.isVideo ? 'Video Call' : 'Audio Call')
                              : (widget.isCaller ? 'Calling...' : 'Connecting...'),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 16,
                      ),
                    ),
                    if (_isInitialising) ...[
                      const SizedBox(height: 24),
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ------ REMOTE VIDEO (full screen, on top of background when connected) ------
            if (widget.isVideo && _callConnected)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),

            // ------ LOCAL VIDEO (thumbnail top-right, always show for video calls) ------
            if (widget.isVideo)
              Positioned(
                top: 60,
                right: 16,
                width: 110,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.black54,
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // ------ BOTTOM CONTROLS ------
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CallButton(
                        icon: _isMuted ? Icons.mic_off : Icons.mic,
                        label: _isMuted ? 'Unmute' : 'Mute',
                        bgColor: _isMuted
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        iconColor: _isMuted ? Colors.black : Colors.white,
                        onTap: _toggleMute,
                      ),
                      const SizedBox(width: 28),
                      // End call — always enabled, no guard needed
                      _CallButton(
                        icon: Icons.call_end,
                        label: 'End',
                        bgColor: Colors.red.shade600,
                        iconColor: Colors.white,
                        onTap: _endCall,
                        size: 72,
                      ),
                      const SizedBox(width: 28),
                      widget.isVideo
                          ? _CallButton(
                              icon: _isCameraOff
                                  ? Icons.videocam_off
                                  : Icons.videocam,
                              label: _isCameraOff ? 'Cam On' : 'Cam Off',
                              bgColor: _isCameraOff
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.15),
                              iconColor:
                                  _isCameraOff ? Colors.black : Colors.white,
                              onTap: _toggleCamera,
                            )
                          : _CallButton(
                              icon: Icons.speaker_phone,
                              label: 'Speaker',
                              bgColor: Colors.white.withValues(alpha: 0.15),
                              iconColor: Colors.white,
                              onTap: () {},
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;

  const _CallButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(size / 2),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: size * 0.42),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
