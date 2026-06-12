import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'models/medicine.dart';
import 'models/user.dart';
import 'pages/home_page.dart';
import 'pages/medicine_list_demo_page.dart';
import 'pages/search_page.dart';
import 'pages/cart_page.dart';
import 'pages/profile_page.dart';
import 'pages/reminder_page.dart';
import 'pages/login_page.dart';
import 'services/firebase_user_service.dart';

class AppController extends GetxController {
  final FirebaseUserService _firebaseUserService = FirebaseUserService();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxInt currentIndex = 0.obs;
  final RxList<Medicine> cart = <Medicine>[].obs;
  final List<Medicine> medicines = MedicineListDemoPage.sampleMedicines;

  final RxBool isDarkMode = false.obs;
  void toggleDarkMode() => isDarkMode.value = !isDarkMode.value;

  // ── Auth check (splash) ──────────────────────────────────────────────────
  final RxBool isCheckingAuth = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _firebaseUserService.loadCurrentUser();
      if (user != null) currentUser.value = user;
    } catch (_) {
      // not logged in / no internet — stay on login screen
    } finally {
      isCheckingAuth.value = false;
    }
  }

  void updateUser(User user) {
    currentUser.value = user;
    currentIndex.value = 0;
  }

  Future<void> logout() async {
    await _firebaseUserService.signOut();
    currentUser.value = null;
    currentIndex.value = 0;
  }

  void navigateToTab(int index) => currentIndex.value = index;

  void addToCart(Medicine medicine) {
    if (isInCart(medicine)) return;
    cart.add(medicine);
  }

  void removeFromCart(Medicine medicine) {
    cart.removeWhere((item) => item.name == medicine.name);
  }

  bool isInCart(Medicine medicine) {
    return cart.any((item) => item.name == medicine.name);
  }
}

// ─── AppShell (Auth Gate) ────────────────────────────────────────────────────
// App open হলে এখানে প্রথমে check হয়:
//  - auth check চলাকালীন → Splash
//  - currentUser == null → Login/Register flow
//  - currentUser != null → Main bottom-nav shell

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.put(AppController());

    return Obx(() {
      if (controller.isCheckingAuth.value) {
        return const _SplashScreen();
      }

      if (controller.currentUser.value == null) {
        // Nested navigator so Login ↔ Register switching works with push/pop
        return Navigator(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (_) => LoginPage(onLogin: controller.updateUser),
            );
          },
        );
      }

      return _MainShell(controller: controller);
    });
  }
}

// ─── Splash Screen ───────────────────────────────────────────────────────────

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A56DB), Color(0xFF6366F1)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  size: 44,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Main Shell (bottom-nav UI, shown after login) ──────────────────────────

class _MainShell extends StatelessWidget {
  final AppController controller;

