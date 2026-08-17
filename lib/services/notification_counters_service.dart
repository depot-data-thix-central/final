// lib/services/notification_counters_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/supabase/supabase_config.dart';

/// Compteurs de notifications non lues, un champ par section de la
/// constellation d'accueil. Les noms correspondent exactement aux
/// champs lus par HomeServicesConstellation (c.media, c.info, ...).
class SectionBadgeCounts {
  final int media;
  final int info;
  final int events;
  final int money;
  final int market;
  final int reservation;
  final int jobs;
  final int formations;
  final int opportunities;
  final int network;
  final int health;
  final int monPays;
  final int chat;

  const SectionBadgeCounts({
    this.media = 0,
    this.info = 0,
    this.events = 0,
    this.money = 0,
    this.market = 0,
    this.reservation = 0,
    this.jobs = 0,
    this.formations = 0,
    this.opportunities = 0,
    this.network = 0,
    this.health = 0,
    this.monPays = 0,
    this.chat = 0,
  });

  static const zero = SectionBadgeCounts();

  int get total =>
      media + info + events + money + market + reservation + jobs +
      formations + opportunities + network + health + monPays + chat;
}

/// Calcule et diffuse en temps réel les compteurs de notifications non
/// lues par section, pour alimenter les badges de la constellation
/// d'accueil et la cloche de notifications.
class NotificationCountersService {
  final SupabaseClient _client;
  NotificationCountersService({SupabaseClient? client}) : _client = client ?? SupabaseConfig.client;

  static const String _table = 'notifications';

  /// Mapping type (colonne `notifications.type`) → section de la
  /// constellation. Étendre cette map au fur et à mesure que chaque
  /// module commence à créer des notifications avec de nouveaux types.
  static const Map<String, String> _typeToSection = {
    // Contenu & Médias
    'media': 'media',
    'tdia': 'media',
    'thix_media': 'media',
    'info': 'info',
    'thix_info': 'info',
    'news': 'info',
    'event': 'events',
    'evenement': 'events',

    // Économie & Transactions
    'money': 'money',
    'payment': 'money',
    'thix_money': 'money',
    'market': 'market',
    'order': 'market',
    'shop': 'market',
    'reservation': 'reservation',
    'booking': 'reservation',

    // Carrière, Éducation & Réseau
    'job': 'jobs',
    'emploi': 'jobs',
    'formation': 'formations',
    'course': 'formations',
    'certificate': 'formations',
    'opportunity': 'opportunities',

    // THIX PRO (réseau) — types réellement en base aujourd'hui
    'like': 'network',
    'follow': 'network',
    'connection': 'network',
    'comment': 'network',
    'post': 'network',
    'mention': 'network',

    // Vie pratique & gouvernement
    'health': 'health',
    'thix_sante': 'health',
    'country': 'monPays',
    'mon_pays': 'monPays',
    'civic': 'monPays',

    // THIX CHAT
    'chat': 'chat',
    'message': 'chat',
  };

  /// Flux réactif des compteurs par section pour l'utilisateur connecté.
  Stream<SectionBadgeCounts> streamSectionBadgeCounts(String uid) {
    return _streamUnreadTypes(uid).map(_buildCounts);
  }

  /// Récupération ponctuelle (non réactive), utile pour un pull-to-refresh.
  Future<SectionBadgeCounts> fetchSectionBadgeCounts(String uid) async {
    try {
      final rows = await _client
          .from(_table)
          .select('type')
          .eq('user_id', uid)
          .eq('is_read', false);
      return _buildCounts(rows.map((r) => (r['type'] ?? '').toString()).toList());
    } catch (e) {
      debugPrint('NotificationCountersService: fetchSectionBadgeCounts failed err=$e');
      return SectionBadgeCounts.zero;
    }
  }

  SectionBadgeCounts _buildCounts(List<String> types) {
    final tally = <String, int>{};
    for (final type in types) {
      final section = _typeToSection[type];
      if (section == null) continue;
      tally[section] = (tally[section] ?? 0) + 1;
    }

    return SectionBadgeCounts(
      media: tally['media'] ?? 0,
      info: tally['info'] ?? 0,
      events: tally['events'] ?? 0,
      money: tally['money'] ?? 0,
      market: tally['market'] ?? 0,
      reservation: tally['reservation'] ?? 0,
      jobs: tally['jobs'] ?? 0,
      formations: tally['formations'] ?? 0,
      opportunities: tally['opportunities'] ?? 0,
      network: tally['network'] ?? 0,
      health: tally['health'] ?? 0,
      monPays: tally['monPays'] ?? 0,
      chat: tally['chat'] ?? 0,
    );
  }

  /// Marque comme lues toutes les notifications d'une section donnée —
  /// appeler quand l'utilisateur ouvre l'écran correspondant.
  Future<void> markSectionRead(String uid, String sectionKey) async {
    final types = _typeToSection.entries
        .where((e) => e.value == sectionKey)
        .map((e) => e.key)
        .toList();
    if (types.isEmpty) return;

    try {
      await _client
          .from(_table)
          .update({'is_read': true})
          .eq('user_id', uid)
          .eq('is_read', false)
          .inFilter('type', types);
    } catch (e) {
      debugPrint('NotificationCountersService: markSectionRead failed section=$sectionKey err=$e');
    }
  }

  // ─── Flux bas niveau : types non lus, avec fallback polling ──────────

  Stream<List<String>> _streamUnreadTypes(String uid) {
    late final StreamController<List<String>> controller;
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
        controller.add(rows.map((r) => (r['type'] ?? '').toString()).toList());
      } catch (e) {
        debugPrint('NotificationCountersService: emitLatest failed uid=$uid err=$e');
        controller.add(const <String>[]);
      }
    }

    void startPolling() {
      if (polling) return;
      polling = true;
      pollTimer?.cancel();
      pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => unawaited(emitLatest()));
    }

    controller = StreamController<List<String>>.broadcast(
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
