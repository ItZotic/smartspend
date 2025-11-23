import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:smartspend/services/theme_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _themeService = ThemeService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  void _showSnackBar(String message, {Color color = Colors.red}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      // Firebase Authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      // Navigate to main menu on success
      Navigator.pushReplacementNamed(context, '/main_menu');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Login failed';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'invalid-credential':
          errorMessage = 'Invalid email or password';
          break;
        default:
          errorMessage = 'Login failed: ${e.message}';
      }
      
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        final isDark = _themeService.isDarkMode;
        
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                            color: isDark ? Colors.white70 : Colors.grey.shade700,
                          ),
                          onPressed: _toggleTheme,
                          tooltip: _themeService.currentThemeString,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Logo
                      Image.asset(
                        'assets/images/logo.png',
                        height: 110,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 110,
                            width: 110,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A73E8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              size: 60,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      Text(
                        "SmartSpend",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1A73E8),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Email",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFF1A73E8),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _login(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: "Password",
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade400,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Color(0xFF1A73E8),
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(color: Colors.red, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Login button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black,
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.pushNamed(context, '/register');
                                  },
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                color: Color(0xFF1A73E8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}