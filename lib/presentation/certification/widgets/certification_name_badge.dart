// lib/presentation/certification/widgets/certification_name_badge.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_id/models/certification_tier.dart';
import 'package:thix_id/presentation/certification/providers/certification_provider.dart';
import 'package:thix_id/services/certification_service.dart';

/// Sceau certification (icône seule, sans nom à côté — style Facebook)
class CertificationNameBadge extends ConsumerWidget {
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final CertificationTier? tier;
  final CertificationStatus? status;

  const CertificationNameBadge({
    super.key,
    this.iconSize = 18,
    this.padding = const EdgeInsets.only(left: 6),
    this.tier,
    this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tier != null) {
      return Padding(
        padding: padding,
        child: _CertSeal(
          tier: tier!,
          status: status ?? CertificationStatus.approved,
          size: iconSize,
        ),
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
        return Padding(
          padding: padding,
          child: _CertSeal(
            tier: info.tier,
            status: info.status,
            size: iconSize,
          ),
        );
      },
    );
  }
}

/// Sceau seul — cercle central + anneau dentelé + check blanc.
class _CertSeal extends StatelessWidget {
  final CertificationTier tier;
  final CertificationStatus status;
  final double size;

  const _CertSeal({
    required this.tier,
    required this.status,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = tier.badgeColor;
    final pending = status == CertificationStatus.pending;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow doux autour du sceau
          Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.45),
                  blurRadius: size * 0.28,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          // Contour dentelé exact (scallop / médaille)
          CustomPaint(
            size: Size(size, size),
            painter: _ScallopedSealPainter(color: color),
          ),
          // Check / sablier blanc
          Icon(
            pending ? Icons.hourglass_top_rounded : Icons.check_rounded,
            color: Colors.white,
            size: size * 0.5,
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

/// Dessine le contour dentelé (forme exacte du sceau de certification)
/// avec un dégradé radial, un léger relief, et une bordure blanche fine.
class _ScallopedSealPainter extends CustomPainter {
  final Color color;
  final int notches;
  final double amplitude;

  _ScallopedSealPainter({
    required this.color,
    this.notches = 20,
    this.amplitude = 0.09,
  });

  Path _scallopPath(Offset center, double radius) {
    final path = Path();
    const steps = 240;
    for (int i = 0; i <= steps; i++) {
      final theta = (i / steps) * 2 * math.pi;
      final r = radius *
          (1 - amplitude / 2 + (amplitude / 2) * math.cos(notches * theta));
      final x = center.dx + r * math.cos(theta - math.pi / 2);
      final y = center.dy + r * math.sin(theta - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = _scallopPath(center, radius);

    // Remplissage dégradé (relief médaille)
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          Color.lerp(color, Colors.black, 0.28)!,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, fillPaint);

    // Bordure blanche fine (effet sceau embossé)
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.09
      ..color = Colors.white.withOpacity(0.4);
    canvas.drawPath(path, borderPaint);

    // Cercle intérieur légèrement plus clair
    final innerPaint = Paint()..color = color.withOpacity(0.35);
    canvas.drawCircle(center, radius * 0.62, innerPaint);
    final innerBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withOpacity(0.25);
    canvas.drawCircle(center, radius * 0.62, innerBorder);
  }

  @override
  bool shouldRepaint(covariant _ScallopedSealPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.notches != notches ||
        oldDelegate.amplitude != amplitude;
  }
}
