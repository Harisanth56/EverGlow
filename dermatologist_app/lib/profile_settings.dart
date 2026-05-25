import 'package:dermatologist_app/change_password.dart';
import 'package:dermatologist_app/complaint.dart';
import 'package:dermatologist_app/edit_profile.dart';
import 'package:dermatologist_app/main.dart';
import 'package:dermatologist_app/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure this is in pubspec.yaml

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  String name = "";
  String email = "";
  String address = "";
  String? photo;
  String gender = "";
  String contact = "";
  String specialization = "";
  String experience = "";
  String? proofLink; // New variable to store the database link

  @override
  void initState() {
    super.initState();
    fetchderma();
  }

  Future<void> fetchderma() async {
    try {
      final dermatologist = supabase.auth.currentUser;
      if (dermatologist == null) return;

      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_id', dermatologist.id)
          .single();

      if (mounted) {
        setState(() {
          name = response['dermatologist_name'] ?? "Dermatologist";
          email = response['dermatologist_email'] ?? "No Email";
          specialization =
              response['dermatologist_specialization'] ?? "No Specialization";
          experience =
              response['dermatologist_experience']?.toString() ??
              "No Experience";
          photo = response['dermatologist_photo'];
          contact = response['dermatologist_contact'] ?? "No Contact";
          address = response['dermatologist_address'] ?? "No Location";
          // Fetch the proof link from the database column
          proofLink = response['dermatologist_proof'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  // Function to handle the swipe to refresh
  Future<void> _handleRefresh() async {
    await fetchderma();
  }

  // Function to open the link
  Future<void> _openProof() async {
    if (proofLink != null && proofLink!.isNotEmpty) {
      final Uri url = Uri.parse(proofLink!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        debugPrint("Could not launch $proofLink");
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No proof document available")),
        );
      }
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
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              /// FIXED HEADER
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 5,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 40),
                          const Text(
                            'Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Replace IconButton with PopupMenuButton
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: PopupMenuButton<String>(
                        color: const Color(0xFF161B22),
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'support') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Complaint(),
                              ),
                            );
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            PopupMenuItem<String>(
                              value: 'support',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    color: Color.fromARGB(137, 255, 255, 255),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Support',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                ),
              ),

              /// SCROLLABLE CONTENT AREA
              Expanded(
                child: RefreshIndicator(
                  color: Colors.blueAccent,
                  backgroundColor: const Color(0xFF1E1E1E),
                  onRefresh: _handleRefresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        /// PROFILE IMAGE SECTION
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.blueAccent.withOpacity(0.5),
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 70,
                                  backgroundColor: const Color(0xFF161B22),
                                  backgroundImage:
                                      (photo != null && photo!.isNotEmpty)
                                      ? NetworkImage(photo!)
                                      : null,
                                  child: (photo == null || photo!.isEmpty)
                                      ? const Icon(
                                          Icons.person,
                                          size: 70,
                                          color: Colors.white24,
                                        )
                                      : null,
                                ),
                              ),
                              const CircleAvatar(
                                backgroundColor: Colors.blueAccent,
                                radius: 20,
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// INFO CARD (Now includes the 7th Proof column)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              children: [
                                _buildInfoRow(
                                  Icons.person_outline,
                                  'Name',
                                  name,
                                ),
                                const Divider(
                                  color: Colors.white10,
                                  height: 30,
                                ),
                                _buildInfoRow(
                                  Icons.medication_outlined,
                                  'Specialization',
                                  specialization,
                                ),
                                const Divider(
                                  color: Colors.white10,
                                  height: 30,
                                ),
                                _buildInfoRow(
                                  Icons.history_edu_outlined,
                                  'Experience',
                                  experience,
                                ),
                                const Divider(
                                  color: Colors.white10,
                                  height: 30,
                                ),
                                _buildInfoRow(
                                  Icons.email_outlined,
                                  'Email',
                                  email,
                                ),
                                const Divider(
                                  color: Colors.white10,
                                  height: 30,
                                ),
                                _buildInfoRow(
                                  Icons.phone_outlined,
                                  'Contact',
                                  contact,
                                ),
                                const Divider(
                                  color: Colors.white10,
                                  height: 30,
                                ),
                                _buildInfoRow(
                                  Icons.location_on_outlined,
                                  'Location',
                                  address,
                                ),

                                // NEW COLUMN: PROOF (Clickable link)
                                const Divider(
                                  color: Colors.white10,
                                  height: 30,
                                ),
                                GestureDetector(
                                  onTap: _openProof,
                                  child: _buildInfoRow(
                                    Icons.verified_user_outlined,
                                    'Proof Document',
                                    (proofLink != null)
                                        ? "Click to View Proof"
                                        : "No Document Provided",
                                    isLink: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        /// ACTIONS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              _buildActionButton(
                                context,
                                'Edit Profile',
                                Icons.edit,
                                const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const EditProfile(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildActionButton(
                                context,
                                'Reset Password',
                                Icons.lock_reset,
                                const [Color(0xFF667eea), Color(0xFF764ba2)],
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChangePass(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildActionButton(
                                context,
                                'Logout',
                                Icons.logout,
                                const [Color(0xFFff0844), Color(0xFFffb199)],
                                () async {
                                  // Show a loading indicator while logging out
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.blueAccent,
                                      ),
                                    ),
                                  );

                                  try {
                                    // 1. Sign out from Supabase
                                    await supabase.auth.signOut();

                                    if (context.mounted) {
                                      // 2. Clear the loading dialog
                                      Navigator.pop(context);

                                      // 3. Navigate to Login page and clear navigation history
                                      // Replace 'LoginScreen()' with whatever your actual login widget class is named.
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Welcome(),
                                        ),
                                        (route) =>
                                            false, // This removes all previous routes from the stack
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.pop(
                                        context,
                                      ); // Close loading indicator
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text("Logout failed: $e"),
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
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

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isLink = false,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                value.isEmpty ? 'Not Provided' : value,
                style: TextStyle(
                  color: isLink ? Colors.blueAccent : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  decoration: isLink
                      ? TextDecoration.underline
                      : TextDecoration.none,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (isLink)
          const Icon(Icons.open_in_new, color: Colors.blueAccent, size: 18),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    List<Color> colors,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
