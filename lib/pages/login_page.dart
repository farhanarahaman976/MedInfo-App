import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/user.dart';
import '../services/firebase_user_service.dart';
import '../services/reminder_service.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

// ─── AuthController ────────────────────────────────────────────────────────────

class AuthController extends GetxController {
  final FirebaseUserService _service = FirebaseUserService();
  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final Rx<User?> currentUser = Rx<User?>(null);

  Future<void> login({
    required String email,
    required String password,
    required void Function(User user) onSuccess,
  }) async {
    isLoading.value = true;
    try {
      final user = await _service.loginUser(email: email, password: password);
      currentUser.value = user;
      onSuccess(user);
      await ReminderService().rescheduleAllOnLogin();

      Get.snackbar(
        'Welcome!',
        'Hello, ${user.name.isNotEmpty ? user.name : email}',
        backgroundColor: const Color(0xFFEAF3F7),
        colorText: const Color(0xFF0F6E56),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 2),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No account found with this email. Please register first.';
          break;
        case 'wrong-password':
          message = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'network-request-failed':
          message = 'Network error. Please check your internet connection.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password. Please try again.';
          break;
        default:
          message = 'Login failed. Please try again.';
      }
      Get.snackbar(
        'Login Failed',
        message,
        backgroundColor: const Color(0xFFFCEBEB),
        colorText: const Color(0xFFA32D2D),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Something went wrong. Please try again.',
        backgroundColor: const Color(0xFFFCEBEB),
        colorText: const Color(0xFFA32D2D),
        snackPosition: SnackPosition.TOP,
        borderRadius: 12,
        margin: const EdgeInsets.all(12),
      );
    } finally {
      isLoading.value = false;
    }
  }
}

// ─── LoginPage ──────────────────────────────────────────────────────────────────

class LoginPage extends StatelessWidget {
  final ValueChanged<User> onLogin;

  const LoginPage({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    final AuthController controller = Get.put(AuthController());
    final formKey = GlobalKey<FormState>();
    String email = '';
    String password = '';

    const Color primaryGreen = Color(0xFF3B82C4);
    const Color darkTeal = Color(0xFF0F6E56);
    const Color lightBg = Color(0xFFEAF3F7);
    const Color fieldBg = Color(0xFFF2F8FA);
    const Color borderColor = Color(0xFFC7DEE8);

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
                      // Top section with logo
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: lightBg,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(48),
                            bottomRight: Radius.circular(48),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
                        child: Column(
                          children: [
                            // Logo box
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

                      // Form Card
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                              key: formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Welcome back 👋',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: darkTeal,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Login with your email & password',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6FA0B0),
                                    ),
                                  ),
                                  const SizedBox(height: 22),

                                  // Email
                                  TextFormField(
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      color: darkTeal,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Email Address',
                                      labelStyle: const TextStyle(
                                        color: Color(0xFF8FB4C9),
                                        fontSize: 13,
                                      ),
                                      prefixIcon: const Icon(
                                        Icons.mail_outline_rounded,
                                        color: primaryGreen,
                                        size: 20,
                                      ),
                                      filled: true,
                                      fillColor: fieldBg,
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: borderColor,
                                          width: 1,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: primaryGreen,
                                          width: 1.5,
                                        ),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE24B4A),
                                          width: 1,
                                        ),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE24B4A),
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                    onSaved: (v) => email = v?.trim() ?? '',
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
                                  const SizedBox(height: 14),

                                  // Password
                                  Obx(
                                    () => TextFormField(
                                      obscureText:
                                          controller.obscurePassword.value,
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
                                            controller.obscurePassword.value
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            color: const Color(0xFF8FB4C9),
                                            size: 20,
                                          ),
                                          onPressed: () => controller
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
                                      onSaved: (v) => password = v ?? '',
                                      validator: (v) {
                                        if (v == null || v.isEmpty) {
                                          return 'Please enter your password';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordPage(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: primaryGreen,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Login button
                                  Obx(
                                    () => SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: controller.isLoading.value
                                            ? null
                                            : () {
                                                if (!(formKey.currentState
                                                        ?.validate() ??
                                                    false)) {
                                                  return;
                                                }
                                                formKey.currentState?.save();
                                                controller.login(
                                                  email: email,
                                                  password: password,
                                                  onSuccess: (user) =>
                                                      onLogin(user),
                                                );
                                              },
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
                                        child: controller.isLoading.value
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
                                                'Login',
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

                      // Sign Up link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6FA0B0),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        RegisterPage(onRegister: onLogin),
                                  ),
                                );
                              },
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F6E56),
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
}