import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/avatar_helper.dart';

class LeaderboardManagementScreen extends StatefulWidget {
  const LeaderboardManagementScreen({super.key});

  @override
  State<LeaderboardManagementScreen> createState() => _LeaderboardManagementScreenState();
}

class _LeaderboardManagementScreenState extends State<LeaderboardManagementScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _subjectFilter = 'all'; // all, arabic, computer, english, premium
  String _sortBy = 'totalScore'; // totalScore, arabicScore, computerScore, englishScore, quizzesCount, highestPercentage

  List<DocumentSnapshot> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String s) {
    return s
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _db.collection('leaderboard').get();
      setState(() {
        _entries = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في جلب بيانات المتصدرين: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<DocumentSnapshot> get _filteredAndSortedEntries {
    var list = _entries.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final name = (data['name'] ?? '').toString();
      final uid = doc.id;

      if (_searchQuery.isNotEmpty) {
        final normQuery = _normalize(_searchQuery);
        final normName = _normalize(name);
        if (!normName.contains(normQuery) && !uid.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }

      if (_subjectFilter == 'premium') {
        if (data['isPremium'] != true) return false;
      } else if (_subjectFilter == 'arabic') {
        if ((data['arabicScore'] ?? 0) <= 0 && (data['totalScore'] ?? 0) <= 0) return false;
      } else if (_subjectFilter == 'computer') {
        if ((data['computerScore'] ?? 0) <= 0) return false;
      } else if (_subjectFilter == 'english') {
        if ((data['englishScore'] ?? 0) <= 0) return false;
      }

      return true;
    }).toList();

    list.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>? ?? {};
      final dataB = b.data() as Map<String, dynamic>? ?? {};

      num valA = 0;
      num valB = 0;

      switch (_sortBy) {
        case 'arabicScore':
          valA = dataA['arabicScore'] ?? 0;
          valB = dataB['arabicScore'] ?? 0;
          break;
        case 'computerScore':
          valA = dataA['computerScore'] ?? 0;
          valB = dataB['computerScore'] ?? 0;
          break;
        case 'englishScore':
          valA = dataA['englishScore'] ?? 0;
          valB = dataB['englishScore'] ?? 0;
          break;
        case 'quizzesCount':
          valA = dataA['quizzesCount'] ?? 0;
          valB = dataB['quizzesCount'] ?? 0;
          break;
        case 'highestPercentage':
          valA = dataA['highestPercentage'] ?? 0.0;
          valB = dataB['highestPercentage'] ?? 0.0;
          break;
        default:
          valA = dataA['totalScore'] ?? 0;
          valB = dataB['totalScore'] ?? 0;
      }

      return valB.compareTo(valA);
    });

    return list;
  }

  // ==========================================
  // حذف طالب من لوحة المتصدرين
  // ==========================================
  Future<void> _deleteEntry(String uid, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Text('حذف من المتصدرين', style: GoogleFonts.notoKufiArabic(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف الطالب "$name" من لوحة المتصدرين فقط؟\n(لن يتم مسح حساب الطالب، فقط سجله في قائمة الشرف).',
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('تأكيد الحذف', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.collection('leaderboard').doc(uid).delete();
        setState(() {
          _entries.removeWhere((doc) => doc.id == uid);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حذف $name من لوحة المتصدرين بنجاح 🗑️')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في الحذف: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ==========================================
  // تصفير لوحة المتصدرين بالكامل (Reset All)
  // ==========================================
  Future<void> _resetEntireLeaderboard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 30),
            const SizedBox(width: 8),
            Text('تصفير لوحة المتصدرين ⚠️', style: GoogleFonts.notoKufiArabic(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        content: const Text(
          'تحذير: سيتم مسح وحذف كافة سجلات الطلاب والنقاط في لوحة المتصدرين بالكامل لبدء موسم جديد!\n\nهل أنت متأكد تماماً من هذا الإجراء؟',
          style: TextStyle(fontFamily: 'Tajawal', fontSize: 13.5, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع', style: TextStyle(fontFamily: 'Tajawal'))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('نعم، مسح وتصفير الكل', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final batch = _db.batch();
        for (var doc in _entries) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        setState(() {
          _entries.clear();
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تصفير لوحة المتصدرين بنجاح! 🌟'), backgroundColor: Color(0xFF16A34A)),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ في التصفير: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  // ==========================================
  // نافذة تعديل أو إضافة متصدر
  // ==========================================
  void _showEditEntrySheet(BuildContext context, {DocumentSnapshot? doc}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNew = doc == null;
    final data = isNew ? <String, dynamic>{} : (doc.data() as Map<String, dynamic>? ?? {});

    final uidCtrl = TextEditingController(text: isNew ? '' : doc.id);
    final nameCtrl = TextEditingController(text: data['name'] ?? '');
    final totalScoreCtrl = TextEditingController(text: (data['totalScore'] ?? 0).toString());
    final arabicScoreCtrl = TextEditingController(text: (data['arabicScore'] ?? 0).toString());
    final compScoreCtrl = TextEditingController(text: (data['computerScore'] ?? 0).toString());
    final engScoreCtrl = TextEditingController(text: (data['englishScore'] ?? 0).toString());
    final quizzesCtrl = TextEditingController(text: (data['quizzesCount'] ?? 1).toString());
    final percentCtrl = TextEditingController(text: (data['highestPercentage'] ?? 100.0).toString());

    String selectedAvatarId = data['avatarId'] ?? 'boy_1';
    String selectedGender = data['gender'] ?? 'male';
    bool isPremium = data['isPremium'] == true;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isNew ? '➕ إضافة طالب للمتصدرين' : '✏️ تعديل بيانات المتصدر',
                      style: GoogleFonts.notoKufiArabic(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. اختيار وتخصيص الأفاتار
                      Text('🎨 اختيار وتغيير الأفاتار:', style: GoogleFonts.notoKufiArabic(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Center(
                        child: AvatarHelper.buildAvatarWidget(
                          avatarId: selectedAvatarId,
                          gender: selectedGender,
                          radius: 36,
                          isPremium: isPremium,
                          showCrown: isPremium,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('👦 شباب', style: TextStyle(fontFamily: 'Tajawal')),
                            selected: selectedGender == 'male',
                            onSelected: (v) => setSheetState(() {
                              selectedGender = 'male';
                              selectedAvatarId = AvatarHelper.maleAvatars.first.id;
                            }),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('👧 بنات', style: TextStyle(fontFamily: 'Tajawal')),
                            selected: selectedGender == 'female',
                            onSelected: (v) => setSheetState(() {
                              selectedGender = 'female';
                              selectedAvatarId = AvatarHelper.femaleAvatars.first.id;
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 70,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: AvatarHelper.getAvatarsByGender(selectedGender).map((av) {
                            final isSel = av.id == selectedAvatarId;
                            return GestureDetector(
                              onTap: () => setSheetState(() => selectedAvatarId = av.id),
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? const Color(0xFF2563EB) : Colors.transparent,
                                    width: 2.5,
                                  ),
                                ),
                                child: AvatarHelper.buildAvatarWidget(avatarId: av.id, gender: selectedGender, radius: 24),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // VIP Switch
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('طالب مميز VIP 👑', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('يظهر بإطار ذهبي وتاج المتفوقين', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey)),
                        value: isPremium,
                        activeColor: const Color(0xFFFACC15),
                        onChanged: (v) => setSheetState(() => isPremium = v),
                      ),
                      const Divider(height: 24),

                      // 2. بيانات الطالب والـ UID
                      if (isNew) ...[
                        TextField(
                          controller: uidCtrl,
                          decoration: InputDecoration(
                            labelText: 'معرف المستخدم (UID) أو كود عشوائي',
                            hintText: 'مثلاً: user_12345 أو UID الطالب',
                            prefixIcon: const Icon(Icons.fingerprint_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'اسم الطالب الكامل',
                          hintText: 'مثلاً: علي حسين كاظم',
                          prefixIcon: const Icon(Icons.person_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 3. الدرجات والنقاط
                      Text('🏆 درجات ونقاط المواد:', style: GoogleFonts.notoKufiArabic(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: totalScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'المجموع الكلي',
                                prefixIcon: const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: percentCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: 'أعلى نسبة (%)',
                                prefixIcon: const Icon(Icons.percent_rounded, color: Colors.green, size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: arabicScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'اللغة العربية',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: compScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'الحاسوب',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: engScoreCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'الإنجليزية',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: quizzesCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'عدد الاختبارات المنجزة',
                          prefixIcon: const Icon(Icons.quiz_rounded, size: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // زر الحفظ النهائي
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final targetUid = uidCtrl.text.trim();
                                  final name = nameCtrl.text.trim();
                                  if (targetUid.isEmpty || name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('يرجى ملء الاسم والمعرف UID')),
                                    );
                                    return;
                                  }

                                  setSheetState(() => isSaving = true);
                                  try {
                                    final totalScore = int.tryParse(totalScoreCtrl.text.trim()) ?? 0;
                                    final arabicScore = int.tryParse(arabicScoreCtrl.text.trim()) ?? 0;
                                    final compScore = int.tryParse(compScoreCtrl.text.trim()) ?? 0;
                                    final engScore = int.tryParse(engScoreCtrl.text.trim()) ?? 0;
                                    final quizzes = int.tryParse(quizzesCtrl.text.trim()) ?? 1;
                                    final percent = double.tryParse(percentCtrl.text.trim()) ?? 100.0;

                                    final entryData = {
                                      'name': name,
                                      'avatarId': selectedAvatarId,
                                      'gender': selectedGender,
                                      'isPremium': isPremium,
                                      'totalScore': totalScore,
                                      'arabicScore': arabicScore,
                                      'computerScore': compScore,
                                      'englishScore': engScore,
                                      'quizzesCount': quizzes,
                                      'highestPercentage': percent,
                                      'lastActive': FieldValue.serverTimestamp(),
                                    };

                                    await _db.collection('leaderboard').doc(targetUid).set(entryData, SetOptions(merge: true));
                                    if (ctx.mounted) Navigator.pop(ctx);
                                    _fetchLeaderboard();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم حفظ بيانات المتصدر بنجاح! ✨'), backgroundColor: Color(0xFF16A34A)),
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSaving = false);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(isNew ? 'إضافة للوحة المتصدرين 🚀' : 'حفظ التعديلات الشاملة 💾', style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 14.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = _filteredAndSortedEntries;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('إدارة لوحة المتصدرين 🏆', style: GoogleFonts.notoKufiArabic(fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'تحديث',
            onPressed: _fetchLeaderboard,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            tooltip: 'تصفير اللوحة بالكامل',
            onPressed: _resetEntireLeaderboard,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('إضافة طالب', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
        onPressed: () => _showEditEntrySheet(context),
      ),
      body: Column(
        children: [
          // 1. شريط البحث
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'ابحث باسم الطالب أو المعرف UID...',
                hintStyle: const TextStyle(fontFamily: 'Tajawal', fontSize: 13.5),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }))
                    : null,
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0))),
              ),
            ),
          ),

          // 2. فلاتر المواد
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterChip('الكل (${_entries.length})', 'all'),
                const SizedBox(width: 6),
                _buildFilterChip('العربية 📖', 'arabic'),
                const SizedBox(width: 6),
                _buildFilterChip('الحاسوب 💻', 'computer'),
                const SizedBox(width: 6),
                _buildFilterChip('الإنجليزية 🇬🇧', 'english'),
                const SizedBox(width: 6),
                _buildFilterChip('VIP المميزون 👑', 'premium'),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // 3. قائمة المتصدرين
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text('لا يوجد طلاب في لوحة المتصدرين حالياً', style: GoogleFonts.notoKufiArabic(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                        physics: const BouncingScrollPhysics(),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final doc = items[index];
                          final data = doc.data() as Map<String, dynamic>? ?? {};
                          final rank = index + 1;
                          final name = data['name'] ?? 'طالب متميز';
                          final totalScore = data['totalScore'] ?? 0;
                          final avatarId = data['avatarId']?.toString();
                          final gender = data['gender']?.toString();
                          final isPremium = data['isPremium'] == true;
                          final quizzes = data['quizzesCount'] ?? 0;
                          final percent = (data['highestPercentage'] ?? 0.0).toString();

                          Color rankColor = const Color(0xFF64748B);
                          String rankBadge = '#$rank';
                          if (rank == 1) {
                            rankColor = const Color(0xFFF59E0B);
                            rankBadge = '🥇 #1';
                          } else if (rank == 2) {
                            rankColor = const Color(0xFF94A3B8);
                            rankBadge = '🥈 #2';
                          } else if (rank == 3) {
                            rankColor = const Color(0xFFB45309);
                            rankBadge = '🥉 #3';
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: rank <= 3 ? rankColor.withOpacity(0.4) : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                                width: rank <= 3 ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  // الرتبة
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: rankColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      rankBadge,
                                      style: TextStyle(
                                        fontFamily: 'Tajawal',
                                        fontSize: rank <= 3 ? 13 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: rankColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // الأفاتار
                                  AvatarHelper.buildAvatarWidget(
                                    avatarId: avatarId,
                                    gender: gender,
                                    radius: 22,
                                    isPremium: isPremium,
                                    showCrown: isPremium,
                                  ),
                                  const SizedBox(width: 12),

                                  // تفاصيل الطالب
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: GoogleFonts.notoKufiArabic(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (isPremium)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFACC15),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text('VIP', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '⭐ $totalScore نقطة • $quizzes اختبارات • %$percent',
                                          style: const TextStyle(
                                            fontFamily: 'Tajawal',
                                            fontSize: 11.5,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // أزرار التحكم (تعديل وحذف)
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 20),
                                    tooltip: 'تعديل شامل',
                                    onPressed: () => _showEditEntrySheet(context, doc: doc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                                    tooltip: 'حذف من المتصدرين',
                                    onPressed: () => _deleteEntry(doc.id, name),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _subjectFilter == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      selected: isSelected,
      selectedColor: const Color(0xFF2563EB).withOpacity(0.15),
      labelStyle: TextStyle(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B)),
      onSelected: (v) => setState(() => _subjectFilter = value),
    );
  }
}
