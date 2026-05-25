import 'package:admin_app/login.dart';
import 'package:admin_app/registration.dart';
import 'package:flutter/material.dart';

class Welcome extends StatelessWidget {
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset('assets/caat_bg.png', fit: BoxFit.cover),
            ),
            Center(
              child: Column(
                children: [
                  SizedBox(height: 70),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome ',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text('=)', style: TextStyle(fontSize: 30)),
                    ],
                  ),
                  SizedBox(height: 50),
                  Text(
                    'Admin, Hi there!',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Text(
                    "We're here to help you",
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Text(
                    'Login or create an account.',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Registration(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                        child: Text(
                          'Create Account',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        gradient: LinearGradient(
                          begin: AlignmentGeometry.centerLeft,
                          end: AlignmentGeometry.centerRight,
                          colors: [
                            const Color.fromARGB(255, 255, 203, 125),
                            const Color.fromARGB(255, 236, 132, 255),
                          ],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Login()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                        ),
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
