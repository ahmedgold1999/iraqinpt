import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/leaderboard_service.dart';
import '../../utils/avatar_helper.dart';
import '../../routes.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _selectedSubject = 'all';

  final Map<String, String> _subjects = {
    'all': '🏆 الترتيب العام',
    'arabic': '📖 اللغة العربية',
    'computer': '💻 الحاسوب',
    'english': '🇬🇧 اللغة الإنجليزية',
  };

  static const _gold = Color(0xFFFACC15);
  static const _silver = Color(0xFF94A3B8);
  static const _bronze = Color(0xFFD97706);

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0A0F1D) : Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_rounded, color: _gold, size: 24),
            SizedBox(width: 8),
            Text(
              'لوحة الشرف والمتصدرين',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط اختيار المواد في الأعلى
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF131C31) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _subjects.entries.map((entry) {
                  final isSelected = _selectedSubject == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      label: Text(
                        entry.value,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : null,
                          fontSize: 12.5,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedSubject = entry.key);
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // قائمة الطلاب السطرية المدمجة
          Expanded(
            child: StreamBuilder<List<LeaderboardEntry>>(
              stream: LeaderboardService.getLeaderboardStream(
                subject: _selectedSubject,
                limit: 50,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ في تحميل لوحة الشرف: ${snapshot.error}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  );
                }

                final entries = snapshot.data ?? [];

                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: _gold.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.stars_rounded, size: 55, color: _gold),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'لا يوجد متصدرون في ${_subjects[_selectedSubject]} بعد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'كن أول من يخوض الاختبار وتصدر القائمة!',
                          style: TextStyle(color: Colors.grey, fontFamily: 'Tajawal', fontSize: 13),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  itemCount: entries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final rank = index + 1;
                    final isMe = entry.userId == currentUserId;
                    final score = entry.getScoreForSubject(_selectedSubject);

                    return _buildCompactStudentRow(
                      rank: rank,
                      entry: entry,
                      score: score,
                      isMe: isMe,
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),

          // شريط تشجيعي سفلي جذاب للانضمام لـ VIP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              border: Border(
                top: BorderSide(color: _gold.withOpacity(0.3), width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👑', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'كن من نخبة المتصدرين مع تاج VIP 🌟',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _gold,
                        ),
                      ),
                      const Text(
                        'احصل على شارة التميز الملكية والوصول لجميع بنوك الأسئلة',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 10.5,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.subscription),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'ترقية ✨',
                    style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStudentRow({
    required int rank,
    required LeaderboardEntry entry,
    required int score,
    required bool isMe,
    required bool isDark,
  }) {
    Color rankColor = const Color(0xFF64748B);
    Widget rankWidget;

    if (rank == 1) {
      rankColor = _gold;
      rankWidget = const Icon(Icons.workspace_premium_rounded, color: _gold, size: 22);
    } else if (rank == 2) {
      rankColor = _silver;
      rankWidget = const Icon(Icons.military_tech_rounded, color: _silver, size: 22);
    } else if (rank == 3) {
      rankColor = _bronze;
      rankWidget = const Icon(Icons.military_tech_outlined, color: _bronze, size: 22);
    } else {
      rankWidget = Text(
        '$rank',
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : const Color(0xFF64748B),
          fontSize: 13,
        ),
      );
    }

    final isVip = entry.isPremium;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isVip
            ? (isDark ? const Color(0xFF1E1B4B).withOpacity(0.6) : const Color(0xFFFFFBEB))
            : (isMe
                ? (isDark ? const Color(0xFF2563EB).withOpacity(0.18) : const Color(0xFFEFF6FF))
                : (isDark ? const Color(0xFF131C31) : Colors.white)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVip
              ? _gold.withOpacity(0.6)
              : (isMe
                  ? const Color(0xFF2563EB)
                  : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0))),
          width: isVip ? 1.6 : (isMe ? 1.5 : 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: isVip
                ? _gold.withOpacity(0.1)
                : Colors.black.withOpacity(isDark ? 0.15 : 0.02),
            blurRadius: isVip ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. الترتيب (Rank)
          SizedBox(
            width: 28,
            child: Center(child: rankWidget),
          ),
          const SizedBox(width: 8),

          // 2. الأفاتار المخصص مع التاج الملكي
          AvatarHelper.buildAvatarWidget(
            avatarId: entry.avatarId,
            gender: entry.gender,
            radius: 19,
            isPremium: isVip,
            showCrown: isVip,
          ),
          const SizedBox(width: 12),

          // 3. اسم الطالب والتفاصيل السريعة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _formatDisplayName(entry.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isVip
                              ? (isDark ? const Color(0xFFFDE047) : const Color(0xFFB45309))
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ),
                    ),
                    if (isVip) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFACC15), Color(0xFFD97706)],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'VIP 👑',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ],
                    if (isMe) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'أنت',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.quizzesCount} اختبار • أعلى نسبة ${entry.highestPercentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // 4. مجموع النقاط
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isVip
                  ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF3C7))
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isVip
                    ? _gold.withOpacity(0.5)
                    : (rank <= 3
                        ? rankColor.withOpacity(0.4)
                        : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE2E8F0))),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: isVip ? _gold : (rank <= 3 ? rankColor : const Color(0xFFF59E0B)),
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  '$score',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    color: isVip
                        ? (isDark ? const Color(0xFFFDE047) : const Color(0xFFB45309))
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayName(String name) {
    if (name.contains('@')) {
      final part = name.split('@').first.trim();
      return part.isNotEmpty ? part : 'طالب متميز';
    }
    return name.trim().isNotEmpty ? name.trim() : 'طالب متميز';
  }
}
