import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/changepassword.dart';
import 'package:user_app/complaint.dart';
import 'package:user_app/editprofile.dart';
import 'package:user_app/main.dart';
import 'package:user_app/myorder.dart';
import 'package:user_app/welcome.dart';

class MyProfile extends StatefulWidget {
  const MyProfile({super.key});

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  String name = "";
  String email = "";
  String skin = "";
  String address = "";
  String? photo;
  String gender = "";
  String contact = "";

  // Tracks database fetching lifecycle state to prevent text pop-in or null flashing
  bool _isInitialLoading = true;

  Future<void> _onRefresh() async {
    await Future.wait([fetchuser()]);
  }

  Future<void> _handleLogout() async {
    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Welcome()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("Error signing out: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to logout. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> fetchuser() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_user')
          .select('''
            *,
            tbl_type (
              type_name
            )
          ''')
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          name = response['user_name'] ?? "User";
          email = response['user_email'] ?? "No Email";
          address = response['user_address'] ?? "No Address";
          photo = response['user_photo'];
          gender = response['user_gender'] ?? "Not provided";
          contact = response['user_contact'] ?? "No Contact";

          final typeData = response['tbl_type'];
          if (typeData != null) {
            skin = typeData['type_name'] ?? "Unknown";
          } else {
            skin = "Not set";
          }

          // Data is loaded, stop showing the central loader animation
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    fetchuser();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E14),
        body: SafeArea(
          child: _isInitialLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8E71FF)),
                )
              : Column(
                  children: [
                    const SizedBox(height: 20),

                    /// FIXED HEADER (Stays put)
                    Row(
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
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: PopupMenuButton<String>(
                            color: const Color(0xFF161B22),
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white,
                            ),
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
                                const PopupMenuItem<String>(
                                  value: 'support',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.help_outline,
                                        color: Color.fromARGB(
                                          137,
                                          255,
                                          255,
                                          255,
                                        ),
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

                    Expanded(
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          CupertinoTheme(
                            data: const CupertinoThemeData(
                              primaryColor: Color(0xFF8E71FF),
                            ),
                            child: CupertinoSliverRefreshControl(
                              onRefresh: _onRefresh,
                              refreshIndicatorExtent: 60,
                              refreshTriggerPullDistance: 100,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                const SizedBox(height: 20),

                                /// PROFILE PICTURE SECTION
                                Center(
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF8E71FF),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF8E71FF,
                                              ).withOpacity(0.2),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 70,
                                          backgroundColor: const Color(
                                            0xFF161B22,
                                          ),
                                          backgroundImage:
                                              (photo != null &&
                                                  photo!.isNotEmpty)
                                              ? NetworkImage(photo!)
                                              : null,
                                          child:
                                              (photo == null || photo!.isEmpty)
                                              ? const Icon(
                                                  Icons.person,
                                                  size: 70,
                                                  color: Colors.white24,
                                                )
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF8E71FF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 30),

                                /// INFORMATION CARD
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF161B22),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        _buildProfileTile(
                                          Icons.person_outline,
                                          'Name',
                                          name,
                                        ),
                                        _buildProfileTile(
                                          Icons.mail_outline,
                                          'Email',
                                          email,
                                        ),
                                        _buildProfileTile(
                                          Icons.phone_android,
                                          'Contact',
                                          contact,
                                        ),
                                        _buildProfileTile(
                                          Icons.opacity,
                                          'Skin type',
                                          skin,
                                        ),
                                        _buildProfileTile(
                                          _getGenderIcon(gender),
                                          'Gender',
                                          gender,
                                        ),
                                        _buildProfileTile(
                                          Icons.location_on_outlined,
                                          'Place',
                                          address,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 30),

                                /// ACTION BUTTONS
                                /// ACTION BUTTONS
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    children: [
                                      // 1. My Orders (Now prominently placed at the top)
                                      _buildMenuButton(
                                        label: 'My Orders',
                                        icon: Icons.shopping_bag,
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const MyOrdersScreen(),
                                          ),
                                        ),
                                        isPrimary:
                                            true, // Swapped to primary gradient styling for emphasis
                                      ),
                                      const SizedBox(height: 15),

                                      // 2. Edit Profile & Reset Password (Side-by-side layout configuration)
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildCompactMenuButton(
                                              label: 'Edit Profile',
                                              icon: Icons.edit_note_rounded,
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const EditProfile(),
                                                ),
                                              ).then((_) => fetchuser()),
                                            ),
                                          ),
                                          const SizedBox(width: 15),
                                          Expanded(
                                            child: _buildCompactMenuButton(
                                              label: 'Reset Password',
                                              icon: Icons.lock_reset_rounded,
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const ChangePass(),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),

                                      // 3. Logout Button (Custom red glow accent style)
                                      _buildLogoutButton(
                                        label: 'Logout',
                                        icon: Icons.logout_rounded,
                                        onTap: _handleLogout,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8E71FF), size: 22),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
              Text(
                value.isNotEmpty ? value : "Not provided",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getGenderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
        return Icons.male;
      case 'female':
        return Icons.female;
      default:
        return Icons.person_outline;
    }
  }

  Widget _buildMenuButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)],
                )
              : null,
          color: isPrimary ? null : const Color(0xFF161B22),
          border: isPrimary ? null : Border.all(color: Colors.white10),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B4EE6).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 15),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white24,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper for the custom glowing red logout action item
Widget _buildLogoutButton({
  required String label,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1214), // Dark charcoal red base tint
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.redAccent.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color: Colors.redAccent, size: 22),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.redAccent,
              size: 14,
            ),
          ],
        ),
      ),
    ),
  );
}

// Compact helper button design matching your exact UI parameters for multi-column rows
Widget _buildCompactMenuButton({
  required String label,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
