import 'package:dermatologist_app/login.dart';
import 'package:dermatologist_app/register.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.black, // Solid Midnight Theme Base
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 80),

                /// TOP ICON / LOGO PLACEHOLDER
                const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.blueAccent,
                  size: 80,
                ),

                const SizedBox(height: 40),

                /// HEADER
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '=)',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 30),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                /// SUBTEXT
                const Text(
                  'Hi there!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "We're here to help you",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const Text(
                  'Login or create an account.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const Spacer(),

                /// ACTION BUTTONS
                // Create Account Button (Outline Style)
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: // Corrected Button Style
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Registration()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      // Use styleFrom, not styleSide
                      side: const BorderSide(
                        color: Colors.white24,
                      ), // Define the border here
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Log In Button (Solid Gradient Style)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
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
                        ], // Theme Blue Gradient
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Log in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
