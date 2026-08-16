// lib/presentation/network/live/live_prep_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'live_broadcast_screen.dart';

class _C {
  static const primary = Color(0xFF2D6CDF);
  static const red = Color(0xFFE5484D);
  static const bgDark = Color(0xFF10192E);
}

class LivePrepScreen extends StatefulWidget {
  const LivePrepScreen({super.key});

  @override
  State<LivePrepScreen> createState() => _LivePrepScreenState();
}

class _LivePrepScreenState extends State<LivePrepScreen> {
  final TextEditingController _titleController = TextEditingController();
  bool _isVideoEnabled = true;
  bool _isMicEnabled = true;

  RtcEngine? _engine;
  bool _isEngineReady = false;
  bool _isStartingLive = false; 

  @override
  void initState() {
    super.initState();
    // 🌟 Au lieu d'initialiser Agora direct, on vérifie les permissions en premier
    _checkPermissionsAndInit();
  }

  // =========================================================
  // 1. NOUVELLE FONCTION : GESTION DES PERMISSIONS (UX / PLAY STORE)
  // =========================================================
  Future<void> _checkPermissionsAndInit() async {
    if (kIsWeb) {
      await _initPreviewAgora();
      return;
    }

    var cameraStatus = await Permission.camera.status;
    var micStatus = await Permission.microphone.status;

    // Si les permissions ne sont pas encore accordées
    if (cameraStatus.isDenied || micStatus.isDenied) {
      if (!mounted) return;

      // 🚨 Affichage de l'explication (Prominent Disclosure pour Google)
      bool? userAgreed = await showDialog<bool>(
        context: context,
        barrierDismissible: false, // Force l'utilisateur à répondre
        builder: (context) => AlertDialog(
          backgroundColor: _C.bgDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.white12, width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.privacy_tip_rounded, color: _C.red, size: 28),
              SizedBox(width: 10),
              Text(
                "Autorisations",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "Pour démarrer votre direct sur THIX Media, l'application a besoin d'accéder à votre caméra et votre microphone. \n\nCes accès sont utilisés uniquement pendant la diffusion.",
            style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Refus
              child: const Text("Annuler", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _C.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context, true), // Acceptation
              child: const Text("Compris", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

      // Si l'utilisateur clique sur "Annuler", on le ramène à l'écran précédent
      if (userAgreed != true) {
        if (mounted) Navigator.pop(context);
        return;
      }

      // Si "Compris", on lance la vraie demande système Android/iOS
      Map<Permission, PermissionStatus> statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      // Vérification finale
      if (statuses[Permission.camera]!.isGranted && statuses[Permission.microphone]!.isGranted) {
        await _initPreviewAgora();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissions refusées. Impossible de lancer le direct.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    } else {
      // Si on a déjà les permissions (ex: 2ème ouverture de l'écran)
      await _initPreviewAgora();
    }
  }

  // =========================================================
  // 2. INITIALISATION AGORA (Allégée de la demande de permission)
  // =========================================================
  Future<void> _initPreviewAgora() async {
    try {
      String appId = "96ed392d17c74fe684bbb9d4a031ad12"; // Pensez à utiliser .env en production !

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      await _engine!.enableVideo();
      await _engine!.startPreview();

      if (mounted) setState(() => _isEngineReady = true);
      
    } catch (e) {
      debugPrint('Erreur init preview Agora: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur Caméra : $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  Future<void> _startLive() async {
    if (_isStartingLive) return;

    final title = _titleController.text.trim().isEmpty 
        ? "Mon Direct" 
        : _titleController.text.trim();

    setState(() => _isStartingLive = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Vous devez être connecté");

      final channelName = 'live_${user.id}_${DateTime.now().millisecondsSinceEpoch}';

      final response = await Supabase.instance.client
          .from('live_sessions')
          .insert({
            'host_id': user.id,
            'title': title,
            'channel_name': channelName, 
            'status': 'live',
          })
          .select()
          .single();

      final liveId = response['id'].toString();

      if (_isEngineReady && _engine != null) {
        await _engine!.stopPreview();
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LiveBroadcastScreen(
            isVideoEnabled: _isVideoEnabled,
            isMicEnabled: _isMicEnabled,
            liveId: liveId,           
            channelName: channelName, 
          ),
        ),
      );
    } catch (e) {
      debugPrint('Erreur création live: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de connexion : $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingLive = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    if (_isEngineReady && _engine != null) {
      _engine!.release();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bgDark,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _isEngineReady && _isVideoEnabled && _engine != null
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1E293B),
                    child: const Center(
                      child: Icon(Icons.videocam_off_rounded, color: Colors.white24, size: 80),
                    ),
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "De quoi allez-vous parler ?",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 24),
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRoundBtn(
                        icon: _isMicEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                        isActive: _isMicEnabled,
                        onTap: () {
                          setState(() => _isMicEnabled = !_isMicEnabled);
                          if (_isEngineReady && _engine != null) {
                            _engine!.muteLocalAudioStream(!_isMicEnabled);
                          }
                        },
                      ),
                      const SizedBox(width: 24),
                      _buildRoundBtn(
                        icon: _isVideoEnabled ? Icons.videocam_rounded : Icons.videocam_off_rounded,
                        isActive: _isVideoEnabled,
                        onTap: () {
                          setState(() => _isVideoEnabled = !_isVideoEnabled);
                          if (_isEngineReady && _engine != null) {
                            if (_isVideoEnabled) {
                              _engine!.enableVideo();
                              _engine!.startPreview();
                            } else {
                              _engine!.disableVideo();
                            }
                          }
                        },
                      ),
                      const SizedBox(width: 24),
                      _buildRoundBtn(
                        icon: Icons.flip_camera_ios_rounded,
                        isActive: true,
                        onTap: () {
                          if (_isEngineReady && _engine != null) {
                            _engine!.switchCamera();
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isStartingLive ? null : _startLive,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isStartingLive ? Colors.grey : _C.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
                        shadowColor: _C.red.withOpacity(0.5),
                      ),
                      child: _isStartingLive 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.sensors_rounded, color: Colors.white),
                              SizedBox(width: 10),
                              Text(
                                'COMMENCER LE DIRECT',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                              ),
                            ],
                          ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundBtn({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.2) : Colors.red.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white54, width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
