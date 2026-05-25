import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Registration extends StatelessWidget {
  const Registration({super.key});

  @override
  Widget build(BuildContext context) {
    // Theme Constants
    const Color bgColor = Color(0xFF0D0D0D);
    const Color cardColor = Color(0xFF1A1A1A);
    const Color accentColor = Color(0xFFE94E1B);
    

    final TextEditingController emailController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    Future<void> insert() async {
      try {
        final email = emailController.text.trim();
        final name = nameController.text.trim();
        final password = passwordController.text;

        if (email.isEmpty || name.isEmpty || password.isEmpty) return;

        await supabase.from('tbl_admin').insert({
          'admin_email': email,
          'admin_name': name,
          'admin_password': password
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Completed"), backgroundColor: accentColor),
        );
        
        emailController.clear();
        nameController.clear();
        passwordController.clear();
      } catch (e) {
        debugPrint("Error $e");
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/Header Section
                  const Text(
                    "JosKart Admin",
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Create your administrative account",
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                  const SizedBox(height: 40),

                  // Main Form Card
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      children: [
                        _buildDarkField(nameController, "Full Name", Icons.person_outline),
                        const SizedBox(height: 20),
                        _buildDarkField(emailController, "Email Address", Icons.mail_outline),
                        const SizedBox(height: 20),
                        _buildDarkField(passwordController, "Password", Icons.lock_outline, isPassword: true),
                        const SizedBox(height: 40),
                        
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: insert,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text(
                              "CREATE ACCOUNT",
                              style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold, letterSpacing: 1.2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account? Log In",
                      style: TextStyle(color: Colors.white38),
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

  Widget _buildDarkField(TextEditingController controller, String label, IconData icon, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF0D0D0D),
            prefixIcon: Icon(icon, color: const Color(0xFFE94E1B), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE94E1B), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}