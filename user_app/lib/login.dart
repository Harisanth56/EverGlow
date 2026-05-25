import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/main.dart';
import 'package:user_app/navigator.dart';
import 'package:user_app/user_homepage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {

  bool rememberMe = false;
  bool isPasswordVisible = false;

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  /// LOGIN FUNCTION
  Future<void> loginUser() async {
    try {
      final authResponse = await supabase.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = authResponse.user;

      if (user == null) {
        throw Exception("Login failed");
      }

      /// CHECK USER STATUS
      final response = await supabase
          .from('tbl_user')
          .select('user_status')
          .eq('user_id', user.id)
          .single();

      String? status = response['user_status'];

      if (status == "rejected") {
        /// BLOCKED
        await supabase.auth.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Your account has been blocked by admin"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } else if (status == "approved") {
        /// ALLOW LOGIN (Active or Pending but not blocked)
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) =>  IndexPage()),
          );
        }
      } else if (status == 'pending') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your account is pending for admin approval"),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E14), // Deep Midnight Base
        body: SafeArea(
          child: Column(
            children: [
              /// HEADER / BACK BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF8E71FF), // Indigo Accent
                        size: 22,
                      ),
                    ),
                    const Text(
                      'Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 30),
                      const Text(
                        'Welcome Back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Please sign in to continue',
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      /// FORM FIELDS
                      Form(
                        child: Column(
                          children: [
                            _buildGlassInput(
                              label: 'Email or Username',
                              controller: emailController,
                              hint: 'Enter your email',
                              icon: Icons.mail_outline,
                              type: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),
                            _buildGlassInput(
                              label: 'Password',
                              controller: passwordController,
                              hint: 'Enter your password',
                              icon: Icons.lock_outline,
                              isPassword: true,
                              isVisible: isPasswordVisible,
                              onToggleVisibility: () {
                                setState(() {
                                  isPasswordVisible = !isPasswordVisible;
                                });
                              },
                            ),

                            /// REMEMBER ME & FORGOT PASSWORD
                            Row(
                              children: [
                                SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: Checkbox(
                                    value: rememberMe,
                                    onChanged: (val) => setState(() => rememberMe = val!),
                                    activeColor: const Color(0xFF8E71FF),
                                    side: const BorderSide(color: Colors.white24),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Remember', style: TextStyle(color: Colors.white70)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () {},
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(color: Color(0xFF8E71FF)),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            /// SIGN IN BUTTON (Indigo Gradient)
                            GestureDetector(
                              onTap: () {
                                loginUser();
                              },
                              child: Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF6B4EE6).withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            /// DIVIDER
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 15),
                                  child: Text('Or Login with', style: TextStyle(color: Colors.white24, fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                              ],
                            ),

                            const SizedBox(height: 30),

                            /// SOCIAL BUTTONS
                            Row(
                              children: [
                                _socialButton('assets/goog.png'),
                                const SizedBox(width: 15),
                                _socialButton('assets/f.png'),
                                const SizedBox(width: 15),
                                _socialButton('assets/apple.png'),
                              ],
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Glassmorphic Input Builder
  Widget _buildGlassInput({
    required String label,
    required TextEditingController controller,
    
    
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onToggleVisibility,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("  $label", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          obscureText: isPassword && !isVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF8E71FF), size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white24),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.1), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF8E71FF)),
            ),
          ),
        ),
      ],
    );
  }

  /// Themed Social Button
  Widget _socialButton(String asset) {
    return Expanded(
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 41, 41, 41),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Center(
          child: Image.asset(asset, height: 24),
        ),
      ),
    );
  }
}