import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';

/// Manages the WebRTC peer connection, streams, and call signaling.
class CallService {
  final ChatRemoteDataSource dataSource;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  // Renderers are owned by the screen but set here so we can assign srcObject
  // directly (avoids missing stream events that fire before subscriptions).
  RTCVideoRenderer? localRenderer;
  RTCVideoRenderer? remoteRenderer;

  final _localStreamCtrl = StreamController<MediaStream>.broadcast();
  final _remoteStreamCtrl = StreamController<MediaStream>.broadcast();
  final _callEndedCtrl = StreamController<void>.broadcast();
  final _remoteConnectedCtrl = StreamController<bool>.broadcast();

  Stream<MediaStream> get localStream => _localStreamCtrl.stream;
  Stream<MediaStream> get remoteStream => _remoteStreamCtrl.stream;
  Stream<void> get onCallEnded => _callEndedCtrl.stream;
  Stream<bool> get onRemoteConnected => _remoteConnectedCtrl.stream;

  StreamSubscription? _callAcceptedSub;
  StreamSubscription? _iceCandidateSub;
  StreamSubscription? _callEndedSub;

  bool get hasLocalStream => _localStream != null;

  CallService({required this.dataSource});

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  static const _offerConstraints = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
    'optional': []
  };

  Future<MediaStream> _getUserMedia(bool isVideo) async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': isVideo ? {'facingMode': 'user', 'width': 640, 'height': 480} : false,
    });
    _localStream = stream;
    // Set renderer srcObject directly AND emit on stream
    if (localRenderer != null) {
      localRenderer!.srcObject = stream;
    }
    _localStreamCtrl.add(stream);
    return stream;
  }

  Future<RTCPeerConnection> _createPC(String remoteId) async {
    final pc = await createPeerConnection(_iceServers);
    _localStream?.getTracks().forEach((t) => pc.addTrack(t, _localStream!));
    pc.onTrack = (ev) {
      if (ev.streams.isNotEmpty) {
        _remoteStream = ev.streams[0];
        // Set renderer srcObject directly so it's never missed
        if (remoteRenderer != null) {
          remoteRenderer!.srcObject = _remoteStream;
        }
        _remoteStreamCtrl.add(_remoteStream!);
        _remoteConnectedCtrl.add(true);
      }
    };
    pc.onIceCandidate = (c) {
      if (c.candidate != null) {
        dataSource.emitIceCandidate(to: remoteId, candidate: c.toMap());
      }
    };
    return pc;
  }

  Future<void> startCall({
    required String remoteUserId,
    required String remoteName,
    required String localUserId,
    required bool isVideo,
  }) async {
    await _getUserMedia(isVideo);
    _peerConnection = await _createPC(remoteUserId);

    final offer = await _peerConnection!.createOffer(_offerConstraints);
    await _peerConnection!.setLocalDescription(offer);

    dataSource.emitCallUser(
      userToCall: remoteUserId,
      signalData: offer.toMap(),
      from: localUserId,
      name: remoteName,
      callType: isVideo ? 'video' : 'audio',
    );

    _callAcceptedSub = dataSource.callAcceptedStream.listen((signal) async {
      if (signal is Map) {
        final desc = RTCSessionDescription(signal['sdp'], signal['type']);
        await _peerConnection?.setRemoteDescription(desc);
      }
    });

    _listenIce();
    _listenEnd(remoteUserId);
  }

  Future<void> answerCall({
    required String callerId,
    required Map<String, dynamic> offer,
    required bool isVideo,
  }) async {
    await _getUserMedia(isVideo);
    _peerConnection = await _createPC(callerId);

    await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']));
    final answer = await _peerConnection!.createAnswer(_offerConstraints);
    await _peerConnection!.setLocalDescription(answer);

    dataSource.emitAnswerCall(to: callerId, signal: answer.toMap());
    _listenIce();
    _listenEnd(callerId);
  }

  void _listenIce() {
    _iceCandidateSub = dataSource.iceCandidateStream.listen((c) async {
      if (c is Map && c['candidate'] != null) {
        final candidate = RTCIceCandidate(
          c['candidate'],
          c['sdpMid'],
          c['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      }
    });
  }

  void _listenEnd(String remoteId) {
    _callEndedSub = dataSource.callEndedStream.listen((_) {
      if (!_callEndedCtrl.isClosed) _callEndedCtrl.add(null);
      _cleanUp();
    });
  }

  void endCall(String remoteId) {
    if (remoteId.isNotEmpty) {
      dataSource.emitEndCall(remoteId);
    }
    if (!_callEndedCtrl.isClosed) _callEndedCtrl.add(null);
    _cleanUp();
  }

  void _cleanUp() {
    _localStream?.getTracks().forEach((t) => t.stop());
    _peerConnection?.close();
    if (localRenderer != null) localRenderer!.srcObject = null;
    if (remoteRenderer != null) remoteRenderer!.srcObject = null;
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _callAcceptedSub?.cancel();
    _iceCandidateSub?.cancel();
    _callEndedSub?.cancel();
    _callAcceptedSub = null;
    _iceCandidateSub = null;
    _callEndedSub = null;
  }

  void dispose() {
    _cleanUp();
    if (!_localStreamCtrl.isClosed) _localStreamCtrl.close();
    if (!_remoteStreamCtrl.isClosed) _remoteStreamCtrl.close();
    if (!_callEndedCtrl.isClosed) _callEndedCtrl.close();
    if (!_remoteConnectedCtrl.isClosed) _remoteConnectedCtrl.close();
  }
}
