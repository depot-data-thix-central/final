// lib/services/local_notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String _channelId = 'thix_id_high_importance';
  static const String _channelName = 'THIX ID Notifications';
  static const String _channelDescription = 'Notifications importantes de THIX ID';

  /// Callback appelé quand l'utilisateur tape sur une notification.
  void Function(String? payload)? onNotificationTap;

  /// Alias pour compatibilité avec le code existant qui appelle `init()`
  /// au lieu de `initialize()`.
  Future<void> init() => initialize();

  Future<void> initialize() async {
    // 1. Protection Web : on évite d'exécuter du code natif sur navigateur
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // On demandera la permission plus tard
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('🔔 Clic notification -> payload: ${response.payload}');
        onNotificationTap?.call(response.payload);
      },
    );

    // 2. Canal Android obligatoire (API 26+)
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    _initialized = true;
    debugPrint('LocalNotificationService: initialisé');
  }

  /// Demande la permission d'affichage des notifications.
  Future<bool> requestPermission() async {
    if (kIsWeb) return true; // Le web n'utilise pas permission_handler

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    return true;
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // 3. Sur le Web, on simule l'affichage discrètement dans la console
    if (kIsWeb) {
      debugPrint('🔔 [Web Notification] $title: $body');
      return;
    }

    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.show(id, title, body, details, payload: payload);
    } catch (e) {
      debugPrint('LocalNotificationService: show failed err=$e');
    }
  }

  Future<void> cancel(int id) async {
    if (!kIsWeb) await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!kIsWeb) await _plugin.cancelAll();
  }
}
