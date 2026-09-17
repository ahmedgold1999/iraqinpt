import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/sound_effects_service.dart';
import '../../services/question_service.dart';
import '../../models/question_model.dart';

class TrueFalseItem {
  final int id;
  final String statement;
  final bool isTrue;
  final String subject;
  final String explanation;

  const TrueFalseItem({
    required this.id,
    required this.statement,
    required this.isTrue,
    required this.subject,
    required this.explanation,
  });
}

class TrueFalseQuizScreen extends StatefulWidget {
  final String? initialSubject;
  const TrueFalseQuizScreen({super.key, this.initialSubject});

  @override
  State<TrueFalseQuizScreen> createState() => _TrueFalseQuizScreenState();
}

class _TrueFalseQuizScreenState extends State<TrueFalseQuizScreen> with SingleTickerProviderStateMixin {
  // بنك عبارات صح وخطأ وزارية نموذجية شاملة (40 عبارة)
  static const List<TrueFalseItem> _allStatements = [
    // 📖 اللغة العربية
    TrueFalseItem(
      id: 1,
      statement: 'الاسم النكرة المنصوب الواقع بعد ألفاظ العقود (من 20 إلى 90) يُعرب دائماً تمييزاً مفرداً.',
      isTrue: true,
      subject: 'عربي',
      explanation: 'صحيح، مثل: "اشتريتُ عشرينَ كتاباً"، كتاباً: تمييز منصوب.',
    ),
    TrueFalseItem(
      id: 2,
      statement: 'همزة الفعل الخماسي والسداسي في الماضي والأمر والمصدر هي همزة قطع.',
      isTrue: false,
      subject: 'عربي',
      explanation: 'خطأ، همزة الخماسي والسداسي (مثل: استغفر، انطلق، استغفار) هي همزة وصل دائماً.',
    ),
    TrueFalseItem(
      id: 3,
      statement: 'تُعرب (ما) في جملة "إنما المؤمنون إخوة" كافة ومكفوفة تكف (إنّ) عن العمل.',
      isTrue: true,
      subject: 'عربي',
      explanation: 'صحيح، دخول ما الزائدة الكافة على إنّ يكفها عن النصب ويعرب ما بعدها مبتدأ.',
    ),
    TrueFalseItem(
      id: 4,
      statement: 'كان وأخواتها أفعال ناسخة تنصب المبتدأ وترفع الخبر.',
      isTrue: false,
      subject: 'عربي',
      explanation: 'خطأ، كان وأخواتها ترفع المبتدأ اسماً لها وتنصب الخبر خبراً لها (إنّ وأخواتها هي التي تنصب المبتدأ).',
    ),
    TrueFalseItem(
      id: 5,
      statement: 'اسم لا النافية للجنس إذا كان مضافاً أو شبيهاً بالمضاف يكون معرباً منصوباً.',
      isTrue: true,
      subject: 'عربي',
      explanation: 'صحيح، يبنى على الفتح فقط إذا كان مفرداً، أما المضاف والشبيه بالمضاف فيكون معرباً منصوباً.',
    ),
    TrueFalseItem(
      id: 6,
      statement: 'الاسم المنقوص تُحذف ياؤه في حالتي الرفع والجر إذا كان نكرة غير مضاف.',
      isTrue: true,
      subject: 'عربي',
      explanation: 'صحيح، مثل: "جاء قاضٍ" و "مررتُ بقاضٍ".',
    ),
    TrueFalseItem(
      id: 7,
      statement: 'المفعول لأجله هو اسم منصوب يدل على مكان وقوع الفعل.',
      isTrue: false,
      subject: 'عربي',
      explanation: 'خطأ، المفعول لأجله يبين سبب وعلة وقوع الفعل (مثل: رغبةً في العلم)، بينما ظرف المكان يبين مكان الفعل.',
    ),
    TrueFalseItem(
      id: 8,
      statement: 'جمع المؤنث السالم يُنصب بالكسرة نيابة عن الفتحة.',
      isTrue: true,
      subject: 'عربي',
      explanation: 'صحيح، مثل: "كافأتُ المعلماتِ"، المعلماتِ: مفعول به منصوب بالكسرة.',
    ),
    TrueFalseItem(
      id: 9,
      statement: 'تُكتب الألف اللينة مقصورة (ى) في أواخر الأفعال الثلاثية إذا كان أصلها واواً.',
      isTrue: false,
      subject: 'عربي',
      explanation: 'خطأ، إذا كان أصلها واواً تكتب ممدودة (دعا يدعو)، وإذا كان أصلها ياء تكتب مقصورة (رمى يرمي).',
    ),
    TrueFalseItem(
      id: 10,
      statement: 'لا النافية للفعل المضارع تجزمه وتسكن آخره.',
      isTrue: false,
      subject: 'عربي',
      explanation: 'خطأ، لا النافية لا تجزم بل يبقى الفعل بعدها مرفوعاً، بينما (لا الناهية الجازمة) هي التي تجزم.',
    ),

    // 💻 علوم الحاسوب
    TrueFalseItem(
      id: 11,
      statement: 'يتكون عنوان IPv6 الحديث من 128 بت (Bits).',
      isTrue: true,
      subject: 'حاسوب',
      explanation: 'صحيح، IPv6 طوله 128 بت بينما IPv4 القديم طوله 32 بت.',
    ),
    TrueFalseItem(
      id: 12,
      statement: 'ذاكرة الوصول العشوائي (RAM) هي ذاكرة غير متطايرة تحتفظ بالبيانات عند انقطاع الكهرباء.',
      isTrue: false,
      subject: 'حاسوب',
      explanation: 'خطأ، RAM ذاكرة متطايرة (Volatile) تفقد محتواها عند إطفاء الجهاز، بينما ROM و SSD غير متطايرة.',
    ),
    TrueFalseItem(
      id: 13,
      statement: 'بروتوكول DHCP هو المسؤول عن تعيين عناوين IP للأجهزة في الشبكة تلقائياً.',
      isTrue: true,
      subject: 'حاسوب',
      explanation: 'صحيح، DHCP يوزع عناوين الـ IP والإعدادات ديناميكياً للأجهزة المتصلة.',
    ),
    TrueFalseItem(
      id: 14,
      statement: 'المنفذ الافتراضي لبروتوكول تصفح الويب الآمن (HTTPS) هو Port 80.',
      isTrue: false,
      subject: 'حاسوب',
      explanation: 'خطأ، منفذ HTTP العادي هو 80 بينما HTTPS الآمن والمشفر هو 443.',
    ),
    TrueFalseItem(
      id: 15,
      statement: 'بروتوكول UDP أسرع من TCP ولكنه لا يضمن وصول حزم البيانات بدون فقدان.',
      isTrue: true,
      subject: 'حاسوب',
      explanation: 'صحيح، UDP غير متصل (Connectionless) وسريع جداً للبث والألعاب، بينما TCP يضمن وصول البيانات (Reliable).',
    ),
    TrueFalseItem(
      id: 16,
      statement: 'الذاكرة المخبأة (Cache Memory) أبطأ في السرعة من القرص الصلب (Hard Disk).',
      isTrue: false,
      subject: 'حاسوب',
      explanation: 'خطأ، الـ Cache هي أسرع ذاكرة في الحاسوب بعد مسجلات المعالج (Registers).',
    ),
    TrueFalseItem(
      id: 17,
      statement: 'بروتوكول DNS يقوم بترجمة أسماء النطاقات (مثل google.com) إلى عناوين IP رقمية.',
      isTrue: true,
      subject: 'حاسوب',
      explanation: 'صحيح، DNS يعمل كدليل هاتف الإنترنت لترجمة الأسماء إلى IPs.',
    ),
    TrueFalseItem(
      id: 18,
      statement: 'تقنية التشفير المتماثل (Symmetric) تستخدم مفتاحين مختلفين: أحدهما عام والآخر خاص.',
      isTrue: false,
      subject: 'حاسوب',
      explanation: 'خطأ، التشفير المتماثل يستخدم مفتاحاً واحداً فقط للتشفير وفك التشفير، بينما غير المتماثل (Asymmetric) يستخدم زوج مفاتيح.',
    ),
    TrueFalseItem(
      id: 19,
      statement: 'نظام الملفات NTFS يدعم صلاحيات الأمان والملفات الأكبر من 4GB مقارنة بـ FAT32.',
      isTrue: true,
      subject: 'حاسوب',
      explanation: 'صحيح، NTFS هو النظام القياسي لويندوز ويدعم الأمان والملفات الضخمة.',
    ),
    TrueFalseItem(
      id: 20,
      statement: 'برنامج BIOS مخزن على ذاكرة RAM ويفقد إعداداته عند إيقاف تشغيل الحاسوب.',
      isTrue: false,
      subject: 'حاسوب',
      explanation: 'خطأ، BIOS مخزن على شريحة ROM/Flash غير متطايرة على اللوحة الأم.',
    ),

    // 🇬🇧 اللغة الإنجليزية
    TrueFalseItem(
      id: 21,
      statement: 'In English, the Past Perfect tense (had + V3) is used for an action that happened before another past action.',
      isTrue: true,
      subject: 'إنكليزي',
      explanation: 'صحيح، الماضي التام يُستخدم للحدث الأقدم الذي وقع قبل حدث ماضٍ آخر.',
    ),
    TrueFalseItem(
      id: 22,
      statement: 'The sentence "She don\'t like apples" is grammatically correct.',
      isTrue: false,
      subject: 'إنكليزي',
      explanation: 'خطأ، مع الضمائر المفردة (He, She, It) نستخدم doesn\'t وليس don\'t.',
    ),
    TrueFalseItem(
      id: 23,
      statement: 'In the Second Conditional, the if-clause uses the past simple tense.',
      isTrue: true,
      subject: 'إنكليزي',
      explanation: 'صحيح، القاعدة: If + Past Simple, would + infinitive (مثال: If I had money, I would travel).',
    ),
    TrueFalseItem(
      id: 24,
      statement: 'The past participle form of the irregular verb "Write" is "Wrote".',
      isTrue: false,
      subject: 'إنكليزي',
      explanation: 'خطأ، Wrote هو الماضي البسيط (V2)، بينما التصريف الثالث (V3) هو Written.',
    ),
    TrueFalseItem(
      id: 25,
      statement: 'The word "Enormous" is an antonym (opposite) of "Tiny".',
      isTrue: true,
      subject: 'إنكليزي',
      explanation: 'صحيح، Enormous تعني هائل وضخم، وهي عكس كلمة Tiny التي تعني ضئيل جداً.',
    ),
    TrueFalseItem(
      id: 26,
      statement: 'We use the preposition "in" with specific days of the week like "in Monday".',
      isTrue: false,
      subject: 'إنكليزي',
      explanation: 'خطأ، نستخدم حرف الجر on مع أيام الأسبوع (on Monday, on Friday).',
    ),
    TrueFalseItem(
      id: 27,
      statement: 'In passive voice, the object of the active sentence becomes the subject of the passive sentence.',
      isTrue: true,
      subject: 'إنكليزي',
      explanation: 'صحيح، في المبني للمجهول يتحول المفعول به في الجملة الأصلية إلى نائب فاعل (مبتدأ الجملة الجديدة).',
    ),
    TrueFalseItem(
      id: 28,
      statement: 'The comparative form of the adjective "Good" is "Gooder".',
      isTrue: false,
      subject: 'إنكليزي',
      explanation: 'خطأ، Good صفة شاذة ومقارنتها هي Better والتفضيل Best.',
    ),
    TrueFalseItem(
      id: 29,
      statement: 'Modal verbs like (can, must, should) are always followed by the base form of the verb.',
      isTrue: true,
      subject: 'إنكليزي',
      explanation: 'صحيح، الأفعال الناقصة يتبعها دائماً مصدر الفعل مجرداً (Infinitive without to).',
    ),
    TrueFalseItem(
      id: 30,
      statement: 'The plural of "Criterion" is "Criterions".',
      isTrue: false,
      subject: 'إنكليزي',
      explanation: 'خطأ، جمع كلمة Criterion هو Criteria (جمع غير قياسي ذو أصل لاتيني/يوناني).',
    ),

    // 🧠 الثقافة العامة والتنافسي
    TrueFalseItem(
      id: 31,
      statement: 'الوسط الحسابي (Mean) هو المقياس الإحصائي الأكثر تأثراً بالقيم المتطرفة والشاذة.',
      isTrue: true,
      subject: 'عام',
      explanation: 'صحيح، لأن الوسط يعتمد على جمع كافة القيم، بينما الوسيط (Median) لا يتأثر بالقيم الشاذة.',
    ),
    TrueFalseItem(
      id: 32,
      statement: 'الزاوية بين عقربي الساعة عند تمام الساعة 3:00 هي زاوية حادة قياسها 45 درجة.',
      isTrue: false,
      subject: 'عام',
      explanation: 'خطأ، عند الساعة 3:00 تكون الزاوية قائمة وقياسها 90 درجة (3 ساعات × 30 درجة = 90).',
    ),
    TrueFalseItem(
      id: 33,
      statement: 'البحث الوصفي يهدف إلى دراسة الواقع كما هو وتحديده بدقة دون التدخل لتغييره.',
      isTrue: true,
      subject: 'عام',
      explanation: 'صحيح، المنهج الوصفي يصف الظاهرة ويفسرها كما هي في الواقع.',
    ),
    TrueFalseItem(
      id: 34,
      statement: 'المتغير المستقل في البحث العلمي هو الذي يتأثر بالمتغير التابع.',
      isTrue: false,
      subject: 'عام',
      explanation: 'خطأ، المتغير المستقل (Independent) هو الذي يُحدث التأثير، والمتغير التابع (Dependent) هو الذي يتأثر به.',
    ),
    TrueFalseItem(
      id: 35,
      statement: 'النسبة المئوية 25% تكافئ الكسر العادي 1/4.',
      isTrue: true,
      subject: 'عام',
      explanation: 'صحيح، 25 / 100 = 1 / 4.',
    ),
    TrueFalseItem(
      id: 36,
      statement: 'الانحراف المعياري هو الجذر التربيعي للتباين ويقيس تشتت البيانات حول وسطها الحسابي.',
      isTrue: true,
      subject: 'عام',
      explanation: 'صحيح، الانحراف المعياري هو المقياس القياسي لتشتت وتجانس البيانات.',
    ),
    TrueFalseItem(
      id: 37,
      statement: 'في التفكير المنطقي، إذا كانت العبارة "كل الطلاب ناجحون" صحيحة، فإن "بعض الطلاب راسبون" تكون صحيحة أيضاً.',
      isTrue: false,
      subject: 'عام',
      explanation: 'خطأ، هما قضيتان متناقضتان (لا تصدقان معاً ولا تكذبان معاً).',
    ),
    TrueFalseItem(
      id: 38,
      statement: 'العينة العشوائية البسيطة تعطي لكل فرد في المجتمع فرصة متساوية في الاختيار.',
      isTrue: true,
      subject: 'عام',
      explanation: 'صحيح، هذا هو التعريف العلمي الأساسي للعينة العشوائية البسيطة.',
    ),
    TrueFalseItem(
      id: 39,
      statement: 'مجموع زوايا المثلث الداخلية يساوي 360 درجة.',
      isTrue: false,
      subject: 'عام',
      explanation: 'خطأ، مجموع زوايا المثلث 180 درجة، ومجموع زوايا الشكل الرباعي 360 درجة.',
    ),
    TrueFalseItem(
      id: 40,
      statement: 'السرقة العلمية (Plagiarism) تشمل نقل أفكار ونصوص الآخرين دون الإشارة إلى المصدر الأصلي.',
      isTrue: true,
      subject: 'عام',
      explanation: 'صحيح، وهي مخالفة أكاديمية جسيمة في متطلبات الدراسات العليا.',
    ),
  ];

