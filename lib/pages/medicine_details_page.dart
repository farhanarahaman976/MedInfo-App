import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../models/medicine.dart';
import '../services/language_service.dart';

class MedicineDetailsPage extends StatefulWidget {
  final Medicine medicine;
  final void Function(Medicine)? onAddToCart;
  final bool Function(Medicine)? isInCart;
  final String? currentUserId; // kept for compatibility with existing call sites
  final String? currentUserName; // kept for compatibility with existing call sites

  const MedicineDetailsPage({
    super.key,
    required this.medicine,
    this.onAddToCart,
    this.isInCart,
    this.currentUserId,
    this.currentUserName,
  });

  @override
  State<MedicineDetailsPage> createState() => _MedicineDetailsPageState();
}

class _MedicineDetailsPageState extends State<MedicineDetailsPage> {
  int _quantity = 1;

  // Brand gradient (matches logo: blue -> teal) — stays same in both modes
  static const Color kBrandStart = Color(0xFF3B82C4);
  static const Color kBrandEnd = Color(0xFF0F6E56);

  int get _maxQuantity => widget.medicine.stockQuantity ?? 99;

  void _increment() {
    if (_quantity < _maxQuantity) setState(() => _quantity++);
  }

  void _decrement() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LanguageService(),
      child: Consumer<LanguageService>(
        builder: (context, languageService, _) {
          final isEnglish = languageService.isEnglish;
          final medicine = widget.medicine;
          final hasImage =
              medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty;
          final outOfStock =
              medicine.stockQuantity != null && medicine.stockQuantity! <= 0;

          final isDark = Theme.of(context).brightness == Brightness.dark;

          // ── Theme-aware colors ──
          final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
          final surfaceColor = isDark ? const Color(0xFF1C1E26) : Colors.white;
          final imageBoxColor =
              isDark ? const Color(0xFF262836) : const Color(0xFFF3F4F6);
          final primaryText =
              isDark ? Colors.white : const Color(0xFF111827);
          final secondaryText =
              isDark ? Colors.grey[400]! : const Color(0xFF6B7280);
          final mutedText =
              isDark ? Colors.grey[600]! : const Color(0xFF9CA3AF);
          final dividerColor =
              isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6);

          final sectionBg =
              isDark ? const Color(0xFF262836) : const Color(0xFFF3F4F6);
          final sectionBorder = isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE5E7EB);
          final sectionIconBg =
              isDark ? const Color(0xFF3D3560) : const Color(0xFFDDD6FE);
          final sectionIconColor =
              isDark ? const Color(0xFFB9A6F5) : const Color(0xFF7C3AED);
          final sectionTitleColor =
              isDark ? Colors.white : const Color(0xFF1F2937);
          final sectionContentColor =
              isDark ? Colors.grey[400]! : const Color(0xFF4B5563);

