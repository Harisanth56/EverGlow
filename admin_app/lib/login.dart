import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool isPasswordVisible = false;

  // JosKart Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);
  static const Color fieldColor = Color(0xFF0D0D0D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center( // Center the login box for web view
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450), // Standard login width
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/Header Section
                  const Text(
                    "JosKart Admin",
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Welcome back, please login to your account",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 40),

                  // Main Login Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildDarkField(
                          controller: emailController,
                          label: "EMAIL ADDRESS",
                          icon: Icons.mail_outline,
                        ),
                        const SizedBox(height: 24),
                        _buildDarkField(
                          controller: passwordController,
                          label: "PASSWORD",
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),

                        // Remember & Forgot Password
                        Row(
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: rememberMe,
                                onChanged: (val) => setState(() => rememberMe = val!),
                                activeColor: accentColor,
                                side: const BorderSide(color: Colors.white24),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text("Remember", style: TextStyle(color: Colors.white54, fontSize: 13)),
                            const Spacer(),
                            TextButton(
                              onPressed: () {},
                              child: const Text("Forgot?", style: TextStyle(color: accentColor, fontSize: 13)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              // Your Login Logic here
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text(
                              "SIGN IN",
                              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  // Navigation back or registration
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_back, size: 16, color: Colors.white.withOpacity(0.3)),
                        const SizedBox(width: 8),
                        Text("Back to main", style: TextStyle(color: Colors.white.withOpacity(0.3))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDarkField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !isPasswordVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: fieldColor,
            prefixIcon: Icon(icon, color: accentColor.withOpacity(0.8), size: 20),
            suffixIcon: isPassword 
              ? IconButton(
                  icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white24, size: 20),
                  onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                )
              : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: accentColor, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}