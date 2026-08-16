// lib/data/models/live/live_model.dart

/// Représente une session de live en cours.
class LiveSession {
  final String id;
  final String channelName;
  final String title;
  final String hostId;
  final String hostName;
  final String? hostAvatarUrl;

  const LiveSession({
    required this.id,
    required this.channelName,
    required this.title,
    required this.hostId,
    required this.hostName,
    this.hostAvatarUrl,
  });

  factory LiveSession.fromMap(Map<String, dynamic> map) {
    return LiveSession(
      id: map['id']?.toString() ?? '',
      channelName: map['channel_name']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      hostId: map['host_id']?.toString() ?? '',
      hostName: map['host_name']?.toString() ?? 'Hôte THIX',
      hostAvatarUrl: map['host_avatar_url']?.toString(),
    );
  }
}

/// Un commentaire de chat en direct.
class LiveComment {
  final String userId;
  final String userName;
  final String text;
  final DateTime sentAt;

  LiveComment({
    required this.userId,
    required this.userName,
    required this.text,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  factory LiveComment.fromPayload(Map<String, dynamic> payload) {
    return LiveComment(
      userId: payload['userId']?.toString() ?? '',
      userName: payload['user']?.toString() ?? 'Invité',
      text: payload['text']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toPayload() => {
        'userId': userId,
        'user': userName,
        'text': text,
      };
}

/// Identifiants Agora renvoyés par la fonction Supabase `agora-token`.
class AgoraCredentials {
  final String appId;
  final String token;

  const AgoraCredentials({required this.appId, required this.token});

  factory AgoraCredentials.fromMap(Map<String, dynamic> map) {
    final appId = map['appId'];
    final token = map['token'];
    if (appId == null || token == null || appId is! String || token is! String || appId.isEmpty || token.isEmpty) {
      throw Exception('appId/token manquant ou invalide : $map');
    }
    return AgoraCredentials(appId: appId, token: token);
  }
}

/// Différents états possibles de l'écran de live.
enum LiveScreenStatus { loading, ready, error, permissionDenied }
