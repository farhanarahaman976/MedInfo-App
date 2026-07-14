import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/user.dart';
import '../services/firebase_user_service.dart';

// ─── RegisterController ────────────────────────────────────────────────────────

class RegisterController extends GetxController {
  final FirebaseUserService _service = FirebaseUserService();
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;

  // ── Health condition toggles ──
  final RxBool hasDiabetes = false.obs;
  final RxBool hasHypertension = false.obs;
  final RxBool hasThyroid = false.obs;
  final RxBool hasHeartDisease = false.obs;
  final RxBool hasAsthma = false.obs;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String address,
    required String bloodGroup,
    required double? weight,
    required double? height,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required void Function(User user) onSuccess,
  }) async {
    isLoading.value = true;
    try {
      final user = await _service.registerUser(
        name: name,
        email: email,
        password: password,
        phone: phone,
        address: address,
        bloodGroup: bloodGroup,
        weight: weight,
        height: height,
        hasDiabetes: hasDiabetes.value,
        hasHypertension: hasHypertension.value,
        hasThyroid: hasThyroid.value,
        hasHeartDisease: hasHeartDisease.value,
        hasAsthma: hasAsthma.value,
        emergencyContactName: emergencyContactName,
        emergencyContactPhone: emergencyContactPhone,
      );

      Get.snackbar(
        'Account Created!',
        'Welcome, ${user.name}!',
        backgroundColor: const Color(0xFFEAF3F7),
        colorText: const Color(0xFF0F6E56),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );

      onSuccess(user);
    } on fb_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered. Please login instead.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          message = 'Password must be at least 6 characters.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        default:
          message = 'Registration failed: ${e.message ?? e.code}';
      }
      Get.snackbar(
        'Registration Failed',
        message,
        backgroundColor: const Color(0xFFFCEBEB),
        colorText: const Color(0xFFA32D2D),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.\n$e',
        backgroundColor: const Color(0xFFFCEBEB),
        colorText: const Color(0xFFA32D2D),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

// ─── RegisterPage ──────────────────────────────────────────────────────────────

class RegisterPage extends StatefulWidget {
  final ValueChanged<User> onRegister;

  const RegisterPage({super.key, required this.onRegister});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final RegisterController _controller = Get.put(RegisterController());
  final _formKey = GlobalKey<FormState>();

  // ── Basic info controllers ──
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // ── Medical info controllers ──
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  String _selectedBloodGroup = '';

  // ── Same colors as LoginPage ──
  static const Color primaryGreen = Color(0xFF3B82C4);
  static const Color darkTeal = Color(0xFF0F6E56);
  static const Color lightBg = Color(0xFFEAF3F7);
  static const Color fieldBg = Color(0xFFF2F8FA);
  static const Color borderColor = Color(0xFFC7DEE8);

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    _controller.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      bloodGroup: _selectedBloodGroup,
      weight: _weightController.text.trim().isNotEmpty
          ? double.tryParse(_weightController.text.trim())
          : null,
      height: _heightController.text.trim().isNotEmpty
          ? double.tryParse(_heightController.text.trim())
          : null,
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      onSuccess: (user) => widget.onRegister(user),
    );
  }

  // ── Section label widget ──
  Widget _sectionLabel(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 15, color: primaryGreen),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkTeal,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 0.5, color: borderColor)),
        ],
      ),
    );
  }

  // ── Blood group dropdown ──
  Widget _buildBloodGroupDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedBloodGroup.isEmpty ? null : _selectedBloodGroup,
      style: const TextStyle(color: darkTeal, fontSize: 14),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: 'Blood Group',
        labelStyle: const TextStyle(color: Color(0xFF8FB4C9), fontSize: 13),
        prefixIcon: const Icon(
          Icons.bloodtype_outlined,
          color: Color(0xFFE24B4A),
          size: 20,
        ),
        filled: true,
        fillColor: fieldBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
        ),
      ),
      hint: const Text(
        'Select blood group',
        style: TextStyle(color: Color(0xFF8FB4C9), fontSize: 13),
      ),
      items: _bloodGroups
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(
                g,
                style: const TextStyle(color: darkTeal, fontSize: 14),
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedBloodGroup = v ?? ''),
    );
  }

  // ── Health condition toggle row ──
  Widget _buildToggleRow({
    required String label,
    required IconData icon,
    required RxBool value,
    Color iconColor = primaryGreen,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: darkTeal, fontSize: 14),
            ),
          ),
          Obx(
            () => Switch.adaptive(
              value: value.value,
              onChanged: (v) => value.value = v,
              activeThumbColor: primaryGreen,
              activeTrackColor: const Color(0xFFA8D4E0),
              inactiveThumbColor: const Color(0xFF8FB4C9),
              inactiveTrackColor: const Color(0xFFEAF3F7),
            ),
          ),
          Obx(
            () => SizedBox(
              width: 28,
              child: Text(
                value.value ? 'Yes' : 'No',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: value.value ? darkTeal : const Color(0xFF8FB4C9),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ── Top section with logo (same as LoginPage) ──
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: lightBg,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(48),
                            bottomRight: Radius.circular(48),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                        child: Column(
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: borderColor,
                                  width: 1.5,
                                ),
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
                            const Text(
                              'Medicine Information App',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6FA0B0),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Form Card ──
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: const BorderSide(
                              color: borderColor,
                              width: 0.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Create Account 🏥',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: darkTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Fill in your details to get started',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6FA0B0),
                                    ),
                                  ),

                                  // ════════════════════════════════
                                  // SECTION 1 — Basic Info
                                  // ════════════════════════════════
                                  _sectionLabel(
                                    'BASIC INFO',
                                    Icons.person_outline,
                                  ),
                                  _buildField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline_rounded,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your full name';
                                      }
                                      if (v.trim().length < 2) {
                                        return 'Name must be at least 2 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildField(
                                    controller: _emailController,
                                    label: 'Email Address',
                                    icon: Icons.mail_outline_rounded,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      final reg = RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      );
                                      if (!reg.hasMatch(v.trim())) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Password with toggle
                                  Obx(
                                    () => TextFormField(
                                      controller: _passwordController,
                                      obscureText:
                                          _controller.obscurePassword.value,
                                      style: const TextStyle(
                                        color: darkTeal,
                                        fontSize: 14,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        labelStyle: const TextStyle(
                                          color: Color(0xFF8FB4C9),
                                          fontSize: 13,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.lock_outline_rounded,
                                          color: primaryGreen,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _controller.obscurePassword.value
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: const Color(0xFF8FB4C9),
                                            size: 20,
                                          ),
                                          onPressed: () => _controller
                                              .obscurePassword
                                              .toggle(),
                                        ),
                                        filled: true,
                                        fillColor: fieldBg,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: primaryGreen,
                                            width: 1.5,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE24B4A),
                                            width: 1,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE24B4A),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter a password';
                                        }
                                        if (v.length < 6) {
                                          return 'Password must be at least 6 characters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildField(
                                    controller: _phoneController,
                                    label: 'Phone Number',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildField(
                                    controller: _addressController,
                                    label: 'Address',
                                    icon: Icons.location_on_outlined,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) {
                                        return 'Please enter your address';
                                      }
                                      return null;
                                    },
                                  ),

                                  // ════════════════════════════════
                                  // SECTION 2 — Medical Info
                                  // ════════════════════════════════
                                  _sectionLabel(
                                    'MEDICAL INFO',
                                    Icons.medical_information_outlined,
                                  ),

                                  _buildBloodGroupDropdown(),
                                  const SizedBox(height: 12),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildField(
                                          controller: _weightController,
                                          label: 'Weight (kg)',
                                          icon: Icons.monitor_weight_outlined,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildField(
                                          controller: _heightController,
                                          label: 'Height (cm)',
                                          icon: Icons.height_rounded,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ════════════════════════════════
                                  // SECTION 3 — Health Conditions
                                  // ════════════════════════════════
                                  _sectionLabel(
                                    'HEALTH CONDITIONS',
                                    Icons.favorite_border_rounded,
                                  ),

                                  _buildToggleRow(
                                    label: 'Diabetes',
                                    icon: Icons.water_drop_outlined,
                                    value: _controller.hasDiabetes,
                                    iconColor: const Color(0xFFBA7517),
                                  ),
                                  _buildToggleRow(
                                    label: 'Hypertension',
                                    icon: Icons.monitor_heart_outlined,
                                    value: _controller.hasHypertension,
                                    iconColor: const Color(0xFFE24B4A),
                                  ),
                                  _buildToggleRow(
                                    label: 'Thyroid',
                                    icon: Icons.biotech_outlined,
                                    value: _controller.hasThyroid,
                                    iconColor: primaryGreen,
                                  ),
                                  _buildToggleRow(
                                    label: 'Heart Disease',
                                    icon: Icons.favorite_border_rounded,
                                    value: _controller.hasHeartDisease,
                                    iconColor: const Color(0xFFE24B4A),
                                  ),
                                  _buildToggleRow(
                                    label: 'Asthma',
                                    icon: Icons.air_outlined,
                                    value: _controller.hasAsthma,
                                    iconColor: const Color(0xFF185FA5),
                                  ),

                                  // ════════════════════════════════
                                  // SECTION 4 — Emergency Contact
                                  // ════════════════════════════════
                                  _sectionLabel(
                                    'EMERGENCY CONTACT',
                                    Icons.emergency_outlined,
                                  ),

                                  _buildField(
                                    controller: _emergencyNameController,
                                    label: 'Contact Person Name',
                                    icon: Icons.person_pin_outlined,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildField(
                                    controller: _emergencyPhoneController,
                                    label: 'Contact Phone',
                                    icon: Icons.phone_callback_outlined,
                                    keyboardType: TextInputType.phone,
                                  ),

                                  const SizedBox(height: 24),

                                  // ── Register Button ──
                                  Obx(
                                    () => SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _controller.isLoading.value
                                            ? null
                                            : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryGreen,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: const Color(
                                            0xFF8FB4C9,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: _controller.isLoading.value
                                            ? const SizedBox(
                                                height: 22,
                                                width: 22,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor:
                                                      AlwaysStoppedAnimation(
                                                        Colors.white,
                                                      ),
                                                ),
                                              )
                                            : const Text(
                                                'Create Account',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.3,
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
                      ),

                      // ── Already have account ──
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6FA0B0),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: darkTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: darkTeal, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF8FB4C9), fontSize: 13),
        prefixIcon: Icon(icon, color: primaryGreen, size: 20),
        filled: true,
        fillColor: fieldBg,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primaryGreen, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}