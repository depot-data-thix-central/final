// lib/presentation/network/live/live_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/data/models/live/live_model.dart';
import 'package:thix_id/data/services/live/live_service.dart';

/// Contient tout l'état et la logique métier de l'écran de live.
/// Le widget ne fait que lire cet état via Provider et déclencher ses
/// méthodes publiques.
class LiveController extends ChangeNotifier {
  LiveController({
    required this.session,
    required bool initialVideoEnabled,
    required bool initialMicEnabled,
    LiveService? service,
  })  : _isVideoOff = !initialVideoEnabled,
        _isMuted = !initialMicEnabled,
        _service = service ?? LiveService();

  final LiveSession session;
  final LiveService _service;

  RtcEngine? _engine;
  RealtimeChannel? _realtimeChannel;

  LiveScreenStatus _status = LiveScreenStatus.loading;
  String? _errorMessage;

  bool _isMuted;
  bool _isVideoOff;
  bool _isEnding = false;
  bool _isFrontCamera = true;
  bool _isBeautyEnabled = false;

  int _viewerCount = 0;
  final List<int> _coHostUids = [];
  final List<LiveComment> _comments = [];

  // ─── Getters exposés à l'UI ───
  LiveScreenStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isMuted => _isMuted;
  bool get isVideoOff => _isVideoOff;
  bool get isEnding => _isEnding;
  bool get isBeautyEnabled => _isBeautyEnabled;
  int get viewerCount => _viewerCount;
  List<int> get coHostUids => List.unmodifiable(_coHostUids);
  List<LiveComment> get comments => List.unmodifiable(_comments);
  RtcEngine? get engine => _engine;
  String get channelName => session.channelName;

  /// Callback fourni par l'écran pour afficher le dialogue de demande de co-hôte.
  void Function(String userId, String userName)? onCoHostRequest;

  // ─── Cycle de démarrage complet ───
  Future<void> bootstrap() async {
    _status = LiveScreenStatus.loading;
    _errorMessage = null;
    notifyListeners();

    if (!kIsWeb) {
      final statuses = await [Permission.camera, Permission.microphone].request();
      final camOk = statuses[Permission.camera]?.isGranted ?? true;
      final micOk = statuses[Permission.microphone]?.isGranted ?? true;
      if (!camOk || !micOk) {
        _status = LiveScreenStatus.permissionDenied;
        notifyListeners();
        return;
      }
    }

    AgoraCredentials credentials;
    try {
      credentials = await _service.fetchAgoraCredentials(session.channelName);
    } on TimeoutException {
      _fail("Délai dépassé lors de la récupération du token Agora.");
      return;
    } catch (e) {
      _fail(e.toString());
      return;
    }

    try {
      final engine = createAgoraRtcEngine();
      await engine.initialize(RtcEngineContext(
        appId: credentials.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      if (!_isVideoOff) {
        await engine.enableVideo();
        await engine.startPreview();
      }

      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!_coHostUids.contains(remoteUid)) {
              _coHostUids.add(remoteUid);
              notifyListeners();
            }
          },
          onUserOffline: (connection, remoteUid, reason) {
            _coHostUids.remove(remoteUid);
            notifyListeners();
          },
          onError: (err, msg) => debugPrint('Agora onError: $err - $msg'),
        ),
      );

      await engine.joinChannel(
        token: credentials.token,
        channelId: session.channelName,
        uid: 0,
        options: ChannelMediaOptions(
          publishCameraTrack: !_isVideoOff,
          publishMicrophoneTrack: !_isMuted,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      _engine = engine;
      _status = LiveScreenStatus.ready;
      notifyListeners();
      _initRealtime();
    } catch (e) {
      debugPrint('Erreur Agora: $e');
      _fail(e.toString());
    }
  }

  void _fail(String message) {
    _status = LiveScreenStatus.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _initRealtime() {
    _realtimeChannel = _service.openRealtimeChannel(
      liveId: session.id,
      onChat: (comment) {
        _comments.add(comment);
        notifyListeners();
      },
      onHeart: () {
        // L'animation des cœurs reste gérée par l'UI ; on notifie juste.
        _heartController.add(null);
      },
      onCoHostRequest: (userId, userName) => onCoHostRequest?.call(userId, userName),
      onPresenceSync: (count) {
        _viewerCount = count;
        notifyListeners();
      },
    );
  }

  // Flux dédié aux animations de cœur (l'UI s'abonne pour déclencher l'anim).
  final StreamController<void> _heartController = StreamController<void>.broadcast();
  Stream<void> get heartStream => _heartController.stream;

  // ─── Actions ───
  void sendComment(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _realtimeChannel == null) return;

    final comment = LiveComment(
      userId: _service.currentUserId,
      userName: session.hostName,
      text: trimmed,
    );
    _service.sendChatMessage(_realtimeChannel!, comment);
    _comments.add(comment);
    notifyListeners();
  }

  void triggerHeart() => _heartController.add(null);

  void respondToCoHost(String targetUserId, bool accepted) {
    if (_realtimeChannel == null) return;
    _service.respondToCoHost(_realtimeChannel!, targetUserId, accepted);
  }

  Future<void> toggleVideo() async {
    _isVideoOff = !_isVideoOff;
    notifyListeners();
    if (_isVideoOff) {
      await _engine?.disableVideo();
    } else {
      await _engine?.enableVideo();
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _engine?.muteLocalAudioStream(_isMuted);
    notifyListeners();
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
    _isFrontCamera = !_isFrontCamera;
    notifyListeners();
  }

  Future<void> toggleBeauty() async {
    _isBeautyEnabled = !_isBeautyEnabled;
    notifyListeners();
    await _engine?.setBeautyEffectOptions(
      enabled: _isBeautyEnabled,
      options: const BeautyOptions(
        lighteningContrastLevel: LighteningContrastLevel.lighteningContrastNormal,
        lighteningLevel: 0.7,
        smoothnessLevel: 0.5,
        rednessLevel: 0.1,
      ),
    );
  }

  Future<void> endBroadcast() async {
    if (_isEnding) return;
    _isEnding = true;
    notifyListeners();

    try {
      await _service.endLiveSession(session.id);
    } catch (e) {
      debugPrint('Erreur suppression session: $e');
    }
    try {
      await _realtimeChannel?.unsubscribe();
    } catch (e) {
      debugPrint('Erreur unsubscribe: $e');
    }
    try {
      if (_engine != null) {
        await _engine!.leaveChannel();
        await _engine!.release();
      }
    } catch (e) {
      debugPrint('Erreur fermeture Agora: $e');
    }
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _engine?.leaveChannel();
    _engine?.release();
    _heartController.close();
    super.dispose();
  }
}
