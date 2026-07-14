import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app_shell.dart';
import '../services/reminder_service.dart';

import 'admin_overview_page.dart';
import 'admin_medicines_page.dart';
import 'admin_orders_page.dart';
import 'admin_users_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  // ── Brand gradient — app-er logo/hero card-er exact color ──
  static const Color _logoGradientStart = Color(0xFF3B82C4);
  static const Color _logoGradientEnd = Color(0xFF0F6E56);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [_logoGradientStart, _logoGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final RxInt _currentIndex = 0.obs;

  final List<Widget> _pages = const [
    AdminOverviewPage(),
    AdminOrdersPage(),
    AdminMedicinesPage(),
    AdminUsersPage(),
  ];

  final List<String> _titles = const [
    'Overview',
    'Orders',
    'Medicines',
    'Users',
  ];

  @override
  Widget build(BuildContext context) {
    final AppController controller = Get.find<AppController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            decoration: const BoxDecoration(gradient: brandGradient),
          ),
          title: Text(
            'Admin • ${_titles[_currentIndex.value]}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white,
              ),
              tooltip: 'Toggle theme',
              onPressed: controller.toggleDarkMode,
            ),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: 'Logout',
              onPressed: () async {
                await ReminderService().cancelAllOnLogout();
                await controller.logout();
              },
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex.value,
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex.value,
          onDestinationSelected: (index) => _currentIndex.value = index,
          backgroundColor: isDark ? const Color(0xFF1C1E26) : Colors.white,
          indicatorColor: _logoGradientStart.withValues(alpha: 0.12),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: _logoGradientStart),
              label: 'Overview',
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long, color: _logoGradientStart),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: const Icon(Icons.medication_outlined),
              selectedIcon: Icon(Icons.medication, color: _logoGradientStart),
              label: 'Medicines',
            ),
            NavigationDestination(
              icon: const Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people, color: const Color.fromRGBO(59, 130, 196, 1)),
              label: 'Users',
            ),
          ],
        ),
      ),
    );
  }
}