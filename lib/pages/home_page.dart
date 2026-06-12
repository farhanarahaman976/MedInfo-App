// home_page.dart  ── only the changed sections shown; rest stays the same
// CHANGES:
//   1. _StatCard → _StatButton  (tappable, ripple, onTap callback)
//   2. _buildStatsRow  passes navigation callbacks
//   3. _buildAppBar  → profile avatar shows initial only when userName != null

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medicine.dart';
import 'medicine_details_page.dart';
import 'medicine_list_demo_page.dart';
import '../app_shell.dart';
import 'chatbot_page.dart';

class HomePage extends StatefulWidget {
  final List<Medicine> medicines;
  final List<Medicine> cart;
  final Function(Medicine) onAddToCart;
  final Function(Medicine) isInCart;
  final String? userName;
  final VoidCallback? onProfileTap;

  const HomePage({
    super.key,
    required this.medicines,
    required this.cart,
    required this.onAddToCart,
    required this.isInCart,
    this.userName,
    this.onProfileTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedCategory;

  static const Color _primary = Color(0xFF1A56DB);

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  // FIX: only show initial when userName is available (logged in)
  // Returns null when not logged in → avatar shows person icon instead
  String? get _userInitial {
    final name = widget.userName ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : null;
  }

  static const List<Map<String, dynamic>> _categoryData = [
    {
      'label': 'Pain Killer',
      'icon': Icons.psychology_outlined,
      'bg': Color(0xFFEEF2FF),
      'iconColor': Color(0xFF1A56DB),
    },
    {
      'label': 'Fever & Pain',
      'icon': Icons.thermostat_outlined,
      'bg': Color(0xFFFAEEDA),
      'iconColor': Color(0xFF854F0B),
    },
    {
      'label': 'Antibiotic',
      'icon': Icons.biotech_outlined,
      'bg': Color(0xFFE1F5EE),
      'iconColor': Color(0xFF0F6E56),
    },
    {
      'label': 'Heart Disease',
      'icon': Icons.monitor_heart_outlined,
      'bg': Color(0xFFFCEBEB),
      'iconColor': Color(0xFFA32D2D),
    },
    {
      'label': 'Diabetes',
      'icon': Icons.water_drop_outlined,
      'bg': Color(0xFFFBEAF0),
      'iconColor': Color(0xFF993556),
    },
    {
      'label': 'Asthma/Respiratory',
      'icon': Icons.air_outlined,
      'bg': Color(0xFFEEEDFE),
      'iconColor': Color(0xFF534AB7),
    },
    {
      'label': 'Gastric',
      'icon': Icons.local_hospital_outlined,
      'bg': Color(0xFFE1F5EE),
      'iconColor': Color(0xFF0F6E56),
    },
    {
      'label': 'Vitamin',
      'icon': Icons.science_outlined,
      'bg': Color(0xFFFAEEDA),
      'iconColor': Color(0xFF854F0B),
    },
  ];

  List<Medicine> get _filteredMedicines {
    var results = widget.medicines;
    if (_selectedCategory != null) {
      results = results.where((m) => m.category == _selectedCategory).toList();
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: false,
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatbotPage(
              medicines: widget.medicines,
              onAddToCart: widget.onAddToCart,
              isInCart: widget.isInCart,
            ),
          ),
        ),
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
      ),
      body: SafeArea(
        top: true,
        child: Column(
          children: [
            _buildAppBar(context, isDark),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroSection(context),
                    _buildStatsRow(context, isDark),
                    _buildCategorySection(context, isDark),
                    _buildMedicineSection(context, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context, bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
            ),
    );

    final appBarColor =
        Theme.of(context).appBarTheme.backgroundColor ??
        Theme.of(context).colorScheme.surface;

    final initial = _userInitial; // null if not logged in

    return Container(
      color: appBarColor,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Scaffold.of(context).openDrawer(),
            child: Icon(
              Icons.menu_rounded,
              size: 24,
              color: isDark ? Colors.white : const Color(0xFF0F1117),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'MedInfo',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F1117),
            ),
          ),
          const Spacer(),
          // Notification bell
          Stack(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF262836)
                      : const Color(0xFFF2F6FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF0F1117),
                ),
              ),
              Positioned(
                top: 7,
                right: 7,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE24B4A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                      width: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Profile avatar
          // FIX: show initial only when logged in (initial != null)
          //       show person icon when not logged in
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262836)
                    : const Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: initial != null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _primary,
                        ),
                      )
                    : Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: isDark ? Colors.white70 : _primary,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Section ────────────────────────────────────────────────────────────

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'What medicine\nare you looking for?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 22,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => showSearch(
              context: context,
              delegate: _MedicineSearchDelegate(
                medicines: widget.medicines,
                onAddToCart: widget.onAddToCart,
                isInCart: widget.isInCart,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.search_rounded,
                    size: 17,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Search medicines...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.75),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Row  (NOW TAPPABLE BUTTONS) ──────────────────────────────────────

  Widget _buildStatsRow(BuildContext context, bool isDark) {
    final allMedicines = widget.medicines;
    final categories = allMedicines.map((m) => m.category).toSet().toList();
    final brands = allMedicines.map((m) => m.company).toSet().toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          // Medicines button → MedicineListDemoPage
          _StatButton(
            number: '${allMedicines.length}+',
            label: 'Medicines',
            color: _primary,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicineListDemoPage()),
            ),
          ),
          const SizedBox(width: 8),
          // Categories button → CategoriesPage
          _StatButton(
            number: '${categories.length}+',
            label: 'Categories',
            color: const Color(0xFF0F6E56),
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoriesPage(
                  categories: categories,
                  allMedicines: allMedicines,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Brands button → BrandsPage (or show snackbar if page not ready)
          _StatButton(
            number: '${brands.length}+',
            label: 'Brands',
            color: const Color(0xFF854F0B),
            isDark: isDark,
            onTap: () {
              // TODO: Replace with BrandsPage when ready
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${brands.length} brands available'),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Category Section ────────────────────────────────────────────────────────

  Widget _buildCategorySection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Categories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F1117),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoriesPage(
                      categories: widget.medicines
                          .map((m) => m.category)
                          .toSet()
                          .toList(),
                      allMedicines: widget.medicines,
                    ),
                  ),
                ),
                child: const Text(
                  'See all →',
                  style: TextStyle(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            physics: const BouncingScrollPhysics(),
            itemCount: _categoryData.length,
            itemBuilder: (context, index) {
              final cat = _categoryData[index];
              final isSelected = _selectedCategory == cat['label'];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedCategory = isSelected
                      ? null
                      : cat['label'] as String;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primary
                              : isDark
                              ? const Color(0xFF262836)
                              : cat['bg'] as Color,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? null
                              : Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.06)
                                      : Colors.grey.withOpacity(0.1),
                                  width: 0.5,
                                ),
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? Colors.white
                              : cat['iconColor'] as Color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 58,
                        child: Text(
                          cat['label'] as String,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? _primary
                                : isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Medicine Section ────────────────────────────────────────────────────────

  Widget _buildMedicineSection(BuildContext context, bool isDark) {
    final medicines = _filteredMedicines;
    final displayList = medicines.length > 10
        ? medicines.sublist(0, 10)
        : medicines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategory ?? 'Recommended',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F1117),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedicineListDemoPage(),
                  ),
                ),
                child: const Text(
                  'Browse all →',
                  style: TextStyle(
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        displayList.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No medicines found',
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.58,
                  ),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final medicine = displayList[index];
                    final inCart = widget.isInCart(medicine) as bool;
                    return _MedicineCard(
                      medicine: medicine,
                      inCart: inCart,
                      categoryData: _categoryData,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MedicineDetailsPage(medicine: medicine),
                        ),
                      ),
                      onAddToCart: () => widget.onAddToCart(medicine),
                    );
                  },
                ),
              ),
      ],
    );
  }
}

