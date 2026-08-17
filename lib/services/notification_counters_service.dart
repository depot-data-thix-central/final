// lib/services/notification_counters_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/models/notification/notification_module.dart';
import 'package:thix_id/supabase/supabase_config.dart';

/// Calcule et diffuse en temps réel les compteurs de notifications non
/// lues, globalement et par module (badges affichés sur chaque bulle
/// du hub d'accueil : THIX CHAT, THIX MONEY, THIX SANTÉ, etc.).
class NotificationCountersService {
  final SupabaseClient _client;
  NotificationCountersService({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  static const String _table = 'notifications';

  /// Flux du nombre total de notifications non lues pour l'utilisateur.
  Stream<int> streamTotalUnread(String uid) {
    return _streamUnreadRows(uid).map((rows) => rows.length);
  }

  /// Flux d'une map { module: compteur non lu } pour tous les modules
  /// définis dans [NotificationModule]. Les modules sans notification
  /// non lue ont un compteur de 0 (jamais absents de la map).
  Stream<Map<NotificationModule, int>> streamCountersByModule(String uid) {
    return _streamUnreadRows(uid).map((rows) {
      final counts = <NotificationModule, int>{
        for (final m in NotificationModule.values) m: 0,
      };

      for (final row in rows) {
        final type = (row['type'] ?? '').toString();
        final module = _moduleForType(type);
        counts[module] = (counts[module] ?? 0) + 1;
      }

      return counts;
    });
  }

  /// Flux du compteur non lu pour UN SEUL module — pratique pour un
  /// widget de badge isolé qui ne veut pas écouter toute la map.
  Stream<int> streamCounterForModule(String uid, NotificationModule module) {
    return streamCountersByModule(uid).map((counts) => counts[module] ?? 0);
  }

  /// Récupère les compteurs une seule fois (non réactif), utile pour un
  /// affichage ponctuel ou un rafraîchissement manuel (pull-to-refresh).
  Future<Map<NotificationModule, int>> fetchCountersByModule(String uid) async {
    try {
      final rows = await _client
          .from(_table)
          .select('type')
          .eq('user_id', uid)
          .eq('is_read', false);

      final counts = <NotificationModule, int>{
        for (final m in NotificationModule.values) m: 0,
      };

      for (final row in rows) {
        final type = (row['type'] ?? '').toString();
        final module = _moduleForType(type);
        counts[module] = (counts[module] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      debugPrint('NotificationCountersService: fetchCountersByModule failed err=$e');
      return {for (final m in NotificationModule.values) m: 0};
    }
  }

  /// Marque comme lues toutes les notifications d'un module donné —
  /// utile quand l'utilisateur ouvre l'écran correspondant (ex: ouvrir
  /// THIX CHAT marque toutes les notifs de chat comme lues).
  Future<void> markModuleRead(String uid, NotificationModule module) async {
    try {
      await _client
          .from(_table)
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false)
          .inFilter('type', module.typeKeys);
    } catch (e) {
      debugPrint('NotificationCountersService: markModuleRead failed module=$module err=$e');
    }
  }

  NotificationModule _moduleForType(String type) {
    for (final module in NotificationModule.values) {
      if (module.typeKeys.contains(type)) return module;
    }
    return NotificationModule.generic;
  }

  // ─── Flux bas niveau : lignes non lues, avec fallback polling ────────

  Stream<List<Map<String, dynamic>>> _streamUnreadRows(String uid) {
    late final StreamController<List<Map<String, dynamic>>> controller;
    RealtimeChannel? channel;
    var closedRetries = 0;
    Timer? retryTimer;
    var isCancelled = false;
    Timer? pollTimer;
    var polling = false;

    Future<void> emitLatest() async {
      try {
        final rows = await _client
            .from(_table)
            .select('type')
            .eq('user_id', uid)
            .eq('is_read', false);
        controller.add(rows);
      } catch (e) {
        debugPrint('NotificationCountersService: emitLatest failed uid=$uid err=$e');
        controller.add(const <Map<String, dynamic>>[]);
      }
    }

    void startPolling() {
      if (polling) return;
      polling = true;
      pollTimer?.cancel();
      pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(emitLatest()));
    }

    controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () => unawaited(emitLatest()),
    );

    Future<void> subscribeOrRetry() async {
      if (isCancelled || polling) return;
      retryTimer?.cancel();

      try {
        if (channel != null) await _client.removeChannel(channel!);
      } catch (_) {}

      channel = _client.channel('notification_counters:$uid');
      try {
        channel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: _table,
              filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
              callback: (payload) => unawaited(emitLatest()),
            )
            .subscribe((status, [err]) {
              if (isCancelled) return;

              if (status == RealtimeSubscribeStatus.channelError) {
                startPolling();
                return;
              }

              final shouldRetry = err != null || status == RealtimeSubscribeStatus.closed;
              if (!shouldRetry) {
                closedRetries = 0;
                return;
              }

              closedRetries = (closedRetries + 1).clamp(1, 10);
              final delayMs = (500 * (1 << (closedRetries - 1))).clamp(500, 8000);
              retryTimer?.cancel();
              retryTimer = Timer(Duration(milliseconds: delayMs), () {
                unawaited(subscribeOrRetry());
              });
            });
      } catch (e) {
        debugPrint('NotificationCountersService: realtime wiring failed, fallback polling. err=$e');
        startPolling();
      }
    }

    unawaited(subscribeOrRetry());

    controller.onCancel = () async {
      isCancelled = true;
      retryTimer?.cancel();
      pollTimer?.cancel();
      final ch = channel;
      if (ch != null) await _client.removeChannel(ch);
    };

    return controller.stream;
  }
}
