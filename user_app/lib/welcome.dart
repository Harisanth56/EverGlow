import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/login.dart';
import 'package:user_app/registration.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E14), // Deep Midnight Base
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 80),
                
                /// ICON / LOGO PLACEHOLDER
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF8E71FF).withOpacity(0.2)),
                  ),
                  child: const Icon(
                    Icons.auto_awesome, 
                    color: Color(0xFF8E71FF), 
                    size: 50,
                  ),
                ),

                const SizedBox(height: 40),

                /// WELCOME TEXT
                const Text(
                  'Welcome to UV Sense',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  "Smart skin protection and specialist\nconsultation at your fingertips.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                /// PRIMARY ACTION: LOG IN
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)],
                      ),
                      
                    ),
                    child: const Center(
                      child: Text(
                        'Log In',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// SECONDARY ACTION: CREATE ACCOUNT
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const Registration()));
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 16,
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