          Color listBg(bool warn) => isDark
              ? (warn ? const Color(0xFF3A2323) : const Color(0xFF1F3329))
              : (warn ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4));
          Color listBorder(bool warn) => isDark
              ? Colors.white.withValues(alpha: 0.06)
              : (warn ? const Color(0xFFFBE2E2) : const Color(0xFFDCFCE7));
          Color listIconBg(bool warn) => isDark
              ? (warn ? const Color(0xFF5C2626) : const Color(0xFF1E4D3A))
              : (warn ? const Color(0xFFFED7D7) : const Color(0xFFCCFBF1));
          Color listIconColor(bool warn) =>
              warn ? const Color(0xFFEF5350) : const Color(0xFF34D399);
          Color listTitleColor(bool warn) => isDark
              ? Colors.white
              : (warn ? const Color(0xFF991B1B) : const Color(0xFF065F46));
          final listItemTextColor =
              isDark ? Colors.grey[400]! : const Color(0xFF4B5563);

          return Scaffold(
            backgroundColor: scaffoldBg,
            appBar: AppBar(
              title: Text(
                AppStrings.getString('medicine_details', isEnglish),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kBrandStart, kBrandEnd],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                if (!isEnglish) languageService.setLanguage(true);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: isEnglish ? Colors.white : Colors.transparent,
                                ),
                                child: Text(
                                  'EN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isEnglish ? kBrandStart : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: GestureDetector(
                              onTap: () {
                                if (isEnglish) languageService.setLanguage(false);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: !isEnglish ? Colors.white : Colors.transparent,
                                ),
                                child: Text(
                                  'বাংলা',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: !isEnglish ? kBrandEnd : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Product Image Card ──
                  Container(
                    width: double.infinity,
                    color: surfaceColor,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Container(
                      height: 240,
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: imageBoxColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: hasImage
                          ? Image.network(
                              medicine.imageUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(color: kBrandStart),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  _fallbackIcon(),
                            )
                          : _fallbackIcon(),
                    ),
                  ),

                  // ── Overlapping Info Card ──
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (medicine.company.isNotEmpty) ...[
                            Text(
                              medicine.company,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: mutedText,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            isEnglish ? medicine.name : medicine.nameBangla,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryText,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [kBrandStart, kBrandEnd],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  medicine.category,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (medicine.stockQuantity != null)
                                Text(
                                  outOfStock
                                      ? (isEnglish ? 'Out of stock' : 'স্টক নেই')
                                      : (isEnglish
                                            ? 'In stock: ${medicine.stockQuantity}'
                                            : 'স্টকে আছে: ${medicine.stockQuantity}'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: outOfStock
                                        ? const Color(0xFFEF5350)
                                        : const Color(0xFF34D399),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(height: 1, color: dividerColor),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppStrings.getString('price', isEnglish),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: secondaryText,
                                ),
                              ),
                              Text(
                                '৳ ${medicine.displayPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? const Color(0xFF34D399) : kBrandEnd,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Details Sections ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          title: AppStrings.getString('usage', isEnglish),
                          content: isEnglish ? medicine.description : medicine.descriptionBangla,
                          icon: Icons.info_outline,
                          bg: sectionBg,
                          border: sectionBorder,
                          iconBg: sectionIconBg,
                          iconColor: sectionIconColor,
                          titleColor: sectionTitleColor,
                          contentColor: sectionContentColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildSection(
                          title: AppStrings.getString('dosage', isEnglish),
                          content: isEnglish ? medicine.dosage : medicine.dosageBangla,
                          icon: Icons.schedule,
                          bg: sectionBg,
                          border: sectionBorder,
                          iconBg: sectionIconBg,
                          iconColor: sectionIconColor,
                          titleColor: sectionTitleColor,
                          contentColor: sectionContentColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildListSection(
                          title: AppStrings.getString('usage', isEnglish),
                          items: isEnglish ? medicine.uses : medicine.usesBangla,
                          icon: Icons.check_circle_outline,
                          bg: listBg(false),
                          border: listBorder(false),
                          iconBg: listIconBg(false),
                          iconColor: listIconColor(false),
                          titleColor: listTitleColor(false),
                          itemTextColor: listItemTextColor,
                        ),
                        const SizedBox(height: 16),
                        _buildListSection(
                          title: AppStrings.getString('side_effects', isEnglish),
                          items: medicine.sideEffects.isEmpty
                              ? [AppStrings.getString('no_side_effects', isEnglish)]
                              : (isEnglish ? medicine.sideEffects : medicine.sideEffectsBangla),
                          icon: Icons.warning_amber,
                          bg: listBg(true),
                          border: listBorder(true),
                          iconBg: listIconBg(true),
                          iconColor: listIconColor(true),
                          titleColor: listTitleColor(true),
                          itemTextColor: listItemTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Sticky bottom bar ──
            bottomNavigationBar: widget.onAddToCart == null
                ? null
                : Obx(() {
                    final inCart = widget.isInCart?.call(medicine) ?? false;

                    return SafeArea(
                      top: false,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: sectionBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: outOfStock ? null : _decrement,
                                    icon: const Icon(Icons.remove, size: 18),
                                    color: isDark ? const Color(0xFF34D399) : kBrandEnd,
                                  ),
                                  Text(
                                    '$_quantity',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: primaryText,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: outOfStock ? null : _increment,
                                    icon: const Icon(Icons.add, size: 18),
                                    color: isDark ? const Color(0xFF34D399) : kBrandEnd,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: outOfStock
                                      ? null
                                      : () {
                                          widget.onAddToCart!(
                                            medicine.copyWithQuantity(_quantity),
                                          );
                                          Get.snackbar(
                                            isEnglish ? 'Added to Cart' : 'কার্টে যোগ হয়েছে',
                                            isEnglish
                                                ? '${medicine.name} has been added to your cart'
                                                : '${medicine.nameBangla} আপনার কার্টে যোগ করা হয়েছে',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: kBrandEnd,
                                            colorText: Colors.white,
                                            duration: const Duration(seconds: 2),
                                            margin: const EdgeInsets.all(12),
                                            borderRadius: 12,
                                            icon: const Icon(Icons.check_circle, color: Colors.white),
                                          );
                                        },
                                  icon: Icon(
                                    outOfStock
                                        ? Icons.block
                                        : inCart
                                            ? Icons.check_circle
                                            : Icons.shopping_cart_outlined,
                                  ),
                                  label: Text(
                                    outOfStock
                                        ? (isEnglish ? 'Out of stock' : 'স্টক নেই')
                                        : (inCart
                                              ? (isEnglish ? 'Added' : 'যোগ হয়েছে')
                                              : (isEnglish ? 'Add to Cart' : 'কার্টে যোগ করুন')),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: kBrandEnd,
                                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
          );
        },
      ),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [kBrandStart, kBrandEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.medication, size: 56, color: Colors.white),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color iconBg,
    required Color iconColor,
    required Color titleColor,
    required Color contentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: contentColor, height: 1.7, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required List<String> items,
    required IconData icon,
    required Color bg,
    required Color border,
    required Color iconBg,
    required Color iconColor,
    required Color titleColor,
    required Color itemTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor)),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              items.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 8, right: 12),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
                    ),
                    Expanded(
                      child: Text(
                        items[index],
                        style: TextStyle(fontSize: 14, color: itemTextColor, height: 1.6, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}