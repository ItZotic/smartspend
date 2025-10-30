import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

import 'package:smartspend/services/auth_service.dart';

import 'forgot_password.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = usernameController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill in all fields');
      return;
    }

    if (password.length < 8) {
      _showSnackBar('Password must be at least 8 characters long');
      return;
    }

    try {
      await _authService.login(email, password);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main_menu');
    } on AuthException catch (e) {
      _showSnackBar(e.message);
    } catch (e) {
      _showSnackBar('Failed to login. Please try again later.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B65EC),
      body: SafeArea(
        child: Column(
          children: [
            // 🔵 Header
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Column(
                children: const [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white,
                    size: 80,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'SMARTSPEND',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ⚪ White rounded card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login to your account',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // 🧍 Username field
                      TextField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔒 Password field
                      TextField(
                        controller: passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ✅ Remember me + Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                              ),
                              const Text('Remember me'),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 🚪 Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2B65EC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ➖ Divider
                      Row(
                        children: const [
                          Expanded(child: Divider(thickness: 1)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text('or sign in with'),
                          ),
                          Expanded(child: Divider(thickness: 1)),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 🌐 Social Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSocialButton(
                            backgroundColor: Colors.white,
                            icon: FontAwesomeIcons.google,
                            iconColor: Colors.black87,
                            onTap: () => _showSnackBar('Sign in with Google'),
                          ),
                          const SizedBox(width: 20),
                          _buildSocialButton(
                            backgroundColor: const Color(0xFF1877F2),
                            icon: FontAwesomeIcons.facebookF,
                            iconColor: Colors.white,
                            onTap: () => _showSnackBar('Sign in with Facebook'),
                          ),
                          const SizedBox(width: 20),
                          _buildSocialButton(
                            backgroundColor: Colors.black,
                            icon: FontAwesomeIcons.apple,
                            iconColor: Colors.white,
                            onTap: () => _showSnackBar('Sign in with Apple'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 🆕 Sign Up Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2B65EC),
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
          ],
        ),
      ),
    );
  }

  // 🎨 Helper: Social button widget
Widget _buildSocialButton({
  required Color backgroundColor,
  required IconData icon,
  required Color iconColor,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 55,
      width: 55,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: FaIcon(icon, color: iconColor, size: 26),
      ),
    ),
  );
}
}