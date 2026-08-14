// lib/presentation/certification/widgets/certification_name_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/models/certification_tier.dart';
import 'package:thix_id/presentation/certification/providers/certification_provider.dart';
import 'package:thix_id/services/certification_service.dart';

/// Badge compact à côté du nom (Standard / Premium / Entreprise / Officiel)
class CertificationNameBadge extends ConsumerWidget {
  final bool showLabel;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  /// Si fourni, affiche ce tier (profil public d'un autre user).
  /// Sinon lit myCertificationProvider (utilisateur connecté).
  final CertificationTier? tier;
  final CertificationStatus? status;

  const CertificationNameBadge({
    super.key,
    this.showLabel = true,
    this.iconSize = 14,
    this.padding = const EdgeInsets.only(left: 6),
    this.tier,
    this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tier != null) {
      return _Badge(
        tier: tier!,
        status: status ?? CertificationStatus.approved,
        showLabel: showLabel,
        iconSize: iconSize,
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
        return _Badge(
          tier: info.tier,
          status: info.status,
          showLabel: showLabel,
          iconSize: iconSize,
          padding: padding,
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final CertificationTier tier;
  final CertificationStatus status;
  final bool showLabel;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const _Badge({
    required this.tier,
    required this.status,
    required this.showLabel,
    required this.iconSize,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final color = tier.badgeColor;
    final pending = status == CertificationStatus.pending;

    return Padding(
      padding: padding,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showLabel ? 8 : 5,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.45), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pending ? Icons.hourglass_top_rounded : tier.icon,
              size: iconSize,
              color: color,
            ),
            if (showLabel) ...[
              const SizedBox(width: 4),
              Text(
                pending ? '${tier.shortLabel}…' : tier.shortLabel,
                style: TextStyle(
                  color: color,
                  fontSize: iconSize - 1,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Nom + badge sur une seule ligne
class NameWithCertification extends ConsumerWidget {
  final String name;
  final TextStyle? nameStyle;
  final bool showLabel;
  final CertificationTier? tier;
  final CertificationStatus? status;
  final int maxLines;

  const NameWithCertification({
    super.key,
    required this.name,
    this.nameStyle,
    this.showLabel = true,
    this.tier,
    this.status,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: nameStyle,
          ),
        ),
        CertificationNameBadge(
          showLabel: showLabel,
          tier: tier,
          status: status,
        ),
      ],
    );
  }
}
