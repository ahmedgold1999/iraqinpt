import 'package:flutter/material.dart';

class AvatarData {
  final String id;
  final String name;
  final String emoji;
  final String gender; // 'male', 'female', 'unspecified'
  final List<Color> gradientColors;
  final Color borderColor;

  const AvatarData({
    required this.id,
    required this.name,
    required this.emoji,
    required this.gender,
    required this.gradientColors,
    required this.borderColor,
  });
}

class AvatarHelper {
  // 5 أفتارات شباب
  static const List<AvatarData> maleAvatars = [
    AvatarData(
      id: 'boy_1',
      name: 'شاب طموح',
      emoji: '👦',
      gender: 'male',
      gradientColors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
      borderColor: Color(0xFF60A5FA),
    ),
    AvatarData(
      id: 'boy_2',
      name: 'طالب متفوق',
      emoji: '👨‍🎓',
      gender: 'male',
      gradientColors: [Color(0xFF4F46E5), Color(0xFF4338CA)],
      borderColor: Color(0xFF818CF8),
    ),
    AvatarData(
      id: 'boy_3',
      name: 'تقني ومبرمج',
      emoji: '🧑‍💻',
      gender: 'male',
      gradientColors: [Color(0xFF0284C7), Color(0xFF0369A1)],
      borderColor: Color(0xFF38BDF8),
    ),
    AvatarData(
      id: 'boy_4',
      name: 'باحث ومعلم',
      emoji: '👨‍🏫',
      gender: 'male',
      gradientColors: [Color(0xFF059669), Color(0xFF047857)],
      borderColor: Color(0xFF34D399),
    ),
    AvatarData(
      id: 'boy_5',
      name: 'بطل التحدي',
      emoji: '🦸‍♂️',
      gender: 'male',
      gradientColors: [Color(0xFFEA580C), Color(0xFFC2410C)],
      borderColor: Color(0xFFFB923C),
    ),
  ];

  // 5 أفتارات بنات
  static const List<AvatarData> femaleAvatars = [
    AvatarData(
      id: 'girl_1',
      name: 'فتاة طموحة',
      emoji: '👧',
      gender: 'female',
      gradientColors: [Color(0xFFE11D48), Color(0xFFBE123C)],
      borderColor: Color(0xFFFB7185),
    ),
    AvatarData(
      id: 'girl_2',
      name: 'طالبة متفوقة',
      emoji: '👩‍🎓',
      gender: 'female',
      gradientColors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
      borderColor: Color(0xFFA78BFA),
    ),
    AvatarData(
      id: 'girl_3',
      name: 'تقنية ومبرمجة',
      emoji: '👩‍💻',
      gender: 'female',
      gradientColors: [Color(0xFFC026D3), Color(0xFFA21CAF)],
      borderColor: Color(0xFFE879F9),
    ),
    AvatarData(
      id: 'girl_4',
      name: 'باحثة ومعلمة',
      emoji: '👩‍🏫',
      gender: 'female',
      gradientColors: [Color(0xFFD97706), Color(0xFFB45309)],
      borderColor: Color(0xFFFBBF24),
    ),
    AvatarData(
      id: 'girl_5',
      name: 'بطلة التحدي',
      emoji: '🦸‍♀️',
      gender: 'female',
      gradientColors: [Color(0xFFDB2777), Color(0xFF9D174D)],
      borderColor: Color(0xFFF472B6),
    ),
  ];

  // 1 أفتار غير محدد / عام
  static const AvatarData defaultAvatar = AvatarData(
    id: 'general_1',
    name: 'طالب المعرفة',
    emoji: '🎓',
    gender: 'unspecified',
    gradientColors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    borderColor: Color(0xFFFACC15),
  );

  static List<AvatarData> getAllAvatars() {
    return [...maleAvatars, ...femaleAvatars, defaultAvatar];
  }

  static List<AvatarData> getAvatarsByGender(String gender) {
    if (gender == 'male') return maleAvatars;
    if (gender == 'female') return femaleAvatars;
    return [defaultAvatar];
  }

  static AvatarData getAvatar(String? avatarId, {String? fallbackGender}) {
    if (avatarId != null && avatarId.isNotEmpty) {
      final all = getAllAvatars();
      for (final a in all) {
        if (a.id == avatarId) return a;
      }
    }

    if (fallbackGender == 'male') return maleAvatars.first;
    if (fallbackGender == 'female') return femaleAvatars.first;
    return defaultAvatar;
  }

  /// بناء عنصر الأفاتار التفاعلي مع دعم إطار الـ VIP والتاج
  static Widget buildAvatarWidget({
    String? avatarId,
    String? gender,
    double radius = 24,
    bool isPremium = false,
    bool showCrown = false,
    VoidCallback? onTap,
  }) {
    final avatar = getAvatar(avatarId, fallbackGender: gender);

    Widget avatarContent = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isPremium
              ? [const Color(0xFFFACC15), const Color(0xFFD97706)]
              : avatar.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: isPremium ? const Color(0xFFFACC15) : avatar.borderColor,
          width: isPremium ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? const Color(0xFFFACC15) : avatar.gradientColors.first).withOpacity(0.35),
            blurRadius: isPremium ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          avatar.emoji,
          style: TextStyle(fontSize: radius * 0.95),
        ),
      ),
    );

    if (showCrown || isPremium) {
      avatarContent = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          avatarContent,
          Positioned(
            top: -radius * 0.45,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: const Text('👑', style: TextStyle(fontSize: 14)),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarContent,
      );
    }

    return avatarContent;
  }
}
