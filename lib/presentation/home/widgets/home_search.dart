// lib/presentation/home/widgets/home_search.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // 🌟 Ajout pour la navigation
import 'package:thix_id/l10n/app_localizations.dart';
import 'package:thix_id/core/theme/thix_design_policy.dart';

class HomeSearch extends StatelessWidget {
  final TextEditingController controller;
  final bool isSearching;
  final VoidCallback onVerify;
  
  // 🌟 Optionnel : Tu pourras passer cette variable à false si l'utilisateur n'est pas encore vérifié
  final bool isUserVerified; 

  const HomeSearch({
    super.key,
    required this.controller,
    required this.isSearching,
    required this.onVerify,
    this.isUserVerified = true, // Par défaut à true
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Container(
      height: ThixPolicy.searchBarHeight, // Utilise la policy ! (48)
      padding: const EdgeInsets.only(left: ThixPolicy.s16, right: ThixPolicy.s6),
      decoration: BoxDecoration(
        color: ThixPolicy.card,
        borderRadius: BorderRadius.circular(ThixPolicy.rXl),
        boxShadow: ThixPolicy.shadowSoft(),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, size: 20, color: ThixPolicy.textSecondary),
          const SizedBox(width: ThixPolicy.s8),
          
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isSearching,
              textAlignVertical: TextAlignVertical.center,
              style: ThixPolicy.bodyMediumStyle,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                hintText: 'THIX ID...',
                hintStyle: ThixPolicy.bodySmallStyle,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          
          // 🌟 NOUVEAU : Icône "Compte Vérifié"
          if (isUserVerified) ...[
            Tooltip(
              message: 'Votre compte est vérifié',
              child: Icon(Icons.verified_rounded, color: ThixPolicy.primary, size: 20),
            ),
            const SizedBox(width: ThixPolicy.s8),
          ],

          // 🌟 NOUVEAU : Bouton Scanner QR Code (Parrainage)
          GestureDetector(
            onTap: () {
              // Ouvre l'écran du scanner QR pour le parrainage
              // Adapte le nom de la route si elle s'appelle autrement dans ton fichier router.dart
              context.push('/network/scanner_activation'); 
            },
            child: Container(
              height: 34,
              width: 34,
              decoration: BoxDecoration(
                color: ThixPolicy.surface,
                shape: BoxShape.circle,
                border: Border.all(color: ThixPolicy.border),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.qr_code_scanner_rounded, color: ThixPolicy.textMain, size: 18),
            ),
          ),
          
          const SizedBox(width: ThixPolicy.s8),
          
          // Bouton "Vérifier" (Existant)
          GestureDetector(
            onTap: isSearching ? null : onVerify,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: ThixPolicy.s16),
              decoration: BoxDecoration(
                gradient: ThixPolicy.brandGradient,
                borderRadius: BorderRadius.circular(ThixPolicy.rMd),
              ),
              alignment: Alignment.center,
              child: Text(
                l10n.t('home_verify_btn'),
                style: const TextStyle(color: ThixPolicy.onBrand, fontWeight: ThixPolicy.bold, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
