import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'package:smartspend/services/theme_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthService _authService = AuthService();
  final _themeService = ThemeService();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _toggleTheme() {
    if (_themeService.themeMode == ThemeMode.system) {
      _themeService.setThemeMode('Light');
    } else if (_themeService.themeMode == ThemeMode.light) {
      _themeService.setThemeMode('Dark');
    } else {
      _themeService.setThemeMode('System default');
    }
  }

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.register(email, password);
      if (!mounted) return;
      _showSnackBar('Registration successful!', color: Colors.green);
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      _showSnackBar('Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        final bool dark = _themeService.isDarkMode;

        final Color primaryBlue = const Color(0xFF2A85FF);
        final Color background = dark ? const Color(0xFF0B1220) : Colors.white;
        final Color fieldFill = dark ? const Color(0xFF0F1B2B) : const Color(0xFFF2F2F2);
        final Color fieldBorder = dark ? Colors.white24 : Colors.black26;
        final Color textColor = dark ? Colors.white : Colors.black87;
        final Color hintColor = dark ? Colors.white60 : Colors.black45;
        final Color shadowColor = dark ? Colors.black45 : Colors.black26;

        InputDecoration fieldDecoration({
          required String label,
          required IconData icon,
          Widget? suffix,
        }) {
          return InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: hintColor),
            prefixIcon: Icon(icon, color: hintColor),
            suffixIcon: suffix,
            filled: true,
            fillColor: fieldFill,
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: fieldBorder, width: 1.1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryBlue, width: 1.6),
            ),
          );
        }

        return Scaffold(
          backgroundColor: background,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Theme toggle button
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          _themeService.themeMode == ThemeMode.system
                              ? Icons.brightness_auto
                              : _themeService.themeMode == ThemeMode.light
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                          color: dark ? Colors.white70 : Colors.grey.shade700,
                        ),
                        onPressed: _toggleTheme,
                        tooltip: _themeService.currentThemeString,
                      ),
                    ),

                    // Icon + Title
                    const SizedBox(height: 8),
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: primaryBlue,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 44),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SmartSpend',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryBlue),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Create Account',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
                    ),
                    const SizedBox(height: 28),

                    // Form Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                      decoration: BoxDecoration(
                        color: dark ? const Color(0xFF071022) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: dark
                            ? []
                            : [
                                BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4))
                              ],
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: emailController,
                            style: TextStyle(color: textColor),
                            decoration: fieldDecoration(label: 'Email', icon: Icons.email_outlined),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            style: TextStyle(color: textColor),
                            decoration: fieldDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: hintColor),
                                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: !_isConfirmPasswordVisible,
                            style: TextStyle(color: textColor),
                            decoration: fieldDecoration(
                              label: 'Confirm Password',
                              icon: Icons.lock_reset,
                              suffix: IconButton(
                                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: hintColor),
                                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: shadowColor, blurRadius: 8, offset: const Offset(0, 4))
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                                    : const Text('Sign Up', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ', style: TextStyle(color: hintColor)),
                              GestureDetector(
                                onTap: () => Navigator.pushReplacementNamed(context, '/'),
                                child: Text('Login', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}