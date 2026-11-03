import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/config_service.dart';

class LuxuryBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isAdmin;

  const LuxuryBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isReview = ConfigService().isReviewMode;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.only(
              bottom: bottomInset > 0 ? bottomInset : 4,
              top: 4,
              left: 4,
              right: 4,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withOpacity(0.92)
                  : Colors.white.withOpacity(0.90), // iOS Frosted Glass Effect
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.12)
                      : Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
              ),
            ),
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'الرئيسية', const Color(0xFF0F172A), isDark),
                  _buildNavItem(
                    1,
                    isReview ? Icons.school_rounded : Icons.stars_rounded,
                    isReview ? 'الدليل' : 'العضوية',
                    const Color(0xFFD4AF37),
                    isDark,
                  ),
                  _buildNavItem(2, Icons.grid_view_rounded, 'الأدوات', const Color(0xFF00C853), isDark),
                  _buildNavItem(3, Icons.auto_stories_rounded, 'ملازم', const Color(0xFF2563EB), isDark),
                  _buildNavItem(
                    4,
                    isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                    isAdmin ? 'المدير' : 'ملفي',
                    const Color(0xFF8B5CF6),
                    isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color accentColor, bool isDark) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? accentColor.withOpacity(0.2) : accentColor.withOpacity(0.10))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  color: isSelected
                      ? (isDark ? const Color(0xFF38BDF8) : accentColor)
                      : (isDark ? Colors.white54 : const Color(0xFF8E8E93)),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? const Color(0xFF38BDF8) : accentColor)
                      : (isDark ? Colors.white54 : const Color(0xFF8E8E93)),
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
