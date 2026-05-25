import 'package:dermatologist_app/main.dart';
import 'package:dermatologist_app/profile_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String name = "";
  String? photo;
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;

  // Counters based on the appointment table
  int get pendingCount => appointments.where((a) => a['appointment_status'] == 'pending').length;
  int get approvedCount => appointments.where((a) => a['appointment_status'] == 'accepted').length;

  @override
  void initState() {
    super.initState();
    _handleRefresh();
  }

  Future<void> _handleRefresh() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchderma(),
      fetchAppointments(),
    ]);
    if (mounted) setState(() => isLoading = false);
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
          photo = response['dermatologist_photo'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
    }
  }

  Future<void> fetchAppointments() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1. Fetch appointments where dermatologist_id matches current user id
      // 2. Perform join with tbl_user to get patient details
      final response = await supabase
          .from('tbl_appointment')
          .select('*, tbl_user(user_name, user_photo, user_contact)')
          .eq('dermatologist_id', user.id) // Filter by current dermatologist
          .order('appointment_date', ascending: false);

      if (mounted) {
        setState(() {
          appointments = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await supabase
          .from('tbl_appointment')
          .update({'appointment_status': newStatus})
          .eq('appointment_id', id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Appointment $newStatus"), backgroundColor: Colors.blueAccent),
      );
      fetchAppointments(); // Refresh list
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        
        body: SafeArea(
          child: RefreshIndicator(
            color: Colors.blueAccent,
            onRefresh: _handleRefresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(),
                  const SizedBox(height: 25),
                  _buildNotificationBar(),
                  const SizedBox(height: 20),
                  _buildStatsSection(),
                  const SizedBox(height: 20),
                  _buildIncomeCard(),
                  const SizedBox(height: 25),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text("Appointment Requests",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  _buildAppointmentList(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back,', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
              Text('Dr. $name', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            ],
          ),
          const Spacer(),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileSettings())),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blueAccent, width: 2)),
        child: CircleAvatar(
          radius: 28,
          backgroundColor: const Color(0xFF161B22),
          backgroundImage: (photo != null && photo!.isNotEmpty) ? NetworkImage(photo!) : null,
          child: (photo == null || photo!.isEmpty) ? const Icon(Icons.person, color: Colors.white24) : null,
        ),
      ),
    );
  }

  Widget _buildNotificationBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: Colors.amber.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Text('You have $pendingCount new appointments',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Row(
        children: [
          _buildStatsCard('Total', Icons.calendar_month, Colors.blueAccent, appointments.length),
          _buildStatsCard('Pending', Icons.pending_actions, Colors.amber, pendingCount),
          _buildStatsCard('Approved', Icons.check_circle, Colors.greenAccent, approvedCount),
        ],
      ),
    );
  }

  Widget _buildIncomeCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4facfe), Color(0xFF00f2fe)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("\$2,500.00", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              Icon(Icons.account_balance_wallet, color: Colors.white, size: 35),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentList() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(50.0),
        child: Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
      );
    }
    if (appointments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(50.0),
        child: Center(child: Text("No appointments found", style: TextStyle(color: Colors.white54))),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      itemCount: appointments.length,
      itemBuilder: (context, index) => _buildAppointmentCard(appointments[index]),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final user = appointment['tbl_user'] ?? {};
    String name = user['user_name'] ?? "Unknown Patient";
    String? photoUrl = user['user_photo'];
    String status = appointment['appointment_status'] ?? "pending";
    String date = appointment['appointment_date'] ?? "";
    String time = appointment['appointment_time'] ?? "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
                child: (photoUrl == null || photoUrl.isEmpty) ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("$date at $time", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              _buildStatusBadge(status),
            ],
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(appointment['appointment_id'].toString(), 'accepted'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Accept", style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateStatus(appointment['appointment_id'].toString(), 'rejected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text("Reject", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsCard(String text, IconData icon, Color iconColor, int count) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1E1E1E),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 26),
            const SizedBox(height: 8),
            Text(count.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            Text(text, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'accepted' ? Colors.greenAccent : (status == 'pending' ? Colors.amberAccent : Colors.redAccent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}