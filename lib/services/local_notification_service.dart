// lib/services/push_notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/services/local_notification_service.dart'; // Pour afficher la pop-up

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Demander la permission (surtout pour iOS et Web)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permission FCM accordée');
    }

    // 2. Écoute des messages quand l'application est ouverte (Foreground)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // 3. Clic sur une notification quand l'app est en arrière-plan (Background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Gère l'affichage d'une pop-up locale quand l'app est déjà ouverte
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Message reçu en premier plan : ${message.notification?.title}');
    
    if (message.notification != null) {
      // On utilise le service local pour forcer l'affichage visuel
      LocalNotificationService.instance.show(
        id: message.hashCode, 
        title: message.notification!.title ?? 'THIX ID',
        body: message.notification!.body ?? '',
        // On passe les datas (ex: la route) pour la navigation au clic
        payload: message.data['route'], 
      );
    }
  }

  /// Gère le clic sur la notification
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification cliquée avec les données : ${message.data}');
    // Le clic est intercepté ici. Si tu as mis une 'route' dans ton payload FCM, 
    // tu pourras rediriger l'utilisateur avec GoRouter plus tard.
  }

  /// Appelée par ton AuthManager quand l'utilisateur se connecte avec succès
  Future<void> onSignedIn({required String userId}) async {
    try {
      // 1. Récupérer le token unique de ce téléphone/navigateur
      String? token = await _messaging.getToken();
      
      if (token != null) {
        debugPrint('FCM Token généré: $token');
        
        // 2. Sauvegarder ce token dans Supabase pour ce user précis
        // (On utilise 'upsert' pour le mettre à jour s'il existe déjà)
        await Supabase.instance.client.from('fcm_tokens').upsert({
          'user_id': userId,
          'token': token,
          'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde du token FCM : $e');
    }
  }

  /// Appelée par ton AuthManager quand l'utilisateur se déconnecte
  Future<void> onSignedOut() async {
    try {
      // 1. Récupérer le token actuel pour le supprimer de Supabase
      String? token = await _messaging.getToken();
      
      if (token != null) {
        await Supabase.instance.client
            .from('fcm_tokens')
            .delete()
            .eq('token', token);
      }
      
      // 2. Supprimer le token de l'appareil localement
      await _messaging.deleteToken();
      debugPrint('Token FCM supprimé de Supabase et de l\'appareil');
    } catch (e) {
      debugPrint('Erreur lors de la suppression du token FCM : $e');
    }
  }
}
