// lib/presentation/network/live/live_controller.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/data/models/live/live_model.dart';
import 'package:thix_id/data/services/live/live_service.dart';

part 'live_controller.g.dart';

/// Notifier Riverpod pour un live donné, identifié par sa [LiveSession].
/// Family car chaque live a son propre état (potentiellement plusieurs
/// écrans instanciés dans une session de navigation).
@riverpod
class LiveController extends _$LiveController {
  RtcEngine? _engine;
  RealtimeChannel? _realtimeChannel;
  final StreamController<void> _heartController = StreamController<void>.broadcast();
  void Function(String userId, String userName)? onCoHostRequest;

  RtcEngine? get engine => _engine;
  Stream<void> get heartStream => _heartController.stream;

  @override
  LiveState build(LiveSession session) {
    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _engine?.leaveChannel();
      _engine?.release();
      _heartController.close();
    });
    // Démarrage automatique dès la création du provider.
    Future.microtask(bootstrap);
    return const LiveState();
  }

  LiveService get _service => ref.read(liveServiceProvider);

  Future<void> bootstrap({
    bool initialVideoEnabled = true,
    bool initialMicEnabled = true,
  }) async {
    state = state.copyWith(
      status: LiveScreenStatus.loading,
      errorMessage: null,
      isVideoOff: !initialVideoEnabled,
      isMuted: !initialMicEnabled,
    );

    if (!kIsWeb) {
      final statuses = await [Permission.camera, Permission.microphone].request();
      final camOk = statuses[Permission.camera]?.isGranted ?? true;
      final micOk = statuses[Permission.microphone]?.isGranted ?? true;
      if (!camOk || !micOk) {
        state = state.copyWith(status: LiveScreenStatus.permissionDenied);
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

      if (!state.isVideoOff) {
        await engine.enableVideo();
        await engine.startPreview();
      }

      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onUserJoined: (connection, remoteUid, elapsed) {
            if (!state.coHostUids.contains(remoteUid)) {
              state = state.copyWith(coHostUids: [...state.coHostUids, remoteUid]);
            }
          },
          onUserOffline: (connection, remoteUid, reason) {
            state = state.copyWith(
              coHostUids: state.coHostUids.where((id) => id != remoteUid).toList(),
            );
          },
          onError: (err, msg) => debugPrint('Agora onError: $err - $msg'),
        ),
      );

      await engine.joinChannel(
        token: credentials.token,
        channelId: session.channelName,
        uid: 0,
        options: ChannelMediaOptions(
          publishCameraTrack: !state.isVideoOff,
          publishMicrophoneTrack: !state.isMuted,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      _engine = engine;
      state = state.copyWith(status: LiveScreenStatus.ready);
      _initRealtime();
    } catch (e) {
      debugPrint('Erreur Agora: $e');
      _fail(e.toString());
    }
  }

  void _fail(String message) {
    state = state.copyWith(status: LiveScreenStatus.error, errorMessage: message);
  }

  void _initRealtime() {
    _realtimeChannel = _service.openRealtimeChannel(
      liveId: session.id,
      onChat: (comment) {
        state = state.copyWith(comments: [...state.comments, comment]);
      },
      onHeart: () => _heartController.add(null),
      onCoHostRequest: (userId, userName) => onCoHostRequest?.call(userId, userName),
      onPresenceSync: (count) {
        state = state.copyWith(viewerCount: count);
      },
    );
  }

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
    state = state.copyWith(comments: [...state.comments, comment]);
  }

  void triggerHeart() => _heartController.add(null);

  void respondToCoHost(String targetUserId, bool accepted) {
    if (_realtimeChannel == null) return;
    _service.respondToCoHost(_realtimeChannel!, targetUserId, accepted);
  }

  Future<void> toggleVideo() async {
    state = state.copyWith(isVideoOff: !state.isVideoOff);
    if (state.isVideoOff) {
      await _engine?.disableVideo();
    } else {
      await _engine?.enableVideo();
    }
  }

  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
    _engine?.muteLocalAudioStream(state.isMuted);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  Future<void> toggleBeauty() async {
    state = state.copyWith(isBeautyEnabled: !state.isBeautyEnabled);
    await _engine?.setBeautyEffectOptions(
      enabled: state.isBeautyEnabled,
      options: const BeautyOptions(
        lighteningContrastLevel: LighteningContrastLevel.lighteningContrastNormal,
        lighteningLevel: 0.7,
        smoothnessLevel: 0.5,
        rednessLevel: 0.1,
      ),
    );
  }

  Future<void> endBroadcast() async {
    if (state.isEnding) return;
    state = state.copyWith(isEnding: true);

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
}
