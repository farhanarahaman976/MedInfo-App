// home_page.dart
// CHANGES (this round):
//   1. MedAI floating button restyled — now uses the app's blue-to-teal
//      brand gradient instead of a flat blue, with a glow shadow, a subtle
//      white ring, a sparkle icon, and a small chat-bubble badge to signal
//      it opens the MedAI assistant.
//   2. Medicine card "add to cart" button — color corrected to exactly
//      match the brand gradient start color (was a slightly different blue)
//      and now uses the full brand gradient for a more polished look.
//   3. Search results list — icon and category label color corrected from
//      an unrelated blue to the brand gradient color.
//   4. Home stats row (Medicines / Categories / Brands) — accent colors
//      switched from unrelated hues to brand-family colors so every
//      tappable element on the page matches the app's palette.
//
// PREVIOUS ROUND CHANGES:
//   1. App bar logo → "MedInfo" gradient text + bandage/plus icon
//   2. Floating action button icon → chat bubble (message) icon instead of robot
//   3. Search bar → now uses the logo's teal-blue gradient instead of translucent white
//   4. FIX: Notification bell ekhon clickable — NotificationHistoryPage e navigate
//      kore, ar real-time unread count badge dekhায় (age just static red dot chilo)
//   5. Medicine card-e star rating + review count dekhano hocche
//   6. NOTUN (polished): Health Tips section — gradient icon badge, left accent bar
//   7. NOTUN (polished): Customer Reviews section — rating summary header, gradient
//      avatar initials, relative time ("2 days ago"), pill-style write button
//   8. NOTUN: Review summary card resized — stars on top (larger), Write a
//      Review button full-width below it
//   9. NOTUN: Health Tips card ekhon tap-able — HealthTipDetailPage e full
//      details (English + Bangla dutai) dekhায়
//  10. NOTUN: Recommended section-e featured medicine (Napa Extra, Maxpro,
//      Fexo, etc.) shobar age dekhায়, total 16 ta medicine display hoy
//  11. NOTUN (polished): "Order Now" banner — Recommended r Health Tips-er
//      majhkhane, gradient card + icon badge + subtitle, tap korle full
//      medicine list e navigate kore
//  12. NOTUN: Medicine grid-e branded scrollbar (thin, rounded, gradient-tone)
//      add kora holo — grid nijer moddhe scroll kore, page na

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medicine.dart';
import '../models/health_tip.dart';
import '../models/app_review.dart';
import '../services/notification_history_service.dart';
import '../services/health_tip_service.dart';
import '../services/app_review_service.dart';
import 'medicine_details_page.dart';
import 'medicine_list_demo_page.dart';
import 'notification_history_page.dart';
import 'health_tip_detail_page.dart';
import '../app_shell.dart';
import 'chatbot_page.dart';

class HomePage extends StatefulWidget {
  final List<Medicine> medicines;
  final List<Medicine> cart;
  final Function(Medicine) onAddToCart;
  final bool Function(Medicine) isInCart;
  final String? userName;
  final String? currentUserId; // FIX: notification history-er jonno lagbe
  final VoidCallback? onProfileTap;