  String _selectedSubject = 'الكل';
  List<TrueFalseItem> _quizList = [];
  int _currentIndex = 0;
  int _score = 0;
  int _streak = 0;
  int _maxStreak = 0;
  bool _answered = false;
  bool? _lastUserChoice;
  bool _isQuizFinished = false;
  bool _isLoadingQuestions = false;

  // Timer: 10 seconds per statement
  int _timeLeft = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.initialSubject != null) {
      _selectedSubject = widget.initialSubject!;
    }
    _prepareQuiz();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _prepareQuiz() async {
    _timer?.cancel();
    setState(() {
      _isLoadingQuestions = true;
      _isQuizFinished = false;
      _quizList = [];
    });

    List<Question> loadedQuestions = [];

    try {
      if (_selectedSubject == 'عربي') {
        loadedQuestions = await QuestionService.loadQuestions(QuestionService.defaultSubjectUrls['arabic']!);
      } else if (_selectedSubject == 'حاسوب') {
        loadedQuestions = await QuestionService.loadQuestions(QuestionService.defaultSubjectUrls['computer']!);
      } else if (_selectedSubject == 'إنكليزي') {
        loadedQuestions = await QuestionService.loadQuestions(QuestionService.defaultSubjectUrls['english']!);
      } else {
        // 'الكل' أو 'عام'
        final results = await Future.wait([
          QuestionService.loadQuestions(QuestionService.defaultSubjectUrls['arabic']!),
          QuestionService.loadQuestions(QuestionService.defaultSubjectUrls['computer']!),
          QuestionService.loadQuestions(QuestionService.defaultSubjectUrls['english']!),
        ]);
        for (var list in results) {
          loadedQuestions.addAll(list);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading questions from JSON: $e');
    }

    List<TrueFalseItem> generatedItems = [];

    if (loadedQuestions.isNotEmpty) {
      loadedQuestions.shuffle();
      int idCounter = 1;
      final random = Random();

      for (final q in loadedQuestions) {
        if (q.question.trim().isEmpty || q.options.isEmpty) continue;

        // Check if question is a direct true/false
        final isBinary = q.options.length == 2 &&
            (q.options.any((o) => o.contains('صح') || o.toLowerCase().contains('true')) &&
             q.options.any((o) => o.contains('خطأ') || o.toLowerCase().contains('false')));

        if (isBinary) {
          final isTrue = q.answer.contains('صح') || q.answer.toLowerCase().contains('true');
          generatedItems.add(TrueFalseItem(
            id: idCounter++,
            statement: q.question.trim(),
            isTrue: isTrue,
            subject: _selectedSubject,
            explanation: q.explanation ?? (isTrue ? 'صحيح، العبارة دقيقة ومطابقة.' : 'خطأ، العبارة غير صحيحة.'),
          ));
        } else {
          // Generate True or False from MCQ
          final makeTrue = random.nextBool();
          if (makeTrue || q.options.length < 2) {
            generatedItems.add(TrueFalseItem(
              id: idCounter++,
              statement: 'فيما يخص "${q.question.trim()}"، فإن الجواب الصحيح هو: "${q.answer.trim()}".',
              isTrue: true,
              subject: _selectedSubject,
              explanation: q.explanation ?? 'صحيح، الإجابة الدقيقة هي: ${q.answer.trim()}',
            ));
          } else {
            final wrongOptions = q.options.where((opt) => opt.trim() != q.answer.trim()).toList();
            if (wrongOptions.isNotEmpty) {
              final wrongChoice = wrongOptions[random.nextInt(wrongOptions.length)];
              generatedItems.add(TrueFalseItem(
                id: idCounter++,
                statement: 'فيما يخص "${q.question.trim()}"، فإن الجواب هو: "${wrongChoice.trim()}".',
                isTrue: false,
                subject: _selectedSubject,
                explanation: q.explanation ?? 'خطأ، الإجابة الصحيحة هي: "${q.answer.trim()}" وليست "${wrongChoice.trim()}".',
              ));
            }
          }
        }

        if (generatedItems.length >= 25) break;
      }
    }

    // Fallback to offline ministerial bank if generated is empty
    if (generatedItems.isEmpty) {
      if (_selectedSubject == 'الكل') {
        generatedItems = List.from(_allStatements);
      } else {
        generatedItems = _allStatements.where((item) => item.subject == _selectedSubject).toList();
      }
      if (generatedItems.isEmpty) {
        generatedItems = List.from(_allStatements);
      }
      generatedItems.shuffle();
    }

    if (generatedItems.length > 15) {
      generatedItems = generatedItems.sublist(0, 15);
    }

    if (!mounted) return;

    setState(() {
      _isLoadingQuestions = false;
      _quizList = generatedItems;
      _currentIndex = 0;
      _score = 0;
      _streak = 0;
      _maxStreak = 0;
      _answered = false;
      _lastUserChoice = null;
      _isQuizFinished = false;
      _timeLeft = 10;
    });

    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    _timeLeft = 10;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft > 1) {
        setState(() => _timeLeft--);
      } else {
        _timer?.cancel();
        _handleAnswer(null); // Time's up
      }
    });
  }

  void _handleAnswer(bool? userChoice) {
    if (_answered || _isQuizFinished) return;
    _timer?.cancel();

    final currentItem = _quizList[_currentIndex];
    final isCorrect = userChoice != null && userChoice == currentItem.isTrue;

    if (isCorrect) {
      SoundEffectsService.playCorrectSound();
      _score += 10 + (_streak * 2); // Streak multiplier bonus
      _streak++;
      if (_streak > _maxStreak) _maxStreak = _streak;
      if (_streak >= 3) SoundEffectsService.playStreakSound();
    } else {
      SoundEffectsService.playWrongSound();
      _streak = 0;
    }

    setState(() {
      _answered = true;
      _lastUserChoice = userChoice;
    });
  }

  void _nextQuestion() {
    if (_currentIndex + 1 < _quizList.length) {
      setState(() {
        _currentIndex++;
        _answered = false;
        _lastUserChoice = null;
      });
      _startQuestionTimer();
    } else {
      setState(() {
        _isQuizFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.flash_on_rounded, color: Color(0xFFFACC15), size: 22),
            const SizedBox(width: 8),
            Text(
              'تحدي صح أم خطأ السريع',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              SoundEffectsService().isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: SoundEffectsService().isMuted ? Colors.grey : const Color(0xFF38BDF8),
            ),
            tooltip: SoundEffectsService().isMuted ? 'تفعيل المؤثرات الصوتية' : 'كتم المؤثرات الصوتية',
            onPressed: () {
              SoundEffectsService().toggleSound();
              setState(() {});
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    SoundEffectsService().isMuted ? 'تم كتم المؤثرات الصوتية 🔇' : 'تم تفعيل المؤثرات الصوتية 🔊',
                    style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: SoundEffectsService().isMuted ? const Color(0xFF64748B) : const Color(0xFF2563EB),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة الاختبار',
            onPressed: _prepareQuiz,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isQuizFinished ? _buildResultScreen(isDark) : _buildQuizBody(isDark),
    );
  }

  Widget _buildQuizBody(bool isDark) {
    if (_isLoadingQuestions) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            Text(
              'جاري تجهيز الأسئلة من بنك الأسئلة...',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    if (_quizList.isEmpty) {
      return const Center(child: Text('لا توجد أسئلة متوفرة', style: TextStyle(fontFamily: 'Tajawal')));
    }

    final currentItem = _quizList[_currentIndex];
    final progress = (_currentIndex + 1) / _quizList.length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          children: [
            // Top Filter Chips
            _buildSubjectFilter(isDark),
            const SizedBox(height: 12),

            // Top Status Bar: Progress + Timer + Score + Streak
            _buildStatusBar(isDark, progress),
            const SizedBox(height: 16),

            // Question Card
            Expanded(
              child: _buildStatementCard(isDark, currentItem),
            ),
            const SizedBox(height: 16),

            // True / False Control Buttons
            if (!_answered)
              _buildChoiceButtons()
            else
              _buildExplanationAndNext(isDark, currentItem),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectFilter(bool isDark) {
    final subjects = ['الكل', 'عربي', 'حاسوب', 'إنكليزي', 'عام'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: subjects.map((sub) {
          final isSelected = _selectedSubject == sub;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              label: Text(
                sub,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF6366F1),
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              onSelected: (val) {
                if (val && _selectedSubject != sub) {
                  setState(() => _selectedSubject = sub);
                  _prepareQuiz();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBar(bool isDark, double progress) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Question Number
              Text(
                'العبارة ${_currentIndex + 1} من ${_quizList.length}',
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 13),
              ),
              // Score & Streak
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '$_score نقطة',
                          style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_streak >= 2) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '🔥 $_streak Streak',
                        style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              // Timer countdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _timeLeft <= 3 ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF38BDF8).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _timeLeft <= 3 ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_timeLeft ث',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _timeLeft <= 3 ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatementCard(bool isDark, TrueFalseItem item) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag & Category
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'المادة: ${item.subject}',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6366F1),
                  ),
                ),
              ),
              const Text('هل العبارة صحيحة أم خاطئة؟ 🤔', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12, color: Colors.grey)),
            ],
          ),
          const Spacer(),

          // Statement text
          Center(
            child: Text(
              item.statement,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildChoiceButtons() {
    return Row(
      children: [
        // ❌ خطأ (False Button)
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () => _handleAnswer(false),
              icon: const Icon(Icons.close_rounded, size: 28),
              label: const Text(
                'خـطـأ',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                shadowColor: const Color(0xFFEF4444).withOpacity(0.4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // ✅ صح (True Button)
        Expanded(
          child: SizedBox(
            height: 60,
            child: ElevatedButton.icon(
              onPressed: () => _handleAnswer(true),
              icon: const Icon(Icons.check_rounded, size: 28),
              label: const Text(
                'صـح',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 4,
                shadowColor: const Color(0xFF10B981).withOpacity(0.4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExplanationAndNext(bool isDark, TrueFalseItem item) {
    final isCorrect = _lastUserChoice != null && _lastUserChoice == item.isTrue;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
            : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCorrect ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                color: isCorrect ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect ? 'إجابة صحيحة! أحسنت 🎉' : 'إجابة خاطئة! ❌',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isCorrect ? (isDark ? Colors.white : const Color(0xFF15803D)) : (isDark ? Colors.white : const Color(0xFFB91C1C)),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (item.isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.isTrue ? 'الحل: صح ✅' : 'الحل: خطأ ❌',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: item.isTrue ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.explanation,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                _currentIndex + 1 < _quizList.length ? 'العبارة التالية 👈' : 'عرض النتيجة النهائية 🏆',
                style: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen(bool isDark) {
    final percentage = ((_score / (_quizList.length * 10)) * 100).clamp(0, 100).toInt();

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚡ 🏆 ⚡', style: TextStyle(fontSize: 36)),
              const SizedBox(height: 10),
              Text(
                'اكتمل تحدي البرق!',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'نتيجتك في تثبيت القواعد والمفاهيم الوزارية',
                style: TextStyle(fontFamily: 'Tajawal', color: isDark ? Colors.white60 : Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Score Circle Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('$_score', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                        const Text('مجموع النقاط', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Tajawal')),
                      ],
                    ),
                    Container(height: 35, width: 1, color: Colors.white24),
                    Column(
                      children: [
                        Text('🔥 $_maxStreak', style: const TextStyle(color: Color(0xFFFDE68A), fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'Tajawal')),
                        const Text('أعلى تتابع (Streak)', style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Tajawal')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('العودة للأدوات', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _prepareQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('تحدٍ جديد 🚀', style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
