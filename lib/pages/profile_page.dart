import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/user.dart';
import '../services/firebase_user_service.dart';
import '../services/reminder_service.dart';
import 'login_page.dart';
import 'register_page.dart';

class ProfilePage extends StatefulWidget {
  final User? user;
  final User? registeredUser;
  final ValueChanged<User>? onLogin;
  final ValueChanged<User>? onRegister;
  final VoidCallback? onLogout;
  // Called after a successful profile edit so parent can refresh state
  final ValueChanged<User>? onProfileUpdated;

  const ProfilePage({
    super.key,
    required this.user,
    this.registeredUser,
    this.onLogin,
    this.onRegister,
    this.onLogout,
    this.onProfileUpdated,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseUserService _service = FirebaseUserService();

  static const Color primaryGreen = Color(0xFF3B82C4);
  static const Color darkTeal = Color(0xFF0F6E56);
  static const Color lightBg = Color(0xFFEAF3F7);
  static const Color borderColor = Color(0xFFC7DEE8);

  // FIX: dark-mode variants — page আগে শুধু light color hardcode করে রাখা ছিল,
  // theme brightness চেক না করার কারণে dark mode এ text/background ঠিকভাবে
  // দেখাচ্ছিল না। এই কালারগুলো dark mode এর জন্য ব্যবহার হবে।
  static const Color darkBg = Color(0xFF10141A);
  static const Color darkCard = Color(0xFF1C1E26);
  static const Color darkFieldBg = Color(0xFF262A33);
  static const Color darkBorder = Color(0x1FFFFFFF); // white @ 12%
  static const Color darkHeading = Color(0xFF5FD9B8); // light teal accent
  static const Color darkSecondaryText = Color(0xFF8A93A3);
  static const Color darkPrimaryText = Colors.white;

  // Local copy so edits reflect immediately without waiting for parent rebuild
  late User? _localUser;

  @override
  void initState() {
    super.initState();
    _localUser = widget.user;
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      _localUser = widget.user;
    }
  }

  void _handleLogin(User user) {
    widget.onLogin?.call(user);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  void _handleRegister(User user) {
    widget.onRegister?.call(user);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditBottomSheet(
        user: _localUser!,
        service: _service,
        onSaved: (updated) {
          setState(() => _localUser = updated);
          widget.onProfileUpdated?.call(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? darkBg : lightBg,
      body: SafeArea(
        child: _localUser == null
            ? _buildLoggedOut(isDark)
            : _buildLoggedIn(_localUser!, isDark),
      ),
    );
  }

  // ── Logged Out ───────────────────────────────────────────────────────────────

  Widget _buildLoggedOut(bool isDark) {
    final headingColor = isDark ? darkPrimaryText : darkTeal;
    final secondaryColor = isDark ? darkSecondaryText : const Color(0xFF6FA0B0);
    final cardColor = isDark ? darkCard : Colors.white;
    final effectiveBorder = isDark ? darkBorder : borderColor;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          // Top header
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? darkBg : lightBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: effectiveBorder, width: 1.5),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 12,
                        child: Container(
                          width: 28,
                          height: 20,
                          decoration: BoxDecoration(
                            color: primaryGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text(
                              '+',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 22,
                        child: Container(
                          width: 26,
                          height: 18,
                          decoration: BoxDecoration(
                            color: darkTeal,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                      const Positioned(
                        top: 14,
                        right: 16,
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFF5FA8D6),
                        ),
                      ),
                      const Positioned(
                        top: 10,
                        right: 24,
                        child: CircleAvatar(
                          radius: 4,
                          backgroundColor: primaryGreen,
                        ),
                      ),
                      const Positioned(
                        top: 14,
                        right: 32,
                        child: CircleAvatar(
                          radius: 2.5,
                          backgroundColor: Color(0xFFF9C74F),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Med',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: primaryGreen,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextSpan(
                        text: 'Info',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: darkTeal,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Medicine Information App',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),

          // Login / Register card
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Card(
              elevation: 0,
              color: cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: effectiveBorder, width: 0.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Your Profile 👤',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: headingColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sign in to access your profile, orders & more',
                      style: TextStyle(fontSize: 12, color: secondaryColor),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text(
                          'Login to your account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LoginPage(onLogin: _handleLogin),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text(
                          'Create new account',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RegisterPage(onRegister: _handleRegister),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryGreen,
                          side: const BorderSide(
                            color: primaryGreen,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Features
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why create an account?',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: secondaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: Icons.history_rounded,
                  title: 'Order History',
                  subtitle: 'Track all your medicine orders',
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.favorite_border_rounded,
                  title: 'Wishlist',
                  subtitle: 'Save medicines for later',
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Get alerts on price changes',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Logged In ────────────────────────────────────────────────────────────────

  Widget _buildLoggedIn(User user, bool isDark) {
    final headingColor = isDark ? darkPrimaryText : darkTeal;
    final cardColor = isDark ? darkCard : Colors.white;
    final effectiveBorder = isDark ? darkBorder : borderColor;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        children: [
          // Header with avatar card — same gradient as original, Edit btn added
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? darkBg : lightBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Profile',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: headingColor,
                      ),
                    ),
                    // ── Edit button ──
                    TextButton.icon(
                      onPressed: _openEditSheet,
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: primaryGreen,
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          color: primaryGreen,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor: primaryGreen.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Avatar gradient card — same as original (works fine on dark too)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryGreen, darkTeal],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'M',
                            style: const TextStyle(
                              fontSize: 26,
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
                              user.name.isNotEmpty ? user.name : 'User',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            // Blood group badge (shows only if set)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '✓ Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (user.bloodGroup.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.bloodtype_outlined,
                                          size: 10,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          user.bloodGroup,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Account Information ──
                Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: effectiveBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      _ProfileInfoRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Full Name',
                        value: user.name.isNotEmpty ? user.name : '—',
                      ),
                      _divider(isDark),
                      _ProfileInfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: user.email.isNotEmpty ? user.email : '—',
                      ),
                      _divider(isDark),
                      _ProfileInfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: (user.phone.isEmpty || user.phone == 'Not set')
                            ? '—'
                            : user.phone,
                      ),
                      _divider(isDark),
                      _ProfileInfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Address',
                        value:
                            (user.address.isEmpty || user.address == 'Not set')
                            ? '—'
                            : user.address,
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Medical Information ──
                Text(
                  'Medical Information',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: effectiveBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      _ProfileInfoRow(
                        icon: Icons.bloodtype_outlined,
                        label: 'Blood Group',
                        value: user.bloodGroup.isEmpty ? '—' : user.bloodGroup,
                        iconColor: const Color(0xFFE24B4A),
                      ),
                      _divider(isDark),
                      _ProfileInfoRow(
                        icon: Icons.monitor_weight_outlined,
                        label: 'Weight',
                        value: user.weight == null ? '—' : '${user.weight} kg',
                      ),
                      _divider(isDark),
                      _ProfileInfoRow(
                        icon: Icons.height_rounded,
                        label: 'Height',
                        value: user.height == null ? '—' : '${user.height} feet',
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Health Conditions ──
                Text(
                  'Health Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: headingColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: effectiveBorder, width: 1),
                  ),
                  child: Column(
                    children: [
                      _ConditionRow(
                        label: 'Diabetes',
                        value: user.hasDiabetes,
                        icon: Icons.water_drop_outlined,
                        iconColor: const Color(0xFFBA7517),
                      ),
                      _divider(isDark),
                      _ConditionRow(
                        label: 'Hypertension',
                        value: user.hasHypertension,
                        icon: Icons.monitor_heart_outlined,
                        iconColor: const Color(0xFFE24B4A),
                      ),
                      _divider(isDark),
                      _ConditionRow(
                        label: 'Thyroid',
                        value: user.hasThyroid,
                        icon: Icons.biotech_outlined,
                      ),
                      _divider(isDark),
                      _ConditionRow(
                        label: 'Heart Disease',
                        value: user.hasHeartDisease,
                        icon: Icons.favorite_border_rounded,
                        iconColor: const Color(0xFFE24B4A),
                      ),
                      _divider(isDark),
                      _ConditionRow(
                        label: 'Asthma',
                        value: user.hasAsthma,
                        icon: Icons.air_outlined,
                        iconColor: const Color(0xFF185FA5),
                        isLast: true,
                      ),
                    ],
                  ),
                ),

                // ── Emergency Contact (shows only if filled) ──
                if (user.emergencyContactName.isNotEmpty ||
                    user.emergencyContactPhone.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Emergency Contact',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: headingColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: effectiveBorder, width: 1),
                    ),
                    child: Column(
                      children: [
                        if (user.emergencyContactName.isNotEmpty)
                          _ProfileInfoRow(
                            icon: Icons.person_pin_outlined,
                            label: 'Name',
                            value: user.emergencyContactName,
                          ),
                        if (user.emergencyContactName.isNotEmpty &&
                            user.emergencyContactPhone.isNotEmpty)
                          _divider(isDark),
                        if (user.emergencyContactPhone.isNotEmpty)
                          _ProfileInfoRow(
                            icon: Icons.phone_callback_outlined,
                            label: 'Phone',
                            value: user.emergencyContactPhone,
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Logout button — same as original ──
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD32F2F),
                      side: const BorderSide(
                        color: Color(0xFFD32F2F),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () async {
                      await ReminderService().cancelAllOnLogout();
                      await _service.signOut();
                      if (!mounted) return;
                      Get.snackbar(
                        'Logged out',
                        'You have been logged out successfully',
                        backgroundColor: const Color(0xFFEAF3F7),
                        colorText: const Color(0xFF0F6E56),
                        snackPosition: SnackPosition.TOP,
                        borderRadius: 12,
                        margin: const EdgeInsets.all(12),
                      );
                      widget.onLogout?.call();
                    },
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Divider(
        height: 0,
        indent: 56,
        color: (isDark ? darkBorder : borderColor).withValues(alpha: 0.5),
      );
}

// ─── Edit Bottom Sheet ─────────────────────────────────────────────────────────

class _EditBottomSheet extends StatefulWidget {
  final User user;
  final FirebaseUserService service;
  final ValueChanged<User> onSaved;

  const _EditBottomSheet({
    required this.user,
    required this.service,
    required this.onSaved,
  });

  @override
  State<_EditBottomSheet> createState() => _EditBottomSheetState();
}

class _EditBottomSheetState extends State<_EditBottomSheet> {
  static const Color primaryGreen = Color(0xFF3B82C4);
  static const Color darkTeal = Color(0xFF0F6E56);
  static const Color fieldBg = Color(0xFFF2F8FA);
  static const Color borderColor = Color(0xFFC7DEE8);

  // FIX: dark-mode variants for the edit sheet
  static const Color darkSheetBg = Color(0xFF1C1E26);
  static const Color darkFieldBg = Color(0xFF262A33);
  static const Color darkBorder = Color(0x1FFFFFFF);
  static const Color darkHeading = Colors.white;
  static const Color darkLabel = Color(0xFF8A93A3);

  static const List<String> _bloodGroups = [
    'A+',
    'A−',
    'B+',
    'B−',
    'AB+',
    'AB−',
    'O+',
    'O−',
  ];

  bool _isSaving = false;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _emergencyNameCtrl;
  late final TextEditingController _emergencyPhoneCtrl;

  late String _bloodGroup;
  late bool _hasDiabetes;
  late bool _hasHypertension;
  late bool _hasThyroid;
  late bool _hasHeartDisease;
  late bool _hasAsthma;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.name);
    _phoneCtrl = TextEditingController(text: u.phone);
    _addressCtrl = TextEditingController(text: u.address);
    _weightCtrl = TextEditingController(text: u.weight?.toString() ?? '');
    _heightCtrl = TextEditingController(text: u.height?.toString() ?? '');
    _emergencyNameCtrl = TextEditingController(text: u.emergencyContactName);
    _emergencyPhoneCtrl = TextEditingController(text: u.emergencyContactPhone);
    _bloodGroup = u.bloodGroup;
    _hasDiabetes = u.hasDiabetes;
    _hasHypertension = u.hasHypertension;
    _hasThyroid = u.hasThyroid;
    _hasHeartDisease = u.hasHeartDisease;
    _hasAsthma = u.hasAsthma;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final updated = widget.user.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        bloodGroup: _bloodGroup,
        weight: _weightCtrl.text.trim().isNotEmpty
            ? double.tryParse(_weightCtrl.text.trim())
            : null,
        height: _heightCtrl.text.trim().isNotEmpty
            ? double.tryParse(_heightCtrl.text.trim())
            : null,
        hasDiabetes: _hasDiabetes,
        hasHypertension: _hasHypertension,
        hasThyroid: _hasThyroid,
        hasHeartDisease: _hasHeartDisease,
        hasAsthma: _hasAsthma,
        emergencyContactName: _emergencyNameCtrl.text.trim(),
        emergencyContactPhone: _emergencyPhoneCtrl.text.trim(),
      );

      await widget.service.updateUser(updated);
      widget.onSaved(updated);

      if (mounted) Navigator.of(context).pop();

      Get.snackbar(
        'Saved!',
        'Your profile has been updated.',
        backgroundColor: const Color(0xFFEAF3F7),
        colorText: const Color(0xFF0F6E56),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Could not save changes. Please try again.',
        backgroundColor: const Color(0xFFFCEBEB),
        colorText: const Color(0xFFA32D2D),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? darkHeading : darkTeal, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? darkLabel : const Color(0xFF8FB4C9),
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: primaryGreen, size: 20),
        filled: true,
        fillColor: isDark ? darkFieldBg : fieldBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? darkBorder : borderColor,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
      ),
    );
  }

  Widget _toggleRow(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    Color iconColor = primaryGreen,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? darkFieldBg : fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? darkBorder : borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? darkHeading : darkTeal,
                fontSize: 14,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: primaryGreen,
            activeTrackColor: const Color(0xFFA8D4E0),
            inactiveThumbColor: isDark
                ? const Color(0xFF565F70)
                : const Color(0xFF8FB4C9),
            inactiveTrackColor: isDark ? darkFieldBg : const Color(0xFFEAF3F7),
          ),
          SizedBox(
            width: 28,
            child: Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value
                    ? (isDark ? darkHeading : darkTeal)
                    : (isDark ? darkLabel : const Color(0xFF8FB4C9)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? darkHeading : darkTeal;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkSheetBg : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? darkBorder : const Color(0xFFC7DEE8),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: headingColor,
              ),
            ),
            const SizedBox(height: 16),

            // Basic fields
            _field(
              _nameCtrl,
              'Full Name',
              Icons.person_outline_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _field(
              _phoneCtrl,
              'Phone Number',
              Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _field(
              _addressCtrl,
              'Address',
              Icons.location_on_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Blood group dropdown
            DropdownButtonFormField<String>(
              initialValue: _bloodGroup.isEmpty ? null : _bloodGroup,
              style: TextStyle(
                color: isDark ? darkHeading : darkTeal,
                fontSize: 14,
              ),
              dropdownColor: isDark ? darkFieldBg : Colors.white,
              decoration: InputDecoration(
                labelText: 'Blood Group',
                labelStyle: TextStyle(
                  color: isDark ? darkLabel : const Color(0xFF8FB4C9),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.bloodtype_outlined,
                  color: Color(0xFFE24B4A),
                  size: 20,
                ),
                filled: true,
                fillColor: isDark ? darkFieldBg : fieldBg,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark ? darkBorder : borderColor,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                ),
              ),
              hint: Text(
                'Select blood group',
                style: TextStyle(
                  color: isDark ? darkLabel : const Color(0xFF8FB4C9),
                  fontSize: 13,
                ),
              ),
              items: _bloodGroups
                  .map(
                    (g) => DropdownMenuItem(
                      value: g,
                      child: Text(
                        g,
                        style: TextStyle(
                          color: isDark ? darkHeading : darkTeal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _bloodGroup = v ?? _bloodGroup),
            ),
            const SizedBox(height: 12),

            // Weight & Height
            Row(
              children: [
                Expanded(
                  child: _field(
                    _weightCtrl,
                    'Weight (kg)',
                    Icons.monitor_weight_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    _heightCtrl,
                    'Height (feet)',
                    Icons.height_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Health conditions
            Text(
              'Health Conditions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: headingColor,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            _toggleRow(
              'Diabetes',
              Icons.water_drop_outlined,
              _hasDiabetes,
              (v) => setState(() => _hasDiabetes = v),
              iconColor: const Color(0xFFBA7517),
              isDark: isDark,
            ),
            _toggleRow(
              'Hypertension',
              Icons.monitor_heart_outlined,
              _hasHypertension,
              (v) => setState(() => _hasHypertension = v),
              iconColor: const Color(0xFFE24B4A),
              isDark: isDark,
            ),
            _toggleRow(
              'Thyroid',
              Icons.biotech_outlined,
              _hasThyroid,
              (v) => setState(() => _hasThyroid = v),
              isDark: isDark,
            ),
            _toggleRow(
              'Heart Disease',
              Icons.favorite_border_rounded,
              _hasHeartDisease,
              (v) => setState(() => _hasHeartDisease = v),
              iconColor: const Color(0xFFE24B4A),
              isDark: isDark,
            ),
            _toggleRow(
              'Asthma',
              Icons.air_outlined,
              _hasAsthma,
              (v) => setState(() => _hasAsthma = v),
              iconColor: const Color(0xFF185FA5),
              isDark: isDark,
            ),

            const SizedBox(height: 4),
            Text(
              'Emergency Contact',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: headingColor,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 10),
            _field(
              _emergencyNameCtrl,
              'Contact Person Name',
              Icons.person_pin_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _field(
              _emergencyPhoneCtrl,
              'Contact Phone',
              Icons.phone_callback_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: headingColor,
                      side: BorderSide(
                        color: isDark ? darkBorder : borderColor,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF8FB4C9),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
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

// ─── Condition Row widget ─────────────────────────────────────────────────────

class _ConditionRow extends StatelessWidget {
  final String label;
  final bool value;
  final IconData icon;
  final Color iconColor;
  final bool isLast;

  const _ConditionRow({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = const Color(0xFF3B82C4),
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? const Color(0xFF8A93A3) : const Color(0xFF6FA0B0);

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 14, isLast ? 12 : 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isDark
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFEAF3F7), Color(0xFFF2F8FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isDark ? Colors.white.withValues(alpha: 0.05) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: value
                  ? (isDark
                      ? const Color(0xFFBA7517).withValues(alpha: 0.18)
                      : const Color(0xFFFAEEDA))
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFEAF3F7)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value ? 'Yes' : 'No',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value
                    ? (isDark ? const Color(0xFFE0A94D) : const Color(0xFF854F0B))
                    : (isDark ? Colors.white : const Color(0xFF0F6E56)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Feature Card (logged out screen) ─────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF3B82C4);
    const Color borderColor = Color(0xFFC7DEE8);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F6E56);
    final subtitleColor =
        isDark ? const Color(0xFF8A93A3) : const Color(0xFF6FA0B0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x1FFFFFFF) : borderColor,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isDark
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFEAF3F7), Color(0xFFF2F8FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isDark ? Colors.white.withValues(alpha: 0.05) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Info Row ─────────────────────────────────────────────────────────

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  final Color? iconColor;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF3B82C4);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? const Color(0xFF8A93A3) : const Color(0xFF6FA0B0);
    final valueColor = isDark ? Colors.white : const Color(0xFF0F6E56);

    return Padding(
      padding: EdgeInsets.fromLTRB(14, 12, 14, isLast ? 12 : 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: isDark
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFEAF3F7), Color(0xFFF2F8FA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              color: isDark ? Colors.white.withValues(alpha: 0.05) : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: labelColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}