// ─── Stat Button (REPLACES _StatCard — now tappable) ──────────────────────────

class _StatButton extends StatelessWidget {
  final String number;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _StatButton({
    required this.number,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey.withOpacity(0.12),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  number,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Medicine Card ──────────────────────────────────────────────────────────────

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final bool inCart;
  final List<Map<String, dynamic>> categoryData;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  static const Color _primary = Color(0xFF1A56DB);

  const _MedicineCard({
    required this.medicine,
    required this.inCart,
    required this.categoryData,
    required this.isDark,
    required this.onTap,
    required this.onAddToCart,
  });

  Color _badgeBg() {
    final match = categoryData.firstWhere(
      (c) => c['label'] == medicine.category,
      orElse: () => {'bg': const Color(0xFFEEF2FF)},
    );
    return match['bg'] as Color;
  }

  Color _badgeText() {
    final match = categoryData.firstWhere(
      (c) => c['label'] == medicine.category,
      orElse: () => {'iconColor': _primary},
    );
    return match['iconColor'] as Color;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E26) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.grey.withOpacity(0.12),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 68,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262836) : _badgeBg(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medication_rounded,
                size: 32,
                color: _badgeText(),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262836) : _badgeBg(),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                medicine.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: _badgeText(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              medicine.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F1117),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              medicine.company,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '৳${medicine.displayPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F1117),
                  ),
                ),
                GestureDetector(
                  onTap: inCart ? null : onAddToCart,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: inCart ? const Color(0xFFEAF3DE) : _primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(
                      inCart ? Icons.check_rounded : Icons.add_rounded,
                      size: 16,
                      color: inCart ? const Color(0xFF3B6D11) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Search Delegate ────────────────────────────────────────────────────────────

class _MedicineSearchDelegate extends SearchDelegate<String> {
  final List<Medicine> medicines;
  final Function(Medicine) onAddToCart;
  final Function(Medicine) isInCart;

  _MedicineSearchDelegate({
    required this.medicines,
    required this.onAddToCart,
    required this.isInCart,
  });

  @override
  String get searchFieldLabel => 'Search medicine by name...';

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
  ];

  @override
  Widget buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back_rounded),
    onPressed: () => close(context, ''),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final q = query.toLowerCase();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = q.isEmpty
        ? medicines
        : medicines.where((m) {
            return m.name.toLowerCase().contains(q);
          }).toList();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 12),
            Text(
              'No medicines found',
              style: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final m = results[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1E26) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.grey.withOpacity(0.1),
              width: 0.8,
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262836)
                    : const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: Color(0xFF1A56DB),
                size: 22,
              ),
            ),
            title: Text(
              m.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F1117),
              ),
            ),
            subtitle: Text(
              m.category,
              style: const TextStyle(fontSize: 11, color: Color(0xFF1A56DB)),
            ),
            trailing: Text(
              '৳${m.displayPrice.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F1117),
              ),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicineDetailsPage(medicine: m),
              ),
            ),
          ),
        );
      },
    );
  }
}
