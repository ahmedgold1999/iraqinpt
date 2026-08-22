import 'package:flutter/material.dart';
import '../../models/question_model.dart';
import '../../services/mistake_vault_service.dart';
import '../../services/tts_service.dart';
import 'quiz_screen.dart';

class MistakesScreen extends StatefulWidget {
  const MistakesScreen({super.key});

  @override
  State<MistakesScreen> createState() => _MistakesScreenState();
}

class _MistakesScreenState extends State<MistakesScreen> {
  String _selectedSubject = 'all';
  List<MistakeItem> _mistakes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMistakes();
  }

  Future<void> _loadMistakes() async {
    setState(() => _isLoading = true);
    final list = await MistakeVaultService.getMistakes(
      subjectKey: _selectedSubject == 'all' ? null : _selectedSubject,
    );
    if (mounted) {
      setState(() {
        _mistakes = list;
        _isLoading = false;
      });
    }
  }

  void _startMistakesQuiz() {
    if (_mistakes.isEmpty) return;

    final questions = _mistakes.map((m) => m.question).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          subject: 'اختبار مراجعة الأخطاء',
          questionsUrl: '',
          initialQuestions: questions,
        ),
      ),
    ).then((_) => _loadMistakes());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.psychology_alt_rounded, color: Color(0xFFEF4444), size: 26),
            SizedBox(width: 8),
            Text(
              'بنك أخطائي الذكي',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 19),
            ),
          ],
        ),
        actions: [
          if (_mistakes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              tooltip: 'مسح جميع الأخطاء',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('مسح بنك الأخطاء', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                    content: const Text('هل أنت متأكد من رغبتك في حذف جميع الأسئلة المحفوظة في بنك الأخطاء؟', style: TextStyle(fontFamily: 'Tajawal')),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal'))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('مسح', style: TextStyle(fontFamily: 'Tajawal', color: Colors.white)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await MistakeVaultService.clearAllMistakes();
                  _loadMistakes();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // شريط فلترة المواد
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip('all', 'الكل (${_mistakes.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('arabic', 'اللغة العربية'),
                  const SizedBox(width: 8),
                  _buildFilterChip('computer', 'الحاسوب'),
                  const SizedBox(width: 8),
                  _buildFilterChip('english', 'اللغة الإنجليزية'),
                ],
              ),
            ),
          ),

          // قائمة الأسئلة أو الحالة الفارغة
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _mistakes.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _mistakes.length,
                        itemBuilder: (context, index) {
                          final item = _mistakes[index];
                          return _buildMistakeCard(item, isDark);
                        },
                      ),
          ),
        ],
      ),
      bottomNavigationBar: _mistakes.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131C31) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton.icon(
                  onPressed: _startMistakesQuiz,
                  icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                  label: Text(
                    'بدء اختبار معالجة الأخطاء (${_mistakes.length} سؤال)',
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedSubject == key;
    return ChoiceChip(
      label: Text(
        label,
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
          setState(() => _selectedSubject = key);
          _loadMistakes();
        }
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded, size: 70, color: Color(0xFF00C853)),
          ),
          const SizedBox(height: 18),
          Text(
            'لا توجد أخطاء مسجلة!',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'ممتاز جداً! أي سؤال تخطئ فيه في الاختبارات القادمة سيتم حفظه هنا تلقائياً لتراجعه لاحقاً.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontFamily: 'Tajawal', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMistakeCard(MistakeItem item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.subjectName,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFFEF4444),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.volume_up_rounded, size: 20, color: Color(0xFF2563EB)),
                    tooltip: 'استماع للسؤال',
                    onPressed: () => TtsService().speak(item.question.question),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 20, color: Color(0xFF00C853)),
                    tooltip: 'أتقنت هذا السؤال (إزالة)',
                    onPressed: () async {
                      await MistakeVaultService.removeMistake(item.question.question);
                      _loadMistakes();
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.question.question,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // إجابتك الخاطئة
          if (item.selectedWrongAnswer.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'إجابتك السابقة: ${item.selectedWrongAnswer}',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        color: Color(0xFFEF4444),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // الإجابة الصحيحة
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_rounded, color: Color(0xFF00C853), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الإجابة النموذجية: ${item.question.answer}',
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Color(0xFF00C853),
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (item.question.explanation != null && item.question.explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'الشرح: ${item.question.explanation}',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
