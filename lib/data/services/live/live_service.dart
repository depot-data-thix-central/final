// lib/data/services/live/live_service.dart
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/data/models/live/live_model.dart';

/// Centralise tous les accès Supabase (token Agora, fin de session, realtime)
/// pour le module Live. Ne contient aucune logique UI.
class LiveService {
  final SupabaseClient _client = Supabase.instance.client;

  String get currentUserId => _client.auth.currentUser?.id ?? 'host';

  /// Récupère le couple appId/token Agora via l'Edge Function `agora-token`.
  Future<AgoraCredentials> fetchAgoraCredentials(String channelName) async {
    final response = await _client.functions
        .invoke('agora-token', body: {'channel': channelName, 'uid': 0})
        .timeout(const Duration(seconds: 12));

    if (response.data == null || response.data is! Map) {
      throw Exception('Réponse invalide de la fonction agora-token');
    }
    return AgoraCredentials.fromMap(response.data as Map<String, dynamic>);
  }

  /// Supprime la session de live côté base de données (fin du direct).
  Future<void> endLiveSession(String liveId) async {
    await _client.from('live_sessions').delete().eq('id', liveId);
  }

  /// Ouvre le canal Supabase Realtime pour un live donné.
  /// Les callbacks sont fournis par le controller, ce service ne fait
  /// que le branchement.
  RealtimeChannel openRealtimeChannel({
    required String liveId,
    required void Function(LiveComment comment) onChat,
    required void Function() onHeart,
    required void Function(String userId, String userName) onCoHostRequest,
    required void Function(int viewerCount) onPresenceSync,
    void Function(RealtimeSubscribeStatus status)? onSubscribed,
  }) {
    final channel = _client.channel('live_$liveId');

    channel
        .onBroadcast(
          event: 'chat',
          callback: (payload) => onChat(LiveComment.fromPayload(payload)),
        )
        .onBroadcast(event: 'heart', callback: (_) => onHeart())
        .onBroadcast(
          event: 'cohost_request',
          callback: (payload) => onCoHostRequest(
            payload['userId']?.toString() ?? '',
            payload['userName']?.toString() ?? '',
          ),
        )
        .onPresenceSync((_) {
          final state = channel.presenceState();
          final count = state.length;
          onPresenceSync(count > 0 ? count - 1 : 0);
        })
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            channel.track({'user_id': currentUserId, 'is_host': true});
          }
          onSubscribed?.call(status);
        });

    return channel;
  }

  void sendChatMessage(RealtimeChannel channel, LiveComment comment) {
    channel.sendBroadcastMessage(event: 'chat', payload: comment.toPayload());
  }

  void respondToCoHost(RealtimeChannel channel, String targetUserId, bool accepted) {
    channel.sendBroadcastMessage(
      event: 'cohost_response',
      payload: {'targetUserId': targetUserId, 'accepted': accepted},
    );
  }
}
