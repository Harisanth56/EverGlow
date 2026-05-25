import 'package:user_app/dr_grid.dart';
import 'package:user_app/main.dart';
import 'package:user_app/cart.dart';
import 'package:user_app/myprofile.dart';
import 'package:user_app/my_booking.dart';
import 'package:user_app/user_homepage.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:line_icons/line_icons.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  int _selectedIndex = 0;
  String? photo;

  Future<void> loadUser() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        final response = await supabase
            .from('tbl_user')
            .select()
            .eq('user_id', user.id)
            .single();

        setState(() {
          photo = response['user_photo'];
        });
      }
    } catch (e) {
      debugPrint("Error loading profile photo: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // Pages
  static final List<Widget> _pages = <Widget>[
    const UserHomePage(),
    const MyAppointments(),
    const DoctorGridScreen(),
    const CartScreen(),
    const MyProfile(),
    

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),

      // Selected Page
      body: _pages[_selectedIndex],

      // Bottom Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.25),
            ),
          ],
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),

            child: GNav(
              // Animation
              curve: Curves.easeInOut,
              duration: const Duration(milliseconds: 250),

              // Effects
              rippleColor: Colors.purple.shade200,
              hoverColor: Colors.purple.shade100,
              haptic: true,

              // Spacing
              gap: 8,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 12,
              ),

              // Colors
              color: Colors.grey.shade400,
              activeColor: Colors.white,
              tabBackgroundColor: Color(0xFF8E71FF),

              // Shape
              tabBorderRadius: 16,

              // Icon Size
              iconSize: 26,

              // Selected Tab
              selectedIndex: _selectedIndex,

              // Tabs
              tabs: [
                const GButton(
                  icon: LineIcons.home,
                  text: 'Home',
                ),

                const GButton(
                  icon: LineIcons.calendar,
                  text: 'Schedule',
                ),

                const GButton(
                  icon: LineIcons.hospital,
                  text: 'Doctors',
                ),
                  const GButton(
                  icon: LineIcons.shoppingCart,
                  text: 'Cart',
                ),
                

                GButton(
                  icon: LineIcons.user,
                  text: 'Profile',

                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.grey.shade800,

                    backgroundImage: photo != null
                        ? NetworkImage(photo!)
                        : null,

                    child: photo == null
                        ? const Icon(
                            LineIcons.user,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
              ],

              // Tab Change
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}