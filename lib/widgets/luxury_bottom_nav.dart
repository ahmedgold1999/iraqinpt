import 'dart:ui';
import 'package:flutter/material.dart';

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

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              color: Colors.white.withOpacity(0.90), // iOS Frosted Glass Effect
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withOpacity(0.7),
                  width: 1.5,
                ),
              ),
            ),
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, 'الرئيسية', const Color(0xFF0F172A)),
                  _buildNavItem(1, Icons.stars_rounded, 'التفعيل', const Color(0xFFD4AF37)),
                  _buildNavItem(2, Icons.grid_view_rounded, 'الأدوات', const Color(0xFF00C853)),
                  _buildNavItem(3, Icons.auto_stories_rounded, 'ملازم', const Color(0xFF2563EB)),
                  _buildNavItem(
                    4,
                    isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
                    isAdmin ? 'المدير' : 'ملفي',
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color accentColor) {
    final bool isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // iOS Active Pill Indicator
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: isSelected ? 20 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: accentColor.withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
              ),
              const SizedBox(height: 4),
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                child: Icon(
                  icon,
                  color: isSelected ? accentColor : const Color(0xFF8E8E93),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? accentColor : const Color(0xFF8E8E93),
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
