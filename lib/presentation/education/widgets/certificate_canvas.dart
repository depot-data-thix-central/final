// lib/presentation/education/widgets/certificate_canvas.dart
import 'package:flutter/material.dart';

class CertificateData {
  final String academyName;
  final String header;
  final String learnerName;
  final String body;
  final String courseTitle;
  final String footer;
  final String signatoryName;
  final String signatoryTitle;
  final String? logoUrl;
  final String? signatureUrl;
  final String serial;
  final String dateLabel;
  final String templateId;

  const CertificateData({
    required this.academyName,
    required this.header,
    required this.learnerName,
    required this.body,
    required this.courseTitle,
    required this.footer,
    required this.signatoryName,
    required this.signatoryTitle,
    this.logoUrl,
    this.signatureUrl,
    required this.serial,
    required this.dateLabel,
    required this.templateId,
  });
}

class CertificateCanvas extends StatelessWidget {
  final CertificateData data;
  final double width;

  const CertificateCanvas({
    super.key,
    required this.data,
    this.width = 360,
  });

  static const templates = <String, _TStyle>{
    'classic_navy': _TStyle(
      name: 'Classic Navy',
      primary: Color(0xFF0B1F3A),
      accent: Color(0xFFC9A227),
      bg: Color(0xFFFFFDF8),
    ),
    'royal_gold': _TStyle(
      name: 'Royal Gold',
      primary: Color(0xFF1A1A2E),
      accent: Color(0xFFD4AF37),
      bg: Color(0xFFFFFBF0),
    ),
    'modern_minimal': _TStyle(
      name: 'Modern Minimal',
      primary: Color(0xFF0F172A),
      accent: Color(0xFF64748B),
      bg: Colors.white,
    ),
    'academic_serif': _TStyle(
      name: 'Academic Serif',
      primary: Color(0xFF1E293B),
      accent: Color(0xFFB45309),
      bg: Color(0xFFFAF7F2),
    ),
    'tech_blue': _TStyle(
      name: 'Tech Blue',
      primary: Color(0xFF0C4A6E),
      accent: Color(0xFF38BDF8),
      bg: Color(0xFFF0F9FF),
    ),
    'emerald_elite': _TStyle(
      name: 'Emerald Elite',
      primary: Color(0xFF064E3B),
      accent: Color(0xFF34D399),
      bg: Color(0xFFECFDF5),
    ),
    'crimson_honor': _TStyle(
      name: 'Crimson Honor',
      primary: Color(0xFF7F1D1D),
      accent: Color(0xFFFBBF24),
      bg: Color(0xFFFFFBEB),
    ),
    'slate_pro': _TStyle(
      name: 'Slate Pro',
      primary: Color(0xFF334155),
      accent: Color(0xFF94A3B8),
      bg: Color(0xFFF8FAFC),
    ),
    'ivory_tradition': _TStyle(
      name: 'Ivory Tradition',
      primary: Color(0xFF44403C),
      accent: Color(0xFFA8A29E),
      bg: Color(0xFFFAFaf9),
    ),
    'midnight_prestige': _TStyle(
      name: 'Midnight Prestige',
      primary: Color(0xFF020617),
      accent: Color(0xFFE2E8F0),
      bg: Color(0xFF0F172A),
      lightText: true,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = templates[data.templateId] ?? templates['classic_navy']!;
    final h = width * 1.35;

    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // Cadre double
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: style.accent, width: 2.5),
                ),
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: style.primary.withOpacity(style.lightText ? 0.5 : 0.85),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            // Coins ornementaux
            ..._corners(style),
            // Contenu
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
              child: Column(
                children: [
                  // Logo / académie
                  if (data.logoUrl != null && data.logoUrl!.isNotEmpty)
                    Image.network(data.logoUrl!, height: 36, fit: BoxFit.contain)
                  else
                    Icon(Icons.workspace_premium,
                        size: 32, color: style.accent),
                  const SizedBox(height: 6),
                  Text(
                    data.academyName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                      color: style.lightText ? style.accent : style.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'CERTIFICATE',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: style.lightText ? Colors.white : style.primary,
                    ),
                  ),
                  Text(
                    'OF COMPLETION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      color: style.accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(width: 48, height: 2, color: style.accent),
                  const SizedBox(height: 10),
                  Text(
                    data.header,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: style.lightText
                          ? Colors.white70
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.learnerName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: style.accent,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    width: 120,
                    height: 1,
                    color: style.accent.withOpacity(0.5),
                  ),
                  Text(
                    data.body,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      height: 1.35,
                      color: style.lightText
                          ? Colors.white70
                          : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '« ${data.courseTitle} »',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: style.lightText ? Colors.white : style.primary,
                    ),
                  ),
                  const Spacer(),
                  // Sceau
                  Icon(Icons.military_tech_rounded,
                      size: 28, color: style.accent),
                  const SizedBox(height: 8),
                  // Signature + date
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            if (data.signatureUrl != null &&
                                data.signatureUrl!.isNotEmpty)
                              Image.network(data.signatureUrl!,
                                  height: 28, fit: BoxFit.contain)
                            else
                              Text(
                                '________________',
                                style: TextStyle(
                                  color: style.lightText
                                      ? Colors.white54
                                      : Colors.black26,
                                  fontSize: 10,
                                ),
                              ),
                            const SizedBox(height: 2),
                            Text(
                              data.signatoryName,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: style.lightText
                                    ? Colors.white
                                    : style.primary,
                              ),
                            ),
                            Text(
                              data.signatoryTitle,
                              style: TextStyle(
                                fontSize: 8,
                                color: style.lightText
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              data.dateLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: style.lightText
                                    ? Colors.white
                                    : style.primary,
                              ),
                            ),
                            Text(
                              data.footer,
                              style: TextStyle(
                                fontSize: 8,
                                color: style.lightText
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.serial,
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: style.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Mention légale obligatoire
                  Text(
                    'Produit par THIX ID CENTRAL',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: style.lightText
                          ? Colors.white38
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _corners(_TStyle s) {
    const size = 28.0;
    Widget corner(Alignment a) {
      return Align(
        alignment: a,
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border(
              top: a == Alignment.topLeft || a == Alignment.topRight
                  ? BorderSide(color: s.accent, width: 3)
                  : BorderSide.none,
              bottom: a == Alignment.bottomLeft || a == Alignment.bottomRight
                  ? BorderSide(color: s.accent, width: 3)
                  : BorderSide.none,
              left: a == Alignment.topLeft || a == Alignment.bottomLeft
                  ? BorderSide(color: s.accent, width: 3)
                  : BorderSide.none,
              right: a == Alignment.topRight || a == Alignment.bottomRight
                  ? BorderSide(color: s.accent, width: 3)
                  : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(Alignment.topLeft),
      corner(Alignment.topRight),
      corner(Alignment.bottomLeft),
      corner(Alignment.bottomRight),
    ];
  }
}

class _TStyle {
  final String name;
  final Color primary;
  final Color accent;
  final Color bg;
  final bool lightText;
  const _TStyle({
    required this.name,
    required this.primary,
    required this.accent,
    required this.bg,
    this.lightText = false,
  });
}
