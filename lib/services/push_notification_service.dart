// lib/services/push_notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/local_notification_service.dart';
import 'package:thix_id/supabase/supabase_config.dart';

/// Handler de messages FCM reçus quand l'app est en arrière-plan ou fermée.
/// DOIT être une fonction top-level (pas une méthode de classe) et annotée
/// @pragma('vm:entry-point') pour fonctionner en isolate séparé.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM background message: ${message.messageId}');
  // Pas besoin d'afficher de notification ici : FCM affiche automatiquement
  // la notification système quand le payload contient un bloc "notification"
  // et que l'app est en arrière-plan/fermée.
}

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static const String _tokensTable = 'user_device_tokens';

  Future<void> initialize() async {
    // Permission (iOS surtout ; sur Android c'est LocalNotificationService
    // qui gère la permission Android 13+, FCM ne redemande pas).
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('PushNotificationService: permission=${settings.authorizationStatus}');

    // Token initial + écoute du renouvellement (rotation périodique par FCM)
    await _registerToken();
    _messaging.onTokenRefresh.listen((_) => _registerToken());

    // Message reçu app AU PREMIER PLAN : FCM n'affiche rien automatiquement,
    // on utilise LocalNotificationService pour le pop.
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // L'utilisateur tape sur une notification qui a ouvert l'app depuis
    // l'arrière-plan
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // L'app a été ouverte DIRECTEMENT depuis une notification (était fermée)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    LocalNotificationService.instance.show(
      id: message.hashCode,
      title: notification.title ?? 'THIX ID',
      body: notification.body ?? '',
      payload: message.data['route'] ?? message.data['notification_id'],
    );
  }

  void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    debugPrint('PushNotificationService: notification tap → route=$route');
    // Le routage effectif se fait via LocalNotificationService.onNotificationTap
    // ou un callback global que main.dart branche sur GoRouter.
    LocalNotificationService.instance.onNotificationTap?.call(route);
  }

  /// Enregistre le token FCM de l'appareil courant, lié à l'utilisateur
  /// connecté, dans Supabase — pour que le backend puisse cibler cet
  /// appareil lors de l'envoi d'un push.
  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      final uid = SupabaseConfig.currentUser?.id;
      if (token == null || uid == null) return;

      await SupabaseConfig.client.from(_tokensTable).upsert(
        {
          'user_id': uid,
          'fcm_token': token,
          'platform': defaultTargetPlatform.name,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
      debugPrint('PushNotificationService: token enregistré uid=$uid');
    } catch (e) {
      debugPrint('PushNotificationService: registerToken failed err=$e');
    }
  }

  /// Supprime le token de cet appareil (à appeler à la déconnexion, pour
  /// éviter d'envoyer des push à un utilisateur qui s'est déconnecté sur
  /// cet appareil).
  Future<void> unregisterToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await SupabaseConfig.client.from(_tokensTable).delete().eq('fcm_token', token);
    } catch (e) {
      debugPrint('PushNotificationService: unregisterToken failed err=$e');
    }
  }
}
