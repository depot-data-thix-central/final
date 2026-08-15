import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CarteSignalementsPage extends StatefulWidget {
  const CarteSignalementsPage({super.key});

  @override
  State<CarteSignalementsPage> createState() => _CarteSignalementsPageState();
}

class _CarteSignalementsPageState extends State<CarteSignalementsPage> {
  bool _showPerdus = true;
  bool _showTrouves = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Carte des signalements',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.filter_list, size: 18, color: Color(0xFF2563EB)),
            label: Text(
              'Filtrer',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                _legendItem(Colors.red, 'Perdus', _showPerdus, () {
                  setState(() => _showPerdus = !_showPerdus);
                }),
                const SizedBox(width: 16),
                _legendItem(Colors.green, 'Trouvés', _showTrouves, () {
                  setState(() => _showTrouves = !_showTrouves);
                }),
                const Spacer(),
                _legendItem(const Color(0xFF2563EB), 'Votre position', true, null),
              ],
            ),
          ),

          // Map placeholder
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFFE8EEF5),
                  child: CustomPaint(
                    painter: _MapPlaceholderPainter(),
                    size: Size.infinite,
                  ),
                ),

                // Floating selected marker card
                Positioned(
                  top: 20,
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Téléphone Samsung',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  "Perdu • Aujourd'hui, 15h • THIX Center",
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),

                // Center position indicator
                const Center(
                  child: Icon(
                    Icons.my_location,
                    size: 32,
                    color: Color(0xFF2563EB),
                  ),
                ),

                // Floating action
                Positioned(
                  bottom: 24,
                  right: 16,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xFF2563EB),
                    onPressed: () {},
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label, bool active, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: active ? color : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: active ? Colors.black87 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final redPaint = Paint()..color = Colors.red.withOpacity(0.8);
    final greenPaint = Paint()..color = Colors.green.withOpacity(0.8);

    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.4), 10, redPaint);
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.55), 10, greenPaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.3), 8, redPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.65), 9, greenPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
