import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thix_id/core/theme/thix_design_policy.dart'; // Ton design system

class ScannerActivationScreen extends StatefulWidget {
  const ScannerActivationScreen({super.key});

  @override
  State<ScannerActivationScreen> createState() => _ScannerActivationScreenState();
}

class _ScannerActivationScreenState extends State<ScannerActivationScreen> {
  bool _isProcessing = false;
  final MobileScannerController _cameraController = MobileScannerController();

  Future<void> _processToken(String token) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final currentUserId = Supabase.instance.client.auth.currentUser!.id;
      
      // Appel de la fonction sécurisée Supabase pour valider le nouveau
      await Supabase.instance.client.rpc(
        'peer_activate_account',
        params: {
          'p_token': token,
          'p_scanner_id': currentUserId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte de votre filleul activé avec succès !'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Retour à l'accueil
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
        );
        setState(() => _isProcessing = false);
        // On relance la caméra après une erreur
        _cameraController.start(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un Parrainage', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final rawValue = barcode.rawValue;
                if (rawValue != null && rawValue.startsWith('thix_activation_')) {
                  _cameraController.stop(); // Met pause pendant le traitement
                  _processToken(rawValue);
                  break;
                }
              }
            },
          ),
          
          // Décoration pour viser
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Text(
              'Pointez l\'appareil vers le QR Code\ndu nouveau membre',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)]),
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Activation en cours...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
