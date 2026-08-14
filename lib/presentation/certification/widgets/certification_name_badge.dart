// lib/presentation/certification/widgets/certification_name_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/models/certification_tier.dart';
import 'package:thix_id/presentation/certification/providers/certification_provider.dart';
import 'package:thix_id/services/certification_service.dart';

/// Sceau certification (icône seule à côté du nom)
class CertificationNameBadge extends ConsumerWidget {
  final bool showLabel;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final CertificationTier? tier;
  final CertificationStatus? status;

  const CertificationNameBadge({
    super.key,
    this.showLabel = false,
    this.iconSize = 18,
    this.padding = const EdgeInsets.only(left: 6),
    this.tier,
    this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tier != null) {
      return _SealChip(
        tier: tier!,
        status: status ?? CertificationStatus.approved,
        showLabel: showLabel,
        size: iconSize,
        padding: padding,
      );
    }

    final async = ref.watch(myCertificationProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (info) {
        if (!info.isCertified && info.status != CertificationStatus.pending) {
          return const SizedBox.shrink();
        }
        return _SealChip(
          tier: info.tier,
          status: info.status,
          showLabel: showLabel,
          size: iconSize,
          padding: padding,
        );
      },
    );
  }
}

class _SealChip extends StatelessWidget {
  final CertificationTier tier;
  final CertificationStatus status;
  final bool showLabel;
  final double size;
  final EdgeInsetsGeometry padding;

  const _SealChip({
    required this.tier,
    required this.status,
    required this.showLabel,
    required this.size,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = tier.badgeColor;
    final pending = status == CertificationStatus.pending;

    return Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sceau type médaille (comme l'affiche)
          _CertSeal(color: color, size: size, pending: pending),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              pending ? '${tier.shortLabel}…' : tier.shortLabel,
              style: TextStyle(
                color: color,
                fontSize: size * 0.7,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Médaille dentelée + check blanc (style certification THIX)
class _CertSeal extends StatelessWidget {
  final Color color;
  final double size;
  final bool pending;

  const _CertSeal({
    required this.color,
    required this.size,
    this.pending = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: size * 0.25,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          // Anneau principal (effet sceau)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color,
                  Color.lerp(color, Colors.black, 0.28)!,
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: size * 0.08,
              ),
            ),
          ),
          // Cercle intérieur
          Container(
            width: size * 0.68,
            height: size * 0.68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.35),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
          ),
          Icon(
            pending ? Icons.hourglass_top_rounded : Icons.check_rounded,
            color: Colors.white,
            size: size * 0.48,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
