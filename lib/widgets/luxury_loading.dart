import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LuxuryLoading extends StatefulWidget {
  final String? message;
  const LuxuryLoading({super.key, this.message});

  @override
  State<LuxuryLoading> createState() => _LuxuryLoadingState();
}

class _LuxuryLoadingState extends State<LuxuryLoading> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0F172A), // Dark Slate / Luxury Royal Navy
            Color(0xFF1E1B4B), // Deep Indigo
            Color(0xFF0284C7), // Academic Electric Blue Accent
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient Radial Light Halo
          Positioned(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 320 * _pulseAnimation.value,
                  height: 320 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withOpacity(0.20),
                        const Color(0xFF818CF8).withOpacity(0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Vector Graduation Hat & Glowing Emblem
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF38BDF8),
                              Color(0xFF818CF8),
                              Color(0xFFF59E0B),
                              Color(0xFF10B981),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withOpacity(0.4),
                              blurRadius: 35,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F172A),
                            shape: BoxShape.circle,
                          ),
                          child: CustomPaint(
                            size: const Size(130, 130),
                            painter: _GraduationCapPainter(
                              progress: _controller.value,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 36),
                // Smooth Progress Indicator
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                    strokeWidth: 3.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Loading Message
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    widget.message ?? "جاري تهيئة منصة الدراسات العليا...",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: const Color(0xFF38BDF8).withOpacity(0.5),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF38BDF8).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Text(
                        "دليل الامتحان الوطني العراقي الموحد للدراسات العليا",
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF93C5FD),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎨 Custom Vector Painter for Animated Graduation Cap & Tassel Physics
class _GraduationCapPainter extends CustomPainter {
  final double progress;

  _GraduationCapPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Floating 3D motion equation
    final floatY = math.sin(progress * 2 * math.pi) * 4.0;
    final tasselSwing = math.sin(progress * 2 * math.pi) * 12.0;

    final capCenterY = centerY + floatY - 6;

    // 1. Draw Floating Glowing Aura under Cap
    final shadowPaint = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, capCenterY + 42),
        width: 70,
        height: 14,
      ),
      shadowPaint,
    );

    // 2. Skull Cap Base (Under Mortarboard)
    final capBasePath = Path()
      ..moveTo(centerX - 24, capCenterY + 4)
      ..lineTo(centerX + 24, capCenterY + 4)
      ..lineTo(centerX + 22, capCenterY + 28)
      ..cubicTo(
        centerX + 16, capCenterY + 36,
        centerX - 16, capCenterY + 36,
        centerX - 22, capCenterY + 28,
      )
      ..close();

    final capBasePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(centerX - 24, capCenterY + 4, 48, 32));

    canvas.drawPath(capBasePath, capBasePaint);

    final capBaseStroke = Paint()
      ..color = const Color(0xFF38BDF8).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawPath(capBasePath, capBaseStroke);

    // 3. Mortarboard Diamond Top (Cap Surface)
    final diamondPath = Path()
      ..moveTo(centerX, capCenterY - 26) // Top vertex
      ..lineTo(centerX + 48, capCenterY - 6) // Right vertex
      ..lineTo(centerX, capCenterY + 12) // Bottom vertex
      ..lineTo(centerX - 48, capCenterY - 6) // Left vertex
      ..close();

    final diamondPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3B82F6), Color(0xFF1E3A8A), Color(0xFF0F172A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(centerX - 48, capCenterY - 26, 96, 38));

    canvas.drawPath(diamondPath, diamondPaint);

    final diamondStroke = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF60A5FA), Color(0xFFF59E0B), Color(0xFF38BDF8)],
      ).createShader(Rect.fromLTWH(centerX - 48, capCenterY - 26, 96, 38))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(diamondPath, diamondStroke);

    // 4. Center Gold Button
    final buttonCenter = Offset(centerX, capCenterY - 7);
    final buttonPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
      ).createShader(Rect.fromCircle(center: buttonCenter, radius: 5));
    canvas.drawCircle(buttonCenter, 4.5, buttonPaint);

    // 5. Golden Silk Tassel String (Swinging with Physics)
    final tasselStartX = centerX;
    final tasselStartY = capCenterY - 7;
    final tasselMidX = centerX - 26 + (tasselSwing * 0.4);
    final tasselMidY = capCenterY + 2;
    final tasselEndX = centerX - 34 + tasselSwing;
    final tasselEndY = capCenterY + 24;

    final stringPath = Path()
      ..moveTo(tasselStartX, tasselStartY)
      ..cubicTo(
        tasselStartX - 10, tasselStartY + 2,
        tasselMidX, tasselMidY,
        tasselEndX, tasselEndY,
      );

    final stringPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.4;
    canvas.drawPath(stringPath, stringPaint);

    // 6. Tassel Fringe (Hanging Golden Ring & Fringe Brush)
    final fringeCenter = Offset(tasselEndX, tasselEndY + 6);
    final fringeBrushPath = Path()
      ..moveTo(fringeCenter.dx - 3.5, fringeCenter.dy - 3)
      ..lineTo(fringeCenter.dx + 3.5, fringeCenter.dy - 3)
      ..lineTo(fringeCenter.dx + 6, fringeCenter.dy + 12)
      ..lineTo(fringeCenter.dx - 6, fringeCenter.dy + 12)
      ..close();

    final fringePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFB45309)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromCircle(center: fringeCenter, radius: 10));

    canvas.drawPath(fringeBrushPath, fringePaint);

    // 7. Academic Stars Floating Particles
    _drawStar(canvas, Offset(centerX - 42, capCenterY - 24 + math.sin(progress * 4 * math.pi) * 3), 4, 0.9);
    _drawStar(canvas, Offset(centerX + 44, capCenterY - 18 + math.cos(progress * 4 * math.pi) * 3), 5, 0.85);
    _drawStar(canvas, Offset(centerX + 32, capCenterY + 20 + math.sin(progress * 3 * math.pi) * 2), 3.5, 0.7);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, double opacity) {
    final starPaint = Paint()
      ..color = const Color(0xFFF59E0B).withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 4; i++) {
      double angle = i * math.pi / 2;
      double x = center.dx + math.cos(angle) * radius;
      double y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      double midAngle = angle + math.pi / 4;
      double midX = center.dx + math.cos(midAngle) * (radius * 0.35);
      double midY = center.dy + math.sin(midAngle) * (radius * 0.35);
      path.lineTo(midX, midY);
    }
    path.close();
    canvas.drawPath(path, starPaint);
  }

  @override
  bool shouldRepaint(covariant _GraduationCapPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
