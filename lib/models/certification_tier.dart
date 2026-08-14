// lib/models/certification_tier.dart
import 'package:flutter/material.dart';

/// Niveaux de certification THIX (alignés sur l'image produit)
enum CertificationTier {
  standard,   // Bleu  — utilisateurs individuels
  premium,    // Or    — fonctionnalités avancées
  enterprise, // Noir  — organisations
  official,   // Rouge — institutions / officiels
}

extension CertificationTierX on CertificationTier {
  String get value => name; // stocké en DB

  String get labelFr => switch (this) {
        CertificationTier.standard => 'Compte Standard',
        CertificationTier.premium => 'Compte Premium',
        CertificationTier.enterprise => 'Compte Entreprise',
        CertificationTier.official => 'Officiel / Institutions',
      };

  String get shortLabel => switch (this) {
        CertificationTier.standard => 'Standard',
        CertificationTier.premium => 'Premium',
        CertificationTier.enterprise => 'Entreprise',
        CertificationTier.official => 'Officiel',
      };

  String get descriptionFr => switch (this) {
        CertificationTier.standard =>
          'Pour les utilisateurs individuels. Accès aux fonctionnalités de base et à la certification d\'identité.',
        CertificationTier.premium =>
          'Pour ceux qui veulent plus. Fonctionnalités avancées, certification prioritaire et expérience améliorée.',
        CertificationTier.enterprise =>
          'Pour les organisations et entreprises. Gestion d\'équipe, contrôle avancé et solutions sur mesure.',
        CertificationTier.official =>
          'Pour les entités officielles et les institutions de confiance. Niveau d\'accès le plus élevé et certification renforcée.',
      };

  /// Couleur principale du sceau (image)
  Color get badgeColor => switch (this) {
        CertificationTier.standard => const Color(0xFF2563EB), // bleu
        CertificationTier.premium => const Color(0xFFD4A017), // or
        CertificationTier.enterprise => const Color(0xFF111827), // noir
        CertificationTier.official => const Color(0xFFDC2626), // rouge
      };

  IconData get icon => switch (this) {
        CertificationTier.standard => Icons.person_rounded,
        CertificationTier.premium => Icons.workspace_premium_rounded,
        CertificationTier.enterprise => Icons.business_center_rounded,
        CertificationTier.official => Icons.verified_user_rounded,
      };

  int get rank => switch (this) {
        CertificationTier.standard => 1,
        CertificationTier.premium => 2,
        CertificationTier.enterprise => 3,
        CertificationTier.official => 4,
      };

  bool get isAtLeastPremium => rank >= CertificationTier.premium.rank;
  bool get isOrganization =>
      this == CertificationTier.enterprise || this == CertificationTier.official;

  static CertificationTier parse(Object? raw) {
    final v = (raw ?? '').toString().trim().toLowerCase();
    return switch (v) {
      'premium' => CertificationTier.premium,
      'enterprise' || 'entreprise' => CertificationTier.enterprise,
      'official' || 'officiel' || 'institution' => CertificationTier.official,
      _ => CertificationTier.standard,
    };
  }

  /// Prix en USD (null = sur invitation)
  double? get priceUsd => switch (this) {
        CertificationTier.standard => 3.0,
        CertificationTier.premium => 7.0,
        CertificationTier.enterprise => 30.0,
        CertificationTier.official => null,
      };

  bool get isInviteOnly => this == CertificationTier.official;
  bool get isPaid => priceUsd != null;
}

/// Statut de la demande / génération de certification
enum CertificationStatus {
  none,
  pending,
  approved,
  rejected,
  generated, // ex. Premium "GÉNÉRÉ" sur l'image
}

extension CertificationStatusX on CertificationStatus {
  String get value => name;

  String get labelFr => switch (this) {
        CertificationStatus.none => 'Non certifié',
        CertificationStatus.pending => 'En cours',
        CertificationStatus.approved => 'Approuvé',
        CertificationStatus.rejected => 'Rejeté',
        CertificationStatus.generated => 'Généré',
      };

  static CertificationStatus parse(Object? raw) {
    final v = (raw ?? '').toString().trim().toLowerCase();
    return switch (v) {
      'pending' || 'en_cours' => CertificationStatus.pending,
      'approved' || 'approuve' || 'vérifié' || 'verified' => CertificationStatus.approved,
      'rejected' || 'rejete' => CertificationStatus.rejected,
      'generated' || 'genere' => CertificationStatus.generated,
      _ => CertificationStatus.none,
    };
  }
}