  const _MainShell({required this.controller});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppController>(
      builder: (ctrl) => Obx(() {
        Widget getPage() {
          switch (controller.currentIndex.value) {
            case 0:
              return HomePage(
                medicines: controller.medicines,
                cart: controller.cart,
                onAddToCart: controller.addToCart,
                isInCart: controller.isInCart,
                userName: controller.currentUser.value?.name,
                onProfileTap: () => controller.navigateToTab(3),
              );
            case 1:
              return SearchPage(
                medicines: controller.medicines,
                cart: controller.cart,
                onAddToCart: controller.addToCart,
                isInCart: controller.isInCart,
              );
            case 2:
              return CartPage(
                cartItems: controller.cart,
                onRemove: controller.removeFromCart,
                onBrowseMedicines: () =>
                    Get.to(() => const MedicineListDemoPage()),
              );
            case 3:
              return ProfilePage(
                user: controller.currentUser.value,
                registeredUser: controller.currentUser.value,
                onLogin: controller.updateUser,
                onRegister: controller.updateUser,
                onLogout: controller.logout,
              );
            case 4:
              return const ReminderPage();
            default:
              return HomePage(
                medicines: controller.medicines,
                cart: controller.cart,
                onAddToCart: controller.addToCart,
                isInCart: controller.isInCart,
                userName: controller.currentUser.value?.name,
                onProfileTap: () => controller.navigateToTab(3),
              );
          }
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          drawer: _AppDrawer(controller: controller),
          body: getPage(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: controller.navigateToTab,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search_rounded),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                activeIcon: Icon(Icons.shopping_cart_rounded),
                label: 'Cart',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.alarm_outlined),
                activeIcon: Icon(Icons.alarm_rounded),
                label: 'Reminder',
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─── Redesigned App Drawer ──────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final AppController controller;

  const _AppDrawer({required this.controller});

  static const Color _primary = Color(0xFF1A56DB);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final user = controller.currentUser.value;
      final userName = user?.name ?? 'Guest User';
      final userEmail = user?.email ?? 'Login or register';
      final initial = userName.isNotEmpty && userName != 'Guest User'
          ? userName[0].toUpperCase()
          : 'G';

      return Drawer(
        backgroundColor: isDark
            ? const Color(0xFF1C1E26)
            : const Color(0xFFF8F9FC),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A56DB), Color(0xFF3B7AF7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '✓ Verified Member',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ── Nav Items ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  children: [
                    _DrawerSection(label: 'Navigation'),
                    _DrawerItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToTab(0);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.search_rounded,
                      label: 'Search Medicines',
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToTab(1);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.shopping_cart_rounded,
                      label: 'My Cart',
                      badge: controller.cart.isNotEmpty
                          ? '${controller.cart.length}'
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToTab(2);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToTab(3);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.alarm_rounded,
                      label: 'Medicine Reminders',
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToTab(4);
                      },
                    ),
                    _DrawerItem(
                      icon: Icons.category_rounded,
                      label: 'All Categories',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CategoriesPage(
                              categories: controller.medicines
                                  .map((m) => m.category)
                                  .toSet()
                                  .toList(),
                              allMedicines: controller.medicines,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    _DrawerSection(label: 'Preferences'),

                    // ── Dark Mode Toggle ──
                    Obx(
                      () => _DrawerToggle(
                        icon: controller.isDarkMode.value
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        iconColor: controller.isDarkMode.value
                            ? const Color(0xFFFFC107)
                            : const Color(0xFF1A56DB),
                        label: 'Dark Mode',
                        value: controller.isDarkMode.value,
                        onChanged: (_) => controller.toggleDarkMode(),
                      ),
                    ),

                    _DrawerItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 8),
                    _DrawerSection(label: 'Account'),

                    user != null
                        ? _DrawerItem(
                            icon: Icons.logout_rounded,
                            label: 'Logout',
                            iconColor: Colors.red.shade400,
                            labelColor: Colors.red.shade400,
                            onTap: () async {
                              Navigator.pop(context);
                              await controller.logout();
                            },
                          )
                        : _DrawerItem(
                            icon: Icons.login_rounded,
                            label: 'Login / Register',
                            onTap: () {
                              Navigator.pop(context);
                              controller.navigateToTab(3);
                            },
                          ),

                    _DrawerItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About MedInfo BD',
                      onTap: () {
                        Navigator.pop(context);
                        showAboutDialog(
                          context: context,
                          applicationName: 'MedInfo BD',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2026 MedInfo BD',
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── Footer ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Text(
                  'MedInfo BD v1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ─── Drawer Helper Widgets ──────────────────────────────────────────────────────

class _DrawerSection extends StatelessWidget {
  final String label;
  const _DrawerSection({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Color? iconColor;
  final Color? labelColor;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.iconColor,
    this.labelColor,
  });

  static const Color _primary = Color(0xFF1A56DB);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIconColor = iconColor ?? _primary;
    final effectiveLabelColor =
        labelColor ?? (isDark ? Colors.white : const Color(0xFF0F1117));

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: effectiveIconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: effectiveLabelColor,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DrawerToggle({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F1117),
              ),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: const Color(0xFF1A56DB),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Categories Page ────────────────────────────────────────────────────────────

class CategoriesPage extends StatelessWidget {
  final List<String> categories;
  final List<Medicine> allMedicines;

  const CategoriesPage({
    super.key,
    required this.categories,
    required this.allMedicines,
  });

  static const List<Map<String, dynamic>> _categoryMeta = [
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

  Map<String, dynamic> _getMeta(String category) {
    return _categoryMeta.firstWhere(
      (c) => c['label'] == category,
      orElse: () => {
        'icon': Icons.category_rounded,
        'bg': const Color(0xFFEEF2FF),
        'iconColor': const Color(0xFF1A56DB),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: categories.isEmpty
          ? const Center(child: Text('No categories available.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final count = allMedicines
                    .where((m) => m.category == category)
                    .length;
                final meta = _getMeta(category);

                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CategoryMedicinesPage(
                        category: category,
                        medicines: allMedicines
                            .where((m) => m.category == category)
                            .toList(),
                      ),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.withOpacity(0.1),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: meta['bg'] as Color,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            meta['icon'] as IconData,
                            size: 22,
                            color: meta['iconColor'] as Color,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F1117),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$count medicines',
                          style: TextStyle(
                            fontSize: 11,
                            color: meta['iconColor'] as Color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

// ─── Category Medicines Page ────────────────────────────────────────────────────

class CategoryMedicinesPage extends StatelessWidget {
  final String category;
  final List<Medicine> medicines;

  const CategoryMedicinesPage({
    super.key,
    required this.category,
    required this.medicines,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: medicines.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No medicines found for $category',
                    style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final medicine = medicines[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1E26) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.06)
                          : Colors.grey.withOpacity(0.1),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.medication_rounded,
                          color: Color(0xFF1A56DB),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicine.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F1117),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              medicine.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '৳${medicine.displayPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A56DB),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ─── Settings Page ──────────────────────────────────────────────────────────────

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
            subtitle: Text('Manage push and email preferences'),
          ),
          ListTile(
            leading: Icon(Icons.language_outlined),
            title: Text('Language'),
            subtitle: Text('Change app language'),
          ),
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy'),
            subtitle: Text('View privacy settings'),
          ),
        ],
      ),
    );
  }
}