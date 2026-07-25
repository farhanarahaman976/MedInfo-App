import 'package:get/get.dart';

/// Shared controller — AdminShell er bottom nav index track kore,
/// jate AdminOverviewPage-er stat card theke tap kore onno tab-e jawa jay.
class AdminTabController extends GetxController {
  final RxInt currentIndex = 0.obs;

  void goToTab(int index) {
    currentIndex.value = index;
  }
}