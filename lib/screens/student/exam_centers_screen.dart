import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ExamCenterModel {
  final String city;
  final String university;
  final String department;
  final String center;

  const ExamCenterModel({
    required this.city,
    required this.university,
    required this.department,
    required this.center,
  });
}

class ExamCentersScreen extends StatefulWidget {
  const ExamCentersScreen({super.key});

  @override
  State<ExamCentersScreen> createState() => _ExamCentersScreenState();
}

class _ExamCentersScreenState extends State<ExamCentersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCity = 'الكل';
  String _searchQuery = '';

  // قائمة المراكز الـ 92 المعتمدة رسمياً
  static const List<ExamCenterModel> _allCenters = [
    ExamCenterModel(city: "الديوانية", university: "جامعة القادسية", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بغداد", university: "الجامعة العراقية", department: "رئاسة الجامعة", center: "مركز التطوير و التعليم المستمر"),
    ExamCenterModel(city: "كركوك", university: "الجامعة التقنية الشمالية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر الكلية التقنية حويجة"),
    ExamCenterModel(city: "بغداد", university: "جامعة بغداد", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بغداد", university: "جامعة بغداد", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "البصرة", university: "الجامعة التقنية الجنوبية", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بغداد", university: "الجامعة التكنولوجية", department: "رئاسة الجامعة", center: "مركز تكنولوجيا المعلومات"),
    ExamCenterModel(city: "بغداد", university: "الجامعة التكنولوجية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بغداد", university: "الجامعة التقنية الوسطى", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "البصرة", university: "الجامعة التقنية الجنوبية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "كربلاء", university: "جامعة وارث الانبياء", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "البصرة", university: "جامعة البصرة", department: "رئاسة الجامعة", center: "مركز تكنولوجيا المعلومات والاتصالات"),
    ExamCenterModel(city: "بغداد", university: "جامعة الامام جعفر الصادق عليه السلام", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "الانبار", university: "جامعة الأنبار", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "النجف", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر كوفة"),
    ExamCenterModel(city: "النجف", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "كركوك", university: "جامعة كركوك", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بابل", university: "جامعة القاسم الخضراء", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بابل", university: "جامعة بابل", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "ذي قار", university: "جامعة ذي قار", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "كربلاء", university: "جامعة كربلاء", department: "رئاسة الجامعة", center: "مركز تكنولوجيا المعلومات"),
    ExamCenterModel(city: "نينوى", university: "الجامعة التقنية الشمالية", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "ذي قار", university: "جامعة سومر", department: "رئاسة الجامعة", center: "قسم الحاسبة الالكترونية"),
    ExamCenterModel(city: "بغداد", university: "جامعة البيان", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "ميسان", university: "جامعة ميسان", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "كربلاء", university: "جامعة العميد", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "المثنى", university: "جامعة المثنى", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "نينوى", university: "جامعة الموصل", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "صلاح الدين", university: "جامعة تكريت", department: "رئاسة الجامعة", center: "مركز تكنولوجيا المعلومات"),
    ExamCenterModel(city: "بغداد", university: "جامعة تكنولوجيا المعلومات والأتصالات", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بابل", university: "جامعة المستقبل", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "الانبار", university: "جامعة الأنبار", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بغداد", university: "جامعة الشعب", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "كربلاء", university: "جامعة الزهراء للبنات", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "ديالى", university: "جامعة ديالى", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "واسط", university: "جامعة واسط", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "نينوى", university: "الجامعة التقنية الشمالية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "صلاح الدين", university: "جامعة سامراء", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "النجف", university: "جامعة الكوفة", department: "رئاسة الجامعة", center: "مركز البحث والتأهيل المعلوماتي"),
    ExamCenterModel(city: "بغداد", university: "الجامعة العراقية", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بغداد", university: "الجامعة المستنصرية", department: "رئاسة الجامعة", center: "مركز تكنولوجيا المعلومات"),
    ExamCenterModel(city: "بغداد", university: "الجامعة المستنصرية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "المثنى", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "المعهد التقني الرميثة"),
    ExamCenterModel(city: "كربلاء", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "كلية البوليتكنك كربلاء"),
    ExamCenterModel(city: "الانبار", university: "جامعة الفلوجة", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "النجف", university: "جامعة الكفيل", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "نينوى", university: "جامعة نينوى", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بابل", university: "جامعة بابل", department: "رئاسة الجامعة", center: "مركز التعليم المستمر وتطوير الكوادر"),
    ExamCenterModel(city: "البصرة", university: "جامعة البصرة", department: "رئاسة الجامعة", center: "مركز اللغات الحية شعبة الايلتس"),
    ExamCenterModel(city: "نينوى", university: "جامعة الحمدانية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "نينوى", university: "جامعة الحمدانية", department: "رئاسة الجامعة", center: "قسم الحاسبة الالكترونية"),
    ExamCenterModel(city: "ذي قار", university: "جامعة الشطرة", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بابل", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "المعهد التقني بابل"),
    ExamCenterModel(city: "الديوانية", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "كلية البوليتكنك قادسية"),
    ExamCenterModel(city: "بابل", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "المعهد التقني مسيب"),
    ExamCenterModel(city: "النجف", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "المعهد التقني النجف"),
    ExamCenterModel(city: "الديوانية", university: "جامعة القادسية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "نينوى", university: "جامعة الموصل", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بابل", university: "جامعة بابل", department: "رئاسة الجامعة", center: "مركز التوفل"),
    ExamCenterModel(city: "نينوى", university: "جامعة تلعفر", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بغداد", university: "كلية الامام الكاظم عليه السلام", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بغداد", university: "جامعة النهرين", department: "رئاسة الجامعة", center: "مركز الحاسبة الالكترونية"),
    ExamCenterModel(city: "بغداد", university: "جامعة النهرين", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "كركوك", university: "الجامعة التقنية الشمالية", department: "رئاسة الجامعة", center: "مركز السيسكو الكلية التقنية الهندسية كركوك"),
    ExamCenterModel(city: "كركوك", university: "الجامعة التقنية الشمالية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر الحويجة"),
    ExamCenterModel(city: "صلاح الدين", university: "الجامعة التقنية الشمالية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر الدور"),
    ExamCenterModel(city: "واسط", university: "جامعة الكوت", department: "رئاسة الجامعة", center: "مركز الحاسبة وتكنولوجيا المعلومات"),
    ExamCenterModel(city: "كركوك", university: "جامعة كركوك", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بغداد", university: "كلية الامام الاعظم الجامعة", department: "رئاسة الجامعة", center: "مركز اللغة الانكليزية والترجمة"),
    ExamCenterModel(city: "بغداد", university: "الجامعة الامريكية في العراق بغداد", department: "رئاسة الجامعة", center: "معهد التعليم المستمر"),
    ExamCenterModel(city: "البصرة", university: "جامعة البصرة", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بغداد", university: "جامعة الكرخ للعلوم", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بغداد", university: "جامعة آشور", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "ذي قار", university: "جامعة ذي قار", department: "رئاسة الجامعة", center: "مركز التطوير و التعليم المستمر"),
    ExamCenterModel(city: "النجف", university: "جامعة جابر بن حيان", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بغداد", university: "جامعة النسور الاهلية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "النجف", university: "الجامعة الاسلامية في النجف", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "النجف", university: "معهد العلمين للدراسات العليا", department: "عمادة معهد العلمين", center: "مركز العلمين للتعليم المستمر"),
    ExamCenterModel(city: "بغداد", university: "جامعة التراث", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "البصرة", university: "الجامعة التقنية الجنوبية", department: "كلية البوليتكنك القرنة", center: "التعليم المستمر كلية البوليتكنك قرنة"),
    ExamCenterModel(city: "بغداد", university: "جامعة بغداد", department: "رئاسة الجامعة", center: "المكتب الاستشاري لنظم المعلومات والحاسبات"),
    ExamCenterModel(city: "ذي قار", university: "الجامعة التقنية الجنوبية", department: "رئاسة الجامعة", center: "وحدة التعليم المستمر المعهد التقني الناصرية"),
    ExamCenterModel(city: "بغداد", university: "الجامعة العراقية", department: "كلية التربية", center: "مركز التعليم والتطوير المستمر الطارمية"),
    ExamCenterModel(city: "بغداد", university: "جامعة بغداد", department: "رئاسة الجامعة", center: "مركز التعليم المستمر مركز هواوي للشبكات"),
    ExamCenterModel(city: "كركوك", university: "الجامعة التقنية الشمالية", department: "رئاسة الجامعة", center: "مركز التعليم المستمر كلية هندسة تقنيات النفط والغاز كركوك"),
    ExamCenterModel(city: "ذي قار", university: "الجامعة الوطنية للعلوم والتكنولوجيا", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بغداد", university: "جامعة اوروك", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "الانبار", university: "جامعة المعارف", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "صلاح الدين", university: "جامعة تكريت", department: "رئاسة الجامعة", center: "مركز التعليم المستمر"),
    ExamCenterModel(city: "بابل", university: "جامعة الفرات الأوسط التقنية", department: "رئاسة الجامعة", center: "الكلية التقنية المسيب"),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getCities() {
    final Set<String> citiesSet = _allCenters.map((e) => e.city).toSet();
    final List<String> sortedCities = citiesSet.toList()..sort();
    return ['الكل', ...sortedCities];
  }

  List<ExamCenterModel> _getFilteredCenters() {
    return _allCenters.where((center) {
      final matchesCity = _selectedCity == 'الكل' || center.city == _selectedCity;
      if (!matchesCity) return false;

      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase().trim();
      return center.university.toLowerCase().contains(query) ||
          center.center.toLowerCase().contains(query) ||
          center.department.toLowerCase().contains(query) ||
          center.city.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _getFilteredCenters();
    final cities = _getCities();

    final uniqueUnis = _allCenters.map((c) => c.university).toSet().length;
    final uniqueCities = _allCenters.map((c) => c.city).toSet().length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0F1D) : const Color(0xFFF4F0E6),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Luxury App Bar & Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF0F2338),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFE9D49C)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.4, -0.2),
                    radius: 1.2,
                    colors: [Color(0xFF1A3A5F), Color(0xFF0C2137)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFC6A43F).withOpacity(0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 14, color: Color(0xFFE9D49C)),
                              SizedBox(width: 6),
                              Text(
                                'المنصة الرسمية المعتمدة',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE9D49C),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'المراكز الامتحانية المعتمدة',
                          style: GoogleFonts.notoKufiArabic(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'دليل مراكز التعليم المستمر ووحدات الحاسبة بكافة الجامعات',
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            color: Color(0xFFE2E8F0),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Statistics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildKpiCard(
                          title: 'مركز معتمد',
                          value: '${_allCenters.length}',
                          icon: Icons.account_balance_rounded,
                          color: const Color(0xFF1F7B4D),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'جامعة ومؤسسة',
                          value: '$uniqueUnis',
                          icon: Icons.school_rounded,
                          color: const Color(0xFF1A3A5F),
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildKpiCard(
                          title: 'محافظة ومدينة',
                          value: '$uniqueCities',
                          icon: Icons.location_city_rounded,
                          color: const Color(0xFFC6A43F),
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C31) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2DBCF),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        color: isDark ? Colors.white : const Color(0xFF1E2A36),
                      ),
                      decoration: InputDecoration(
                        hintText: 'ابحث باسم الجامعة، المركز، أو المحافظة...',
                        hintStyle: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 13,
                          color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFC6A43F)),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // City Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: cities.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final city = cities[index];
                        final isSelected = _selectedCity == city;
                        return InkWell(
                          onTap: () => setState(() => _selectedCity = city),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [Color(0xFF1F7B4D), Color(0xFF0E5A36)],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : (isDark ? const Color(0xFF131C31) : const Color(0xFFEBE6D8)),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFC6A43F)
                                    : (isDark ? Colors.white.withOpacity(0.06) : Colors.transparent),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 13,
                                  color: isSelected
                                      ? const Color(0xFFE9D49C)
                                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  city,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontSize: 12.5,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : const Color(0xFF1E2A36)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Results Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'المراكز المتاحة (${filtered.length})',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A3A5F),
                        ),
                      ),
                      if (_selectedCity != 'الكل' || _searchQuery.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _selectedCity = 'الكل';
                              _searchQuery = '';
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('إعادة الضبط', style: TextStyle(fontFamily: 'Tajawal', fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Centers List
                  if (filtered.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildPrestigeCenterCard(filtered[index], isDark);
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE9D49C).withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              color: Color(0xFF1F7B4D),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'Tajawal',
              color: isDark ? Colors.white70 : const Color(0xFF1A3A5F),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrestigeCenterCard(ExamCenterModel center, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFE8E2D4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Accent Header Bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC6A43F), Color(0xFF1F7B4D)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // City Tag + Landmark Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A3A5F).withOpacity(isDark ? 0.6 : 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_city_rounded, size: 13, color: Color(0xFF2B5580)),
                          const SizedBox(width: 4),
                          Text(
                            center.city,
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2B5580),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFFC6A43F)),
                      tooltip: 'نسخ بيانات المركز',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                          text: '${center.university} - ${center.department} - ${center.center} (${center.city})',
                        ));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('تم نسخ بيانات المركز بنجاح! 📋', style: TextStyle(fontFamily: 'Tajawal')),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // University Name
                Text(
                  center.university,
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A3A5F),
                  ),
                ),
                const SizedBox(height: 6),

                // Department
                Row(
                  children: [
                    const Icon(Icons.account_balance_outlined, size: 15, color: Color(0xFF1F7B4D)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        center.department,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F7B4D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Center Name Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF6F3EC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFC6A43F).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.computer_rounded, size: 16, color: Color(0xFFC6A43F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          center.center,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF2D3E50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131C31) : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFC6A43F)),
          const SizedBox(height: 12),
          Text(
            'لا توجد مراكز مطابقة لبحثك',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A3A5F),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'جرّب تغيير المحافظة أو كتابة اسم الجامعة بشكل مختلف',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 12,
              color: Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
