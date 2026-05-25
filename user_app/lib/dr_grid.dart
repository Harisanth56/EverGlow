import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/main.dart';
import 'package:user_app/doctor.dart';
import 'package:user_app/navigator.dart';

class DoctorGridScreen extends StatefulWidget {
  const DoctorGridScreen({super.key});

  @override
  State<DoctorGridScreen> createState() => _DoctorGridScreenState();
}

class _DoctorGridScreenState extends State<DoctorGridScreen> {
  List<Map<String, dynamic>> dermatologistList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }

  Future<void> fetchDoctors() async {
    try {
      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_status', 'approved');

      if (mounted) {
        setState(() {
          dermatologistList = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("ERROR: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: SafeArea(
        child: Column(
          children: [
            /// PREMIUM TOP NAV
            _buildPremiumHeader(),

            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8E71FF),
                      ),
                    )
                  : dermatologistList.isEmpty
                  ? const Center(
                      child: Text(
                        "No specialists available",
                        style: TextStyle(color: Colors.white24),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      physics: const BouncingScrollPhysics(),
                      itemCount: dermatologistList.length,
                      itemBuilder: (context, index) {
                        return _buildDoctorListCard(
                          context,
                          dermatologistList[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IndexPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            "Find your\nSpecialist",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(15),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search doctor...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8E71FF)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorListCard(
    BuildContext context,
    Map<String, dynamic> doctor,
  ) {
    final String name = doctor['dermatologist_name'] ?? 'Doctor';
    final String specialty =
        doctor['dermatologist_specialization'] ?? 'Dermatology';
    final String exp = doctor['dermatologist_experience'] ?? '0';
    final String? photoUrl = doctor['dermatologist_photo'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProfileDr(doctor: doctor)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Stack(
          children: [
            // Decorative background icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                Icons.medical_services_outlined,
                size: 80,
                color: Colors.white.withOpacity(0.02),
              ),
            ),
            Row(
              children: [
                /// Left: Doctor Photo
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    image: photoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(photoUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: const Color(0xFF0A0E14),
                  ),
                  child: photoUrl == null
                      ? const Icon(
                          Icons.person,
                          color: Colors.white12,
                          size: 40,
                        )
                      : null,
                ),

                /// Right: Doctor Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          specialty,
                          style: TextStyle(
                            color: const Color(0xFF8E71FF).withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              "4.9",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Icon(
                              Icons.work_outline,
                              color: Colors.white38,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "$exp Yrs Exp",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                /// Far Right: Action
                const Padding(
                  padding: EdgeInsets.only(right: 15),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white24,
                    size: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