  const HomePage({
    super.key,
    required this.medicines,
    required this.cart,
    required this.onAddToCart,
    required this.isInCart,
    this.userName,
    this.currentUserId,
    this.onProfileTap,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _selectedCategory;

  static const Color _primary = Color.fromRGBO(59, 130, 196, 1);

  static const Color _logoGradientStart = Color(0xFF3B82C4);
  static const Color _logoGradientEnd = Color(0xFF0F6E56);

  final HealthTipService _healthTipService = HealthTipService();
  final AppReviewService _appReviewService = AppReviewService();

  // A small rotating palette so tip badges aren't monotone
  static const List<List<Color>> _tipGradients = [
    [Color(0xFF3B82C4), Color(0xFF0F6E56)],
    [Color(0xFF7C3AED), Color(0xFF3B82C4)],
    [Color(0xFFF5A623), Color(0xFFE0662F)],
    [Color(0xFF0F6E56), Color(0xFF34D399)],
  ];

  static const List<Color> _avatarPalette = [
    Color(0xFF3B82C4),
    Color(0xFF0F6E56),
    Color(0xFF7C3AED),
    Color(0xFFE0662F),
    Color(0xFF993556),
  ];

  // Featured medicines — eigula "Recommended" section-e shobar age dekhabe
  static const List<String> _featuredMedicineNames = [
    'Napa Extra',
    'Deslor 5 mg',
    'Maxpro 20',
    'Fexo 120',
    'Artica',
    'Scabo 5%',
  ];

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  String? get _userInitial {
    final name = widget.userName ?? '';
    return name.isNotEmpty ? name[0].toUpperCase() : null;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return '$months mo ago';
    } else if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'just now';
  }

  static const List<Map<String, dynamic>> _categoryData = [
    {
      'label': 'Pain Killer',
      'icon': Icons.psychology_outlined,
      'bg': Color(0xFFEEF2FF),
      'iconColor': Color.fromARGB(255, 38, 129, 214),
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

  void _showWriteReviewDialog(BuildContext context) {
    if (widget.currentUserId == null || widget.userName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log in first to write a review.')),
      );
      return;
    }

    int selectedStars = 5;
    final commentController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('Write a Review'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your rating', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (i) {
                      final starIndex = i + 1;
                      return GestureDetector(
                        onTap: () => setDialogState(() => selectedStars = starIndex),
                        child: Icon(
                          starIndex <= selectedStars
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 28,
                          color: const Color(0xFFF5A623),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with MedInfo...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _logoGradientEnd,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please write a short comment.')),
                            );
                            return;
                          }
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _appReviewService.submitReview(
                              userId: widget.currentUserId!,
                              userName: widget.userName!,
                              stars: selectedStars,
                              comment: commentController.text.trim(),
                            );
                            if (dialogContext.mounted) Navigator.pop(dialogContext);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Thanks for your review!')),
                              );
                            }
                          } catch (e) {
                            debugPrint('Review submit failed: $e');
                            setDialogState(() => isSubmitting = false);
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: false,
      floatingActionButton: _buildMedAiFab(context),
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
                    _buildOrderNowBanner(context, isDark),
                    _buildHealthTipsSection(context, isDark),
                    _buildCustomerReviewsSection(context, isDark),
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

  // ── MedAI floating button (brand-matched, styled) ────────────────────────

  Widget _buildMedAiFab(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatbotPage(
            medicines: widget.medicines,
            onAddToCart: widget.onAddToCart,
            isInCart: widget.isInCart,
          ),
        ),
      ),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_logoGradientStart, _logoGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1.6,
          ),
          boxShadow: [
            BoxShadow(
              color: _logoGradientStart.withValues(alpha: 0.45),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: _logoGradientEnd.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 26,
            ),
            Positioned(
              bottom: -3,
              right: -3,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _logoGradientEnd, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  size: 12,
                  color: _logoGradientEnd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

    final initial = _userInitial;

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
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF3B82C4), Color(0xFF0F6E56)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: const Text(
              'MedInfo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82C4), Color(0xFF0F6E56)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.add_rounded, size: 14, color: Colors.white),
          ),
          const Spacer(),
          _buildNotificationBell(context, isDark),
          const SizedBox(width: 10),
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

  Widget _buildNotificationBell(BuildContext context, bool isDark) {
    final userId = widget.currentUserId;

    return GestureDetector(
      onTap: () {
        if (userId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Log in first to see the notification history.'),
            ),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationHistoryPage(userId: userId),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
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
          if (userId != null)
            StreamBuilder<int>(
              stream: NotificationHistoryService().getUnreadCount(userId),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                if (count == 0) return const SizedBox.shrink();
                return Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE24B4A),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_logoGradientStart, _logoGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                  color: Colors.white.withValues(alpha: 0.15),
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
                color: Colors.white.withValues(alpha: 0.18),
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
                      color: Colors.white.withValues(alpha: 0.75),
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

  Widget _buildStatsRow(BuildContext context, bool isDark) {
    final allMedicines = widget.medicines;
    final categories = allMedicines.map((m) => m.category).toSet().toList();
    final brands = allMedicines.map((m) => m.company).toSet().toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          _StatButton(
            number: '${allMedicines.length}+',
            label: 'Medicines',
            color: _logoGradientStart,
            isDark: isDark,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicineListDemoPage(
                  medicines: allMedicines,
                  onAddToCart: widget.onAddToCart,
                  isInCart: widget.isInCart,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _StatButton(
            number: '${categories.length}+',
            label: 'Categories',
            color: _logoGradientEnd,
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
          _StatButton(
            number: '${brands.length}+',
            label: 'Brands',
            color: Color.lerp(_logoGradientStart, _logoGradientEnd, 0.5)!,
            isDark: isDark,
            onTap: () {
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
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.grey.withValues(alpha: 0.1),
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

  Widget _buildMedicineSection(BuildContext context, bool isDark) {
    final medicines = _filteredMedicines;

    // Featured medicines first, tarpor baki gula
    final featured = <Medicine>[];
    final rest = <Medicine>[];
    for (final m in medicines) {
      if (_featuredMedicineNames.any((name) =>
          m.name.toLowerCase().contains(name.toLowerCase()))) {
        featured.add(m);
      } else {
        rest.add(m);
      }
    }
    final sortedMedicines = [...featured, ...rest];

    final displayList = sortedMedicines.length > 16
        ? sortedMedicines.sublist(0, 16)
        : sortedMedicines;

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
                    builder: (_) => MedicineListDemoPage(
                      medicines: widget.medicines,
                      onAddToCart: widget.onAddToCart,
                      isInCart: widget.isInCart,
                    ),
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
                    childAspectRatio: 0.62,
                  ),
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final medicine = displayList[index];
                    final inCart = widget.isInCart(medicine);
                    return _MedicineCard(
                      medicine: medicine,
                      inCart: inCart,
                      categoryData: _categoryData,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MedicineDetailsPage(
                            medicine: medicine,
                            onAddToCart: widget.onAddToCart,
                            isInCart: (m) => widget.isInCart(m),
                          ),
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

  // ── Order Now Banner ──────────────────────────────────────────────────────

  Widget _buildOrderNowBanner(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineListDemoPage(
              medicines: widget.medicines,
              onAddToCart: widget.onAddToCart,
              isInCart: widget.isInCart,
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_logoGradientStart, _logoGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _logoGradientStart.withValues(alpha: 0.32),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 24,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Your Medicine',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Fast delivery, genuine products',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Order Now',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _logoGradientEnd,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: _logoGradientEnd,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Health Tips Section (polished) ───────────────────────────────────────

  Widget _buildHealthTipsSection(BuildContext context, bool isDark) {
    return StreamBuilder<List<HealthTip>>(
      stream: _healthTipService.getAllTips(),
      builder: (context, snapshot) {
        final tips = snapshot.data ?? [];

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (tips.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 22, 14, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_logoGradientStart, _logoGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tips_and_updates_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Health Tips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F1117),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 142,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                physics: const BouncingScrollPhysics(),
                itemCount: tips.length,
                itemBuilder: (context, index) {
                  final tip = tips[index];
                  final gradientColors = _tipGradients[index % _tipGradients.length];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HealthTipDetailPage(
                          tip: tip,
                          gradientColors: gradientColors,
                        ),
                      ),
                    ),
                    child: Container(
                      width: 230,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.06)
                              : Colors.grey.withValues(alpha: 0.1),
                          width: 0.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top accent strip with icon badge
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: gradientColors),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: gradientColors),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.lightbulb_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip.titleBangla.isNotEmpty
                                            ? tip.titleBangla
                                            : tip.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F1117),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tip.bodyBangla.isNotEmpty
                                      ? tip.bodyBangla
                                      : tip.body,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.45,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
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
      },
    );
  }

  // ── Customer Reviews Section (polished) ──────────────────────────────────

  Widget _buildCustomerReviewsSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_logoGradientStart, _logoGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.reviews_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'What Our Customers Say',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F1117),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<AppReview>>(
            stream: _appReviewService.getReviews(),
            builder: (context, snapshot) {
              final reviews = snapshot.data ?? [];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }

              // Rating summary computed from the full list
              final avg = reviews.isEmpty
                  ? 0.0
                  : reviews.fold<int>(0, (s, r) => s + r.stars) / reviews.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Summary card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _logoGradientStart.withValues(alpha: isDark ? 0.18 : 0.08),
                          _logoGradientEnd.withValues(alpha: isDark ? 0.18 : 0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _logoGradientStart.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── Rating block (bigger, centered, on top) ──
                        Text(
                          reviews.isEmpty ? '—' : avg.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F1117),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final filled = i < avg.round();
                            return Icon(
                              filled ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 26,
                              color: const Color(0xFFF5A623),
                            );
                          }),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reviews.isEmpty
                              ? 'No reviews yet'
                              : 'Based on ${reviews.length} review${reviews.length == 1 ? "" : "s"}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ── Write a Review button (full width, below) ──
                        GestureDetector(
                          onTap: () => _showWriteReviewDialog(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_logoGradientStart, _logoGradientEnd],
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit_rounded, size: 15, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Write a Review',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Individual reviews ──
                  if (reviews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Be the first to share your experience!',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    )
                  else
                    ...reviews.take(5).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final review = entry.value;
                      final avatarColor = _avatarPalette[index % _avatarPalette.length];
                      final initial = review.userName.isNotEmpty
                          ? review.userName[0].toUpperCase()
                          : '?';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.grey.withValues(alpha: 0.12),
                            width: 0.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: avatarColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: avatarColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          review.userName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F1117),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _timeAgo(review.createdAt),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < review.stars ? Icons.star_rounded : Icons.star_border_rounded,
                                        size: 12,
                                        color: const Color(0xFFF5A623),
                                      );
                                    }),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    review.comment,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

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
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.12),
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

class _MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final bool inCart;
  final List<Map<String, dynamic>> categoryData;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  static const Color _logoGradientStart = Color(0xFF3B82C4);
  static const Color _logoGradientEnd = Color(0xFF0F6E56);

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
      orElse: () => {'iconColor': _logoGradientStart},
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
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.12),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF262836) : _badgeBg(),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: (medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty)
                  ? Image.network(
                      medicine.imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _badgeText(),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.medication_rounded,
                        size: 32,
                        color: _badgeText(),
                      ),
                    )
                  : Icon(
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
            if (medicine.reviewCount > 0) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF5A623)),
                  const SizedBox(width: 2),
                  Text(
                    medicine.averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '(${medicine.reviewCount})',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
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
                      color: inCart ? const Color(0xFFEAF3DE) : null,
                      gradient: inCart
                          ? null
                          : const LinearGradient(
                              colors: [_logoGradientStart, _logoGradientEnd],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
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

class _MedicineSearchDelegate extends SearchDelegate<String> {
  final List<Medicine> medicines;
  final Function(Medicine) onAddToCart;
  final Function(Medicine) isInCart;

  static const Color _logoGradientStart = Color(0xFF3B82C4);
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
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.withValues(alpha: 0.1),
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
                color: _logoGradientStart,
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
              style: const TextStyle(fontSize: 11, color: _logoGradientStart),
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
                builder: (_) => MedicineDetailsPage(
                  medicine: m,
                  onAddToCart: onAddToCart,
                  isInCart: (m) => isInCart(m) as bool,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}