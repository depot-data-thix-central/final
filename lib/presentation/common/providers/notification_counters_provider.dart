// lib/presentation/common/providers/notification_counters_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:thix_id/models/notification/notification_module.dart';
import 'package:thix_id/services/notification_counters_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';

part 'notification_counters_provider.g.dart';

@riverpod
NotificationCountersService notificationCountersService(NotificationCountersServiceRef ref) =>
    NotificationCountersService();

@riverpod
Stream<Map<NotificationModule, int>> moduleNotificationCounters(ModuleNotificationCountersRef ref) {
  final uid = SupabaseConfig.currentUser?.id;
  if (uid == null) return Stream.value({for (final m in NotificationModule.values) m: 0});

  final service = ref.watch(notificationCountersServiceProvider);
  return service.streamCountersByModule(uid);
}
