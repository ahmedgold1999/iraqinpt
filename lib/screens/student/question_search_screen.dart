import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/question_model.dart';
import '../../services/question_service.dart';
import '../../services/tts_service.dart';
import 'subscription_screen.dart';

class QuestionSearchScreen extends StatefulWidget {
  const QuestionSearchScreen({super.key});

  @override
  State<QuestionSearchScreen> createState() => _QuestionSearchScreenState();
}

class _QuestionSearchScreenState extends State<QuestionSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  String _selectedSubject = 'arabic';
  final Map<String, String> _subjectNames = {
    'arabic': 'اللغة العربية',
    'computer': 'الحاسوب',
    'english': 'اللغة الإنجليزية',
  };

  // تخزين الأسئلة المحملة حسب المادة لتجنب إعادة التحميل
  final Map<String, List<Question>> _cachedQuestions = {};
  List<Question> _currentSubjectQuestions = [];
  List<Question> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSubjectQuestions(_selectedSubject);
  }

  Future<void> _loadSubjectQuestions(String subjectKey) async {
    // حماية المواد المدفوعة (الحاسوب والإنكليزي)
    if (subjectKey == 'computer' || subjectKey == 'english') {
      bool isPremium = false;
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists && doc.data()?['isPremium'] == true) {
            final expRaw = doc.data()!['expiryDate'] ?? doc.data()!['premiumUntil'];
            DateTime? exp;
            if (expRaw is Timestamp) exp = expRaw.toDate();
            if (expRaw is String) exp = DateTime.tryParse(expRaw);
            if (exp == null || exp.isAfter(DateTime.now())) {
              isPremium = true;
            }
          }
        }
      } catch (_) {}

      if (!isPremium) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🔒 البحث في أسئلة الحاسوب والإنكليزي متاح فقط لمشتركي VIP.',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
            ),
            backgroundColor: Color(0xFFD97706),
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
        );
        return;
      }
    }

    if (_cachedQuestions.containsKey(subjectKey)) {
      setState(() {
        _selectedSubject = subjectKey;
        _currentSubjectQuestions = _cachedQuestions[subjectKey]!;
        _filterResults(_searchController.text);
      });
      return;
    }

    setState(() {
      _selectedSubject = subjectKey;
      _isLoading = true;
    });

    final url = QuestionService.defaultSubjectUrls[subjectKey] ?? '';
    List<Question> list = [];
    if (url.isNotEmpty) {
      try {
        list = await QuestionService.loadQuestions(url);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _cachedQuestions[subjectKey] = list;
        _currentSubjectQuestions = list;
        _isLoading = false;
        _filterResults(_searchController.text);
      });
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          _filterResults(query);
        });
      }
    });
  }

  void _filterResults(String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      _searchResults = [];
      return;
    }

    final matched = _currentSubjectQuestions.where((q) {
      final qText = q.question.toLowerCase();
      final qAnswer = q.answer.toLowerCase();
      final qExplanation = (q.explanation ?? '').toLowerCase();
      return qText.contains(cleanQuery) ||
          qAnswer.contains(cleanQuery) ||
          qExplanation.contains(cleanQuery);
    }).take(40).toList(); // أقصى حد 40 نتيجة لتفادي أي تعليق

    _searchResults = matched;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
            Icon(Icons.search_rounded, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 8),
            Text(
              'البحث في بنك الأسئلة',
              style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // شريط اختيار المادة (عربي / حاسوب / إنجليزي)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _subjectNames.entries.map((entry) {
                final isSelected = _selectedSubject == entry.key;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Center(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : null,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: const Color(0xFF2563EB),
                      onSelected: (selected) {
                        if (selected && !isSelected) {
                          _loadSubjectQuestions(entry.key);
                        }
                      },
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // شريط البحث الذكي
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'ابحث في أسئلة ${_subjectNames[_selectedSubject]}...',
                hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF131C31) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // عداد الأسئلة أو النتائج
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchController.text.isEmpty
                      ? 'إجمالي أسئلة المادة: ${_currentSubjectQuestions.length}'
                      : 'النتائج المطابقة: ${_searchResults.length}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_searchController.text.isNotEmpty && _searchResults.length >= 40)
                  const Text(
                    '(عرض أول 40 نتيجة لسرعة الأداء)',
                    style: TextStyle(fontFamily: 'Tajawal', fontSize: 11, color: Colors.orange),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // المحتوى
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchController.text.trim().isEmpty
                    ? _buildSearchPromptState(isDark)
                    : _searchResults.isEmpty
                        ? _buildNoResultsState(isDark)
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final q = _searchResults[index];
                              return _buildQuestionCard(q, isDark);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPromptState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.manage_search_rounded, size: 55, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 16),
            Text(
              'محرك بحث أسئلة ${_subjectNames[_selectedSubject]}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اكتب أي كلمة، قاعدة، أو مصطلح في شريط البحث بالأعلى لعرض الأسئلة المتعلقة بها فوراً وبأقصى سرعة.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12.5,
                color: isDark ? Colors.white60 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 55, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'لا توجد أسئلة تطابق "${_searchController.text}"',
            style: const TextStyle(fontFamily: 'Tajawal', fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'جرب البحث بكلمة أخرى أو غيّر المادة من الأعلى',
            style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question q, bool isDark) {
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
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _subjectNames[_selectedSubject] ?? 'سؤال معتمد',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Color(0xFF2563EB),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 20, color: Color(0xFF2563EB)),
                tooltip: 'استماع',
                onPressed: () => TtsService().speak(q.question),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            q.question,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 14.5,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          // الإجابة النموذجية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C853).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF00C853), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الإجابة النموذجية: ${q.answer}',
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
          if (q.explanation != null && q.explanation!.isNotEmpty) ...[
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
                      'الشرح: ${q.explanation}',
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
