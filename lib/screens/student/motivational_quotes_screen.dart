import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/motivational_service.dart';
import '../../widgets/motivational_story_dialog.dart';

class MotivationalQuotesScreen extends StatefulWidget {
  const MotivationalQuotesScreen({super.key});

  @override
  State<MotivationalQuotesScreen> createState() => _MotivationalQuotesScreenState();
}

class _MotivationalQuotesScreenState extends State<MotivationalQuotesScreen> {
  String _selectedCategory = 'all';
  final MotivationalService _service = MotivationalService();

  final Map<String, String> _categories = {
    'all': 'الكل 🌟',
    'competitive_exam': 'الامتحان التنافسي 🎯',
    'mindset': 'التركيز والهمة 🧠',
    'perseverance': 'الصبر والمثابرة ⏳',
    'research': 'شغف البحث العلمي 📚',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'ومضات تحفيز الدراسات العليا',
          style: GoogleFonts.notoKufiArabic(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<AcademicQuote>>(
        stream: _service.getQuotesStream(),
        builder: (context, snapshot) {
          final allQuotes = snapshot.data ?? MotivationalService.defaultQuotes;
          final filteredQuotes = _selectedCategory == 'all'
              ? allQuotes
              : allQuotes.where((q) => q.category == _selectedCategory).toList();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. ترويسة تشجيعية فاخرة
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF312E81)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Color(0xFFFACC15),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'زادك الأكاديمي لرحلة القبول 🎓',
                                style: GoogleFonts.notoKufiArabic(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'رسائل وومضات شُحذت همتها لترافقك حتى إعلان نتائج القبول والظفر بالمقعد.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Tajawal',
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. تصنيفات الومضات
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 46,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final key = _categories.keys.elementAt(index);
                      final label = _categories[key]!;
                      final isSelected = _selectedCategory == key;

                      return InkWell(
                        onTap: () => setState(() => _selectedCategory = key),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : (isDark ? const Color(0xFF1E293B) : Colors.white),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 12.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 16)),

              // 3. قائمة البطاقات التحفيزية
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final quote = filteredQuotes[index];
                      return _buildQuoteCard(quote, isDark);
                    },
                    childCount: filteredQuotes.length,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildQuoteCard(AcademicQuote quote, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.format_quote_rounded,
                  color: Color(0xFF38BDF8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quote.text,
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, size: 15, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 5),
                  Text(
                    quote.author,
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    tooltip: 'نسخ العبارة',
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: '${quote.text}\n— ${quote.author}'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم نسخ العبارة التحفيزية بنجاح 📋'),
                          backgroundColor: Color(0xFF10B981),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => MotivationalStoryDialog.show(context, quote),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE1306C), Color(0xFF833AB4)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_camera_back_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            'ستوري',
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
