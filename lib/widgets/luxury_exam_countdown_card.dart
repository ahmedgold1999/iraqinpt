import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/config_service.dart';

class LuxuryExamCountdownCard extends StatefulWidget {
  const LuxuryExamCountdownCard({super.key});

  @override
  State<LuxuryExamCountdownCard> createState() => _LuxuryExamCountdownCardState();
}

class _LuxuryExamCountdownCardState extends State<LuxuryExamCountdownCard> {
  Timer? _tickerTimer;
  DateTime _targetDate = DateTime(2026, 6, 15, 23, 59, 59);
  String _rawDateStr = '2026-06-15';
  StreamSubscription<DocumentSnapshot>? _streamSubscription;

  @override
  void initState() {
    super.initState();
    _initInitialDate();
    _startListeningToFirestore();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _initInitialDate() {
    final initialDateStr = ConfigService().examEndDate;
    _parseAndSetDate(initialDateStr);
  }

  void _startListeningToFirestore() {
    _streamSubscription = FirebaseFirestore.instance
        .collection('system_settings')
        .doc('maintenance_and_updates')
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data() != null && mounted) {
        final data = doc.data()!;
        final dynamic rawEnd = data['exam_end_date'] ?? data['examEndDate'];
        if (rawEnd != null) {
          if (rawEnd is Timestamp) {
            setState(() {
              _targetDate = rawEnd.toDate();
              _rawDateStr = '${_targetDate.year}-${_targetDate.month.toString().padLeft(2, '0')}-${_targetDate.day.toString().padLeft(2, '0')}';
            });
          } else if (rawEnd is String && rawEnd.trim().isNotEmpty) {
            _parseAndSetDate(rawEnd.trim());
          }
        }
      }
    }, onError: (e) => debugPrint('⚠️ Error streaming exam_end_date: $e'));
  }

  void _parseAndSetDate(String dateStr) {
    _rawDateStr = dateStr;
    try {
      // Normalize slashes to dashes
      final normalized = dateStr.replaceAll('/', '-').trim();
      DateTime? parsed = DateTime.tryParse(normalized);
      if (parsed != null) {
        // If no time is specified, set to end of that day (23:59:59)
        if (!normalized.contains('T') && !normalized.contains(':')) {
          parsed = DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
        }
        setState(() => _targetDate = parsed!);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bool isEnded = now.isAfter(_targetDate);
    final difference = isEnded ? Duration.zero : _targetDate.difference(now);

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(-0.6, -0.6),
          radius: 1.4,
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF0C2137),
            Color(0xFF071424),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: const Color(0xFFC6A43F).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC6A43F).withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // Background subtle luxury accent circle
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC6A43F).withOpacity(0.06),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
              child: Column(
                children: [
                  // Header Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFE9D49C).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFFACC15)),
                        const SizedBox(width: 6),
                        Text(
                          isEnded ? 'انتهت الفترة المحددة' : 'العد التنازلي للامتحان الوطني',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFACC15),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  Text(
                    isEnded
                        ? 'انتهت فترة الاختبارات الحالية'
                        : 'الوقت المتبقي على انتهاء فترة الامتحان',
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 4 Time Units Row
                  if (isEnded)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy_rounded, color: Color(0xFFFCA5A5), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'تم انتهاء الفترة الزمنية المحددة للاختبار',
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFFCA5A5),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLuxuryUnit(days.toString().padLeft(2, '0'), 'أيام', const Color(0xFF1F7B4D)),
                        const SizedBox(width: 8),
                        _buildLuxuryUnit(hours.toString().padLeft(2, '0'), 'ساعات', const Color(0xFF2563EB)),
                        const SizedBox(width: 8),
                        _buildLuxuryUnit(minutes.toString().padLeft(2, '0'), 'دقائق', const Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        _buildLuxuryUnit(seconds.toString().padLeft(2, '0'), 'ثواني', const Color(0xFFDC2626)),
                      ],
                    ),
                  const SizedBox(height: 16),

                  // Footer Date Info Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFFE9D49C)),
                        const SizedBox(width: 6),
                        Text(
                          'تاريخ الانتهاء المعتمد: $_rawDateStr',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE9D49C),
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
      ),
    );
  }

  Widget _buildLuxuryUnit(String value, String label, Color accentColor) {
    return Column(
      children: [
        Container(
          width: 64,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF132438),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.5),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            fontFamily: 'Tajawal',
          ),
        ),
      ],
    );
  }
}
