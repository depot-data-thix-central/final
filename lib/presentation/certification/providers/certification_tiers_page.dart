// lib/presentation/certification/certification_tiers_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/core/theme/thix_design_policy.dart';
import 'package:thix_id/models/certification_tier.dart';
import 'package:thix_id/presentation/certification/providers/certification_provider.dart';
import 'package:thix_id/services/certification_service.dart';

class CertificationTiersPage extends ConsumerStatefulWidget {
  const CertificationTiersPage({super.key});

  @override
  ConsumerState<CertificationTiersPage> createState() =>
      _CertificationTiersPageState();
}

class _CertificationTiersPageState
    extends ConsumerState<CertificationTiersPage> {
  bool _submitting = false;

  Future<void> _requestTier(CertificationTier tier) async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      await ref.read(certificationServiceProvider).requestUpgrade(
            requestedTier: tier,
            reason: 'Demande depuis la page Certification THIX',
          );
      ref.invalidate(myCertificationProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande ${tier.shortLabel} envoyée'),
          backgroundColor: ThixPolicy.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: ThixPolicy.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final certAsync = ref.watch(myCertificationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: certAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: ThixPolicy.primary),
          ),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (info) => CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Header ──
              SliverToBoxAdapter(child: _buildHeader(info)),
              const SliverToBoxAdapter(sizedBox: SizedBox(height: 8)),

              // ── Liste des 4 tiers ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _TierCard(
                      tier: CertificationTier.standard,
                      current: info,
                      submitting: _submitting,
                      onRequest: () => _requestTier(CertificationTier.standard),
                    ),
                    const SizedBox(height: 14),
                    _TierCard(
                      tier: CertificationTier.premium,
                      current: info,
                      submitting: _submitting,
                      onRequest: () => _requestTier(CertificationTier.premium),
                      showGeneratedBadge: info.tier == CertificationTier.premium &&
                          info.status == CertificationStatus.generated,
                    ),
                    const SizedBox(height: 14),
                    _TierCard(
                      tier: CertificationTier.enterprise,
                      current: info,
                      submitting: _submitting,
                      onRequest: () =>
                          _requestTier(CertificationTier.enterprise),
                    ),
                    const SizedBox(height: 14),
                    _TierCard(
                      tier: CertificationTier.official,
                      current: info,
                      submitting: _submitting,
                      onRequest: () => _requestTier(CertificationTier.official),
                    ),
                    const SizedBox(height: 24),
                    _buildFooterNote(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CertificationInfo info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1B3A), Color(0xFF152A52)],
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
              // Logo THIX mini
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
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
          const SizedBox(height: 12),
          const Text(
            'CERTIFICATION THIX',
            style: TextStyle(
              color: Color(0xFFE53935),
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Secure Identity. Trusted Future.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          // Statut actuel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: info.tier.badgeColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: info.tier.badgeColor, width: 2),
                  ),
                  child: Icon(info.tier.icon,
                      color: info.tier.badgeColor, size: 22),
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
                        info.tier.labelFr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor(info.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    info.status.labelFr,
                    style: TextStyle(
                      color: _statusColor(info.status),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(CertificationStatus s) => switch (s) {
        CertificationStatus.approved ||
        CertificationStatus.generated =>
          const Color(0xFF22C55E),
        CertificationStatus.pending => const Color(0xFFF59E0B),
        CertificationStatus.rejected => const Color(0xFFEF4444),
        CertificationStatus.none => Colors.white54,
      };

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThixPolicy.border),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 18, color: ThixPolicy.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les demandes Premium, Entreprise et Officiel sont examinées par l\'équipe THIX. La certification d\'identité (Standard) peut être validée plus rapidement.',
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

// ─────────────────────────────────────────────────────────────
// CARTE D'UN NIVEAU
// ─────────────────────────────────────────────────────────────

class _TierCard extends StatelessWidget {
  final CertificationTier tier;
  final CertificationInfo current;
  final bool submitting;
  final VoidCallback onRequest;
  final bool showGeneratedBadge;

  const _TierCard({
    required this.tier,
    required this.current,
    required this.submitting,
    required this.onRequest,
    this.showGeneratedBadge = false,
  });

  bool get _isCurrent => current.tier == tier;

  bool get _isLockedBelow => tier.rank < current.tier.rank;

  bool get _canRequest {
    if (current.status == CertificationStatus.pending) return false;
    if (_isCurrent && current.isCertified) return false;
    if (_isLockedBelow) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final color = tier.badgeColor;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isCurrent ? color : Colors.white.withOpacity(0.08),
          width: _isCurrent ? 2 : 1,
        ),
        boxShadow: [
          if (_isCurrent)
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _canRequest && !submitting ? onRequest : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sceau ──
                _Seal(color: color, icon: tier.icon, active: _isCurrent || current.tier.rank >= tier.rank),
                const SizedBox(width: 14),
                // ── Textes ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              tier.labelFr.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          if (showGeneratedBadge) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4A017).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFFD4A017), width: 1),
                              ),
                              child: const Text(
                                'GÉNÉRÉ',
                                style: TextStyle(
                                  color: Color(0xFFD4A017),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                          if (_isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ACTUEL',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tier.descriptionFr,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 12.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Bouton d'action ──
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _ActionChip(
                          canRequest: _canRequest,
                          isCurrent: _isCurrent,
                          isCertified: current.isCertified && _isCurrent,
                          isPending: current.status == CertificationStatus.pending &&
                              current.tier.rank <= tier.rank,
                          submitting: submitting,
                          color: color,
                        ),
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

class _Seal extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool active;

  const _Seal({
    required this.color,
    required this.icon,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(active ? 1 : 0.45),
            color.withOpacity(active ? 0.75 : 0.25),
          ],
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 2,
        ),
      ),
      child: Icon(
        active ? Icons.check_rounded : icon,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final bool canRequest;
  final bool isCurrent;
  final bool isCertified;
  final bool isPending;
  final bool submitting;
  final Color color;

  const _ActionChip({
    required this.canRequest,
    required this.isCurrent,
    required this.isCertified,
    required this.isPending,
    required this.submitting,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    Color bg;
    Color fg;

    if (isCertified) {
      label = 'Certifié';
      bg = const Color(0xFF22C55E).withOpacity(0.15);
      fg = const Color(0xFF22C55E);
    } else if (isPending) {
      label = 'En cours…';
      bg = const Color(0xFFF59E0B).withOpacity(0.15);
      fg = const Color(0xFFF59E0B);
    } else if (canRequest) {
      label = isCurrent ? 'Activer' : 'Demander';
      bg = color;
      fg = Colors.white;
    } else {
      label = 'Inclus';
      bg = Colors.white.withOpacity(0.08);
      fg = Colors.white54;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (submitting && canRequest)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}
