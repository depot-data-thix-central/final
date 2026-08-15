// lib/presentation/certification/certification_tiers_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:thix_id/core/theme/thix_design_policy.dart';
import 'package:thix_id/models/certification_tier.dart';
import 'package:thix_id/presentation/certification/certification_checkout_page.dart';
import 'package:thix_id/presentation/certification/providers/certification_provider.dart';
import 'package:thix_id/services/bcc_exchange_rate_service.dart';
import 'package:thix_id/services/certification_service.dart';

class CertificationTiersPage extends ConsumerStatefulWidget {
  const CertificationTiersPage({super.key});

  @override
  ConsumerState<CertificationTiersPage> createState() =>
      _CertificationTiersPageState();
}

class _CertificationTiersPageState
    extends ConsumerState<CertificationTiersPage> {
  Future<void> _requestTier(CertificationTier tier) async {
    if (tier.isInviteOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Le niveau Officiel / Institutions est accessible uniquement sur invitation THIX.',
          ),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CertificationCheckoutPage(tier: tier),
      ),
    );

    if (ok == true) {
      ref.invalidate(myCertificationProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final certAsync = ref.watch(myCertificationProvider);
    final rateAsync = ref.watch(usdCdfRateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: certAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: ThixPolicy.primary),
        ),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (info) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _Header(info: info)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  rateAsync.when(
                    data: (q) => _RateBanner(quote: q),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 14),
                  _CertificationBoard(
                    current: info,
                    rate: rateAsync.valueOrNull,
                    onRequest: _requestTier,
                  ),
                  const SizedBox(height: 16),
                  const _FooterNote(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final CertificationInfo info;
  const _Header({required this.info});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    
    // ✅ CORRECTION DE LA LOGIQUE : Si l'utilisateur n'a pas de certification active, on force "Compte Gratuit"
    final isFreeAccount = info.status == CertificationStatus.none;
    final displayTierName = isFreeAccount ? 'Compte Gratuit' : info.tier.labelFr;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, top + 4, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1628),
            Color(0xFF132A4A),
            Color(0xFF1A3A5C),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fingerprint, color: Color(0xFFE8B84A), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'THIX ID',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'CERTIFICATION THIX',
              style: TextStyle(
                color: Color(0xFFE53935),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Abonnement mensuel · Secure Identity. Trusted Future.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  _MiniSeal(
                    color: isFreeAccount ? Colors.blueGrey : info.tier.badgeColor,
                    icon: isFreeAccount ? Icons.person_outline : info.tier.icon,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Votre niveau actuel',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayTierName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: info.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final CertificationStatus status;
  const _StatusPill({required this.status});

  Color get _c => switch (status) {
        CertificationStatus.approved ||
        CertificationStatus.generated =>
          const Color(0xFF22C55E),
        CertificationStatus.pending => const Color(0xFFF59E0B),
        CertificationStatus.rejected => const Color(0xFFEF4444),
        CertificationStatus.none => Colors.white54,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _c.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.labelFr,
        style: TextStyle(
          color: _c,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BANDEAU TAUX
// ═══════════════════════════════════════════════════════════════

class _RateBanner extends StatelessWidget {
  final ExchangeRateQuote quote;
  const _RateBanner({required this.quote});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM/yyyy').format(quote.asOf.toLocal());
    final rateStr = NumberFormat('#,##0.##', 'fr_FR').format(quote.usdToCdf);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E9F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            quote.isOfficialBcc
                ? Icons.account_balance_rounded
                : Icons.currency_exchange_rounded,
            size: 18,
            color: ThixPolicy.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '1 USD = $rateStr CDF · ${quote.isOfficialBcc ? 'BCC' : quote.source} · $date',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: ThixPolicy.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOARD — 4 niveaux
// ═══════════════════════════════════════════════════════════════

class _CertificationBoard extends StatelessWidget {
  final CertificationInfo current;
  final ExchangeRateQuote? rate;
  final Future<void> Function(CertificationTier) onRequest;

  const _CertificationBoard({
    required this.current,
    required this.rate,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF152238),
            Color(0xFF1C2E4A),
            Color(0xFF243B5A),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF3A4F6A), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3A5C).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      child: Column(
        children: [
          _TierRow(
            tier: CertificationTier.standard,
            current: current,
            rate: rate,
            onRequest: onRequest,
          ),
          const _DividerLine(),
          
          _TierRow(
            tier: CertificationTier.premium,
            current: current,
            rate: rate,
            onRequest: onRequest,
            showGeneratedBadge: current.tier == CertificationTier.premium &&
                (current.status == CertificationStatus.generated ||
                    current.status == CertificationStatus.approved),
            extraLines: const [
              'Accès à la monétisation des contenus et services.',
            ],
          ),
          
          // ✅ Suppression de la Divider ici pour mettre en valeur la carte Entreprise
          const SizedBox(height: 6),
          
          _TierRow(
            tier: CertificationTier.enterprise,
            current: current,
            rate: rate,
            onRequest: onRequest,
          ),
          
          const SizedBox(height: 6),
          // ✅ Suppression de la Divider ici également
          
          _TierRow(
            tier: CertificationTier.official,
            current: current,
            rate: rate,
            onRequest: onRequest,
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Colors.white.withOpacity(0.08),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LIGNE D’UN NIVEAU
// ═══════════════════════════════════════════════════════════════

class _TierRow extends StatelessWidget {
  final CertificationTier tier;
  final CertificationInfo current;
  final ExchangeRateQuote? rate;
  final Future<void> Function(CertificationTier) onRequest;
  final bool showGeneratedBadge;
  final List<String> extraLines;

  const _TierRow({
    required this.tier,
    required this.current,
    required this.rate,
    required this.onRequest,
    this.showGeneratedBadge = false,
    this.extraLines = const [],
  });

  bool get _isCurrent => current.tier == tier;
  bool get _isLockedBelow => tier.rank < current.tier.rank;

  bool get _canRequest {
    if (tier.isInviteOnly) return false;
    if (current.status == CertificationStatus.pending &&
        current.tier.rank >= tier.rank) {
      return false;
    }
    if (_isCurrent && current.isCertified) return false;
    if (_isLockedBelow) return false;
    return true;
  }

  String get _title => switch (tier) {
        CertificationTier.standard => 'COMPTE STANDARD',
        CertificationTier.premium => 'COMPTE PREMIUM',
        CertificationTier.enterprise => 'COMPTE ENTREPRISE',
        CertificationTier.official =>
          'RÉSERVÉ AUX OFFICIELS,\nEXCELLENCE, INSTITUTIONS',
      };

  String get _body => switch (tier) {
        CertificationTier.standard =>
          'Pour les utilisateurs individuels.\nAccès aux fonctionnalités de base\net à la certification d\'identité.',
        CertificationTier.premium =>
          'Pour ceux qui veulent plus.\nFonctionnalités avancées,\ncertification prioritaire et\nexpérience améliorée.',
        CertificationTier.enterprise =>
          'Pour les organisations et entreprises.\nGestion d\'équipe, contrôle avancé\net solutions sur mesure.',
        CertificationTier.official =>
          'Pour les entités officielles et les\ninstitutions de confiance.\nNiveau d\'accès le plus élevé\net certification renforcée.',
      };

  IconData get _titleIcon => switch (tier) {
        CertificationTier.standard => Icons.person_rounded,
        CertificationTier.premium => Icons.star_rounded,
        CertificationTier.enterprise => Icons.business_center_rounded,
        CertificationTier.official => Icons.shield_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = tier.badgeColor;
    final active = _isCurrent || current.tier.rank >= tier.rank;
    
    // ✅ DÉTECTION DU NIVEAU ENTREPRISE POUR LE DESIGN "CLAIRE PROPRE"
    final isEnterprise = tier == CertificationTier.enterprise;

    return Container(
      // Marge uniquement pour l'entreprise afin de la détacher des autres
      margin: isEnterprise ? const EdgeInsets.symmetric(vertical: 6) : EdgeInsets.zero,
      
      // ✅ NOUVEAU DESIGN CLAIR ET PROPRE POUR L'ENTREPRISE
      decoration: isEnterprise 
          ? BoxDecoration(
              color: const Color(0xFF1E334D), // Un fond bleu nuit uni et propre
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4A90E2).withOpacity(0.35), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ) 
          : null,
          
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canRequest ? () => onRequest(tier) : null,
          borderRadius: BorderRadius.circular(isEnterprise ? 16 : 14),
          child: Padding(
            // Plus d'espace (padding) pour la carte Entreprise
            padding: isEnterprise 
                ? const EdgeInsets.all(16) 
                : const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SealBadge(color: color, active: active),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_titleIcon, color: color, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _title,
                              style: TextStyle(
                                color: color,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                                height: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (showGeneratedBadge || _isCurrent) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (showGeneratedBadge)
                              const _Chip(
                                  label: 'GÉNÉRÉ', color: Color(0xFFD4A017)),
                            if (_isCurrent) _Chip(label: 'ACTUEL', color: color),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        _body,
                        style: TextStyle(
                          color: Colors.white.withOpacity(isEnterprise ? 0.85 : 0.78),
                          fontSize: 12.2,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ...extraLines.map(
                        (l) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.monetization_on_rounded,
                                  size: 14, color: color.withOpacity(0.9)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  l,
                                  style: TextStyle(
                                    color: color.withOpacity(0.95),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child:
                                _PriceLine(tier: tier, rate: rate, color: color),
                          ),
                          const SizedBox(width: 8),
                          _ActionBtn(
                            tier: tier,
                            canRequest: _canRequest,
                            isCurrent: _isCurrent,
                            isCertified: current.isCertified && _isCurrent,
                            isPending: current.status ==
                                    CertificationStatus.pending &&
                                !_isLockedBelow,
                            color: color,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PriceLine extends StatelessWidget {
  final CertificationTier tier;
  final ExchangeRateQuote? rate;
  final Color color;

  const _PriceLine({
    required this.tier,
    required this.rate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (tier.isInviteOnly) {
      return Text(
        'Sur invitation',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      );
    }
    final usd = tier.priceUsd ?? 0;
    final cdf = rate != null ? rate!.formatCdf(usd) : '… CDF';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${usd.toStringAsFixed(0)} USD / mois',
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '≈ $cdf / mois',
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final CertificationTier tier;
  final bool canRequest;
  final bool isCurrent;
  final bool isCertified;
  final bool isPending;
  final Color color;

  const _ActionBtn({
    required this.tier,
    required this.canRequest,
    required this.isCurrent,
    required this.isCertified,
    required this.isPending,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    Color fg;

    if (tier.isInviteOnly) {
      label = 'Invitation';
      bg = const Color(0xFFDC2626).withOpacity(0.2);
      fg = const Color(0xFFFCA5A5);
    } else if (isCertified) {
      label = 'Actif';
      bg = const Color(0xFF22C55E).withOpacity(0.2);
      fg = const Color(0xFF86EFAC);
    } else if (isPending) {
      label = 'En cours';
      bg = const Color(0xFFF59E0B).withOpacity(0.2);
      fg = const Color(0xFFFCD34D);
    } else if (canRequest) {
      label = 'S\'abonner';
      bg = color;
      fg = Colors.white;
    } else {
      label = 'Inclus';
      bg = Colors.white.withOpacity(0.08);
      fg = Colors.white54;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SCEAU
// ═══════════════════════════════════════════════════════════════

class _SealBadge extends StatelessWidget {
  final Color color;
  final bool active;
  const _SealBadge({required this.color, required this.active});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (active)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.55),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(active ? 1 : 0.55),
                  Color.lerp(color, Colors.black, 0.25)!,
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 2.5,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.25),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.5,
              ),
            ),
          ),
          Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 26,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 4,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniSeal extends StatelessWidget {
  final Color color;
  final IconData icon;
  final double size;
  const _MiniSeal({
    required this.color,
    required this.icon,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.3)!],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.45),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FOOTER
// ═══════════════════════════════════════════════════════════════

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E9F0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: ThixPolicy.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Abonnement mensuel. '
              'Standard 3\$/mois et Premium 7\$/mois : activés après paiement. '
              'Entreprise 30\$/mois : validation admin. '
              'Officiel : sur invitation THIX. '
              'Premium inclut l\'accès à la monétisation.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: ThixPolicy.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
