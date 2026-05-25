import 'package:dermatologist_app/homepage.dart';
import 'package:dermatologist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  Future<void> loginDerma() async {
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
          .from('tbl_dermatologist')
          .select('dermatologist_status')
          .eq('dermatologist_id', user.id)
          .single();

      String? status = response['dermatologist_status'];

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
            MaterialPageRoute(builder: (context) => const HomeScreen()),
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
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black, // Midnight Base
        body: SafeArea(
          child: Column(
            children: [
              /// TOP SECTION (Logo/Space)
              const SizedBox(height: 60),
              const Icon(
                Icons.lock_outline_rounded,
                size: 80,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 40),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E), // Midnight Grey Container
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),

                        /// HEADER Row with Back Button
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        /// LOGIN FORM
                        Form(
                          child: Column(
                            children: [
                              _buildMidnightField(
                                label: 'Email or Username',
                                icon: Icons.mail_outline,
                                controller: emailController,
                                type: TextInputType.emailAddress,
                                
                              ),
                              const SizedBox(height: 20),
                              _buildMidnightField(
                                label: 'Password',
                                controller: passwordController,
                                icon: Icons.lock_outline,
                                isPassword: true,
                              ),

                              const SizedBox(height: 10),

                              /// REMEMBER & FORGOT
                              Row(
                                children: [
                                  Transform.scale(
                                    scale: 0.9,
                                    child: Checkbox(
                                      value: rememberMe,
                                      onChanged: (val) =>
                                          setState(() => rememberMe = val!),
                                      activeColor: Colors.blueAccent,
                                      checkColor: Colors.white,
                                      side: const BorderSide(
                                        color: Colors.white30,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    'Remember',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const Spacer(),
                                  TextButton(
                                    onPressed: () {},
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              /// GET STARTED BUTTON (Gradient)
                              GestureDetector(
                                onTap: () {
                                  loginDerma();
                                },
                                child: Container(
                                  width: double.infinity,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF4facfe),
                                        Color(0xFF00f2fe),
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blueAccent.withOpacity(
                                          0.3,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'Login',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 30),

                              /// SOCIAL DIVIDER
                              const Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: Colors.white10),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15,
                                    ),
                                    child: Text(
                                      'Or Login with',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(color: Colors.white10),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              /// SOCIAL BUTTONS
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildSocialTile(
                                    'assets/goog.png',
                                    onTap: () {},
                                  ),
                                  _buildSocialTile(
                                    'assets/f.png',
                                    onTap: () {},
                                  ),
                                  _buildSocialTile(
                                    'assets/apple.png',
                                    onTap: () {},
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialTile(String asset, {required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 60,
          width: 75, // Slightly wider for a modern "tile" look
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 66, 66, 66), // Midnight Grey
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10), // Subtle theme border
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.9),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Image.asset(
              asset,
              height: 30,
              // color: Colors.white, // Removed as requested to keep original colors
            ),
          ),
        ),
      ),
    );
  }

  /// Midnight Field Builder
  Widget _buildMidnightField({
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword ? !isPasswordVisible : false,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => isPasswordVisible = !isPasswordVisible),
              )
            : null,
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.blueAccent),
        ),
      ),
    );
  }
}
