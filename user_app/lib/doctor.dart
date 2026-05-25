import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/book_appointment.dart';

class ProfileDr extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const ProfileDr({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    // Data Extraction
    final String name = doctor['dermatologist_name'] ?? 'Doctor';
    final String specialty =
        doctor['dermatologist_specialization'] ?? 'General Dermatologist';
    final String experience = doctor['dermatologist_experience'] ?? '0';
    final String email = doctor['dermatologist_email'] ?? 'Contact via app';
    final String? photoUrl = doctor['dermatologist_photo'];

    

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF161B22),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF8E71FF),
                size: 18,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 100), // Spacing for custom app bar
            /// HERO SECTION: Image & Name
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E71FF).withOpacity(0.3),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 75,
                      backgroundColor: const Color(0xFF0A0E14),
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.white24,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    specialty,
                    style: const TextStyle(
                      color: Color(0xFF8E71FF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// CONTENT SECTION
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// INFO BADGES (Experience & Patients)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoBadge(
                        Icons.history_toggle_off,
                        "Experience",
                        "$experience Years",
                      ),
                      _buildInfoBadge(
                        Icons.verified_user_outlined,
                        "Status",
                        "Verified",
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  const Text(
                    "Professional Bio",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Dr. $name is a highly skilled $specialty dedicated to providing the best skin health care. Available for consultations via $email.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 35),

                  /// ACTION BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: _buildSecondaryAction(
                          Icons.email_outlined,
                          "Message",
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _buildSecondaryAction(
                          Icons.share_outlined,
                          "Share",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  /// BOOKING BUTTON
                  GestureDetector(
                    // Inside ProfileDr's GestureDetector onTap:
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BookAppointment(doctor: doctor),
                        ),
                      );
                    },
                    child: Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6B4EE6).withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Book Appointment',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: const Color(0xFF8E71FF), size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryAction(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
