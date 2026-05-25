import 'package:dermatologist_app/appointment.dart';
import 'package:dermatologist_app/homepage.dart';
import 'package:flutter/material.dart';
import 'profile_settings.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // The pages for the bottom bar
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomeScreen(),
      const PlaceholderPage(title: "Schedule Feed", icon: Icons.calendar_month),
      const AppointmentManagement(),
      const ProfileSettings(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // IndexedStack preserves the state of the Home Screen (scroll position/data)
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.black,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey[600],
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Schedule'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'Patients'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// Temporary page for Schedule and Patient tabs
class PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;
  const PlaceholderPage({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white10),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white38, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}