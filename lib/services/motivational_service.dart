import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class AcademicQuote {
  final String id;
  final String text;
  final String author;
  final String category; // 'competitive_exam', 'research', 'perseverance', 'mindset'

  const AcademicQuote({
    required this.id,
    required this.text,
    required this.author,
    this.category = 'competitive_exam',
  });

  factory AcademicQuote.fromMap(String id, Map<String, dynamic> data) {
    return AcademicQuote(
      id: id,
      text: data['text']?.toString() ?? '',
      author: data['author']?.toString() ?? 'إرشاد أكاديمي',
      category: data['category']?.toString() ?? 'competitive_exam',
    );
  }
}

class MotivationalService {
  static final MotivationalService _instance = MotivationalService._internal();
  factory MotivationalService() => _instance;
  MotivationalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// قائمة غنية مخصصة لطلاب الدراسات العليا في العراق بنكهة أكاديمية عراقية أصيلة
  static const List<AcademicQuote> defaultQuotes = [
    // 1. الامتحان التنافسي والقبول
    AcademicQuote(
      id: 'iq_1',
      text: 'المنافسة قوية على المقاعد لكن عزيمة الطالب العراقي أقوى.. اقرأ بوعي وتركيز والمقعد التنافسي حليفك بإذن الله.',
      author: 'وصايا التنافسي في الجامعات العراقية',
      category: 'competitive_exam',
    ),
    AcademicQuote(
      id: 'iq_2',
      text: 'عَلَى قَدْرِ أَهْلِ العَزْمِ تَأْتِي العَزَائِمُ ... وَتَأْتِي عَلَى قَدْرِ الكِرَامِ المَكَارِمُ',
      author: 'أبو الطيب المتنبي (الكوفة)',
      category: 'competitive_exam',
    ),
    AcademicQuote(
      id: 'iq_3',
      text: 'من قاعات كليات بغداد والمستنصرية والموصل والبصرة.. لحظة إعلان نتائج القبول تستحق كل دقيقة سهر بذلتها.',
      author: 'حلم الماجستير والدكتوراه',
      category: 'competitive_exam',
    ),
    AcademicQuote(
      id: 'iq_4',
      text: 'وَلَمْ أَرَ فِي عُيُوبِ النَّاسِ عَيْباً ... كَنَقْصِ القَادِرِينَ عَلَى التَّمَامِ',
      author: 'أبو الطيب المتنبي',
      category: 'competitive_exam',
    ),

    // 2. عقلية وفكر الباحث العراقي
    AcademicQuote(
      id: 'iq_5',
      text: 'القوة التي تقود العالم اليوم ليست السلاح، إنها قوة العلم والنظام والتفكير المرن المتجدد.',
      author: 'د. علي الوردي (عالم الاجتماع العراقي)',
      category: 'mindset',
    ),
    AcademicQuote(
      id: 'iq_6',
      text: 'المثقف والأكاديمي الحقيقي هو من يمتاز بمرونة رأيه واستعداده للبحث والتدبر في كل فكرة جديدة.',
      author: 'د. علي الوردي',
      category: 'mindset',
    ),
    AcademicQuote(
      id: 'iq_7',
      text: 'طلبُ الدقة والتحري في المعلومة وبحثُ الحقيقة أمانةٌ في عنق كل باحث وأكاديمي في بلاد الرافدين.',
      author: 'د. مصطفى جواد (علاّمة العراق)',
      category: 'mindset',
    ),
    AcademicQuote(
      id: 'iq_8',
      text: 'وَلَيْسَ الغِنَى إِلاَّ غِنَى العِلْمِ إِنَّهُ ... لَنُورُ الفَتَى يَجْلُو ظَلاَمَ افْتِقَارِهِ',
      author: 'معروف الرصافي (شاعر العراق)',
      category: 'mindset',
    ),

    // 3. الإصرار والكفاح الأكاديمي
    AcademicQuote(
      id: 'iq_9',
      text: 'سَيُورِقُ صَخْرٌ وتَبْدُو ثِمَارٌ ... إِذَا مَا الصَّبُورُ اسْتَمَاتَ كِفَاحَا',
      author: 'محمد مهدي الجواهري (شاعر العرب الأكبر)',
      category: 'perseverance',
    ),
    AcademicQuote(
      id: 'iq_10',
      text: 'تحدّى بكَ الشوقُ أُفْقاً بَعِيداً ... وَعَزْماً يُعِيدُ الحَيَاةَ جَدِيدَا',
      author: 'محمد مهدي الجواهري',
      category: 'perseverance',
    ),
    AcademicQuote(
      id: 'iq_11',
      text: 'فَكُلُّ بِلاَدٍ جَادَهَا العِلْمُ أَمْرَعَتْ ... رُبَاهَا وَسَالَتْ بِالرَّشَادِ شِعَابُهَا',
      author: 'معروف الرصافي',
      category: 'perseverance',
    ),
    AcademicQuote(
      id: 'iq_12',
      text: 'تَعَلَّمْ فَلَيْسَ المَرْءُ يُولَدُ عَالِماً ... وَعِلْمُ الفَتَى يَسْمُو بِهِ حَيْثُمَا كَانَا',
      author: 'جميل صدقي الزهاوي (بغداد)',
      category: 'perseverance',
    ),

    // 4. البحث العلمي ورسائل الماجستير والدكتوراه
    AcademicQuote(
      id: 'iq_13',
      text: 'العراق صُنع بحبر علمائه وأقلام باحثيه.. رسالتك وأطروحتك القادمة هي بصمة تخلد اسمك في تاريخ هذا الوطن.',
      author: 'رسائل الباحث العراقي',
      category: 'research',
    ),
    AcademicQuote(
      id: 'iq_14',
      text: 'بناء الأوطان يبدأ من رصانة التعليم واستقلالية البحث العلمي وسعي الشباب الدؤوب نحو المعرفة.',
      author: 'د. عبد الجبار عبد الله (عالم الفيزياء العراقي)',
      category: 'research',
    ),
    AcademicQuote(
      id: 'iq_15',
      text: 'سهر الليالي مع المصادر والمراجع ليس تعباً ضائعاً، بل هو فخر ترفعه بين يديك يوم المناقشة العلنية.',
      author: 'إرشاد الدراسات العليا - العراق',
      category: 'research',
    ),
    AcademicQuote(
      id: 'iq_16',
      text: 'تعبك اليوم في حل هذه الأسئلة وقراءة المصادر هو الأساس المتين لأطروحتك ومستقبلك الأكاديمي.',
      author: 'دليل طلبة الدراسات العليا 🇮🇶',
      category: 'research',
    ),
  ];

  /// جلب اقتباس عشوائي سريع
  AcademicQuote getRandomQuote() {
    final random = Random();
    return defaultQuotes[random.nextInt(defaultQuotes.length)];
  }

  /// تيار الاقتباسات من السيرفر مع الرجوع للقائمة الافتراضية
  Stream<List<AcademicQuote>> getQuotesStream() {
    return _firestore.collection('motivational_quotes').snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return defaultQuotes;
      }
      return snapshot.docs.map((doc) {
        return AcademicQuote.fromMap(doc.id, doc.data());
      }).toList();
    });
  }
}
