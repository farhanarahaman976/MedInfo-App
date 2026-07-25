import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_shell.dart';
import '../services/reminder_service.dart';
import 'admin_tab_controller.dart';

import 'admin_overview_page.dart';
import 'admin_medicines_page.dart';
import 'admin_orders_page.dart';
import 'admin_users_page.dart';
import 'admin_health_tips_page.dart'; // NOTUN

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  static const Color _logoGradientStart = Color(0xFF3B82C4);
  static const Color _logoGradientEnd = Color(0xFF0F6E56);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [_logoGradientStart, _logoGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final AdminTabController _tabController = Get.put(AdminTabController());

  // NOTUN: Health Tips tab add kora hoise
  final List<Widget> _pages = const [
    AdminOverviewPage(),
    AdminOrdersPage(),
    AdminMedicinesPage(),
    AdminUsersPage(),
    AdminHealthTipsPage(),
  ];

  final List<String> _titles = const [
    'Overview',
    'Orders',
    'Medicines',
    'Users',
    'Health Tips',
  ];

  static const List<IconData> _outlineIcons = [
    Icons.dashboard_outlined,
    Icons.receipt_long_outlined,
    Icons.medication_outlined,
    Icons.people_outline,
    Icons.tips_and_updates_outlined,
  ];

  static const List<IconData> _filledIcons = [
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.medication_rounded,
    Icons.people_alt_rounded,
    Icons.tips_and_updates_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.find<AppController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => PopScope(
        // Back gesture/button first returns to the Overview tab;
        // only exits the app once already on Overview (index 0).
        canPop: _tabController.currentIndex.value == 0,
        onPopInvoked: (didPop) {
          if (didPop) return;
          _tabController.currentIndex.value = 0;
        },
        child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 68,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: brandGradient),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ADMIN PANEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _titles[_tabController.currentIndex.value],
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            _AppBarIconButton(
              icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              tooltip: 'Toggle theme',
              onPressed: controller.toggleDarkMode,
            ),
            const SizedBox(width: 6),
            _AppBarIconButton(
              icon: Icons.logout_rounded,
              tooltip: 'Logout',
              onPressed: () async {
                await ReminderService().cancelAllOnLogout();
                await controller.logout();
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _tabController.currentIndex.value,
          children: _pages,
        ),
        bottomNavigationBar: _PillBottomNav(
          currentIndex: _tabController.currentIndex.value,
          onTap: (index) => _tabController.currentIndex.value = index,
          isDark: isDark,
          titles: _titles,
          outlineIcons: _outlineIcons,
          filledIcons: _filledIcons,
          gradient: brandGradient,
        ),
        ),
      ),
    );
  }
}

class _AppBarIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _AppBarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 21, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PillBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isDark;
  final List<String> titles;
  final List<IconData> outlineIcons;
  final List<IconData> filledIcons;
  final LinearGradient gradient;

  const _PillBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.isDark,
    required this.titles,
    required this.outlineIcons,
    required this.filledIcons,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        // NOTUN: label na thakay ekhon shob tab-i equal width e spaceEvenly
        // diye rakha jay, horizontal scroll-er dorkar nai
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < titles.length; i++)
              _NavItem(
                selected: currentIndex == i,
                tooltip: titles[i],
                icon: currentIndex == i ? filledIcons[i] : outlineIcons[i],
                isDark: isDark,
                gradient: gradient,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final String tooltip;
  final IconData icon;
  final bool isDark;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.tooltip,
    required this.icon,
    required this.isDark,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // NOTUN: label text soriye shudhu icon rakha holo — tooltip-e naam ta
    // dekha jabe long-press/hover korle, kintu bar-e text lekha thakbe na
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? gradient : null,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Icon(
            icon,
            size: 24,
            color: selected ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}