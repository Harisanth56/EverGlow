import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppointmentManagement extends StatefulWidget {
  const AppointmentManagement({super.key});

  @override
  State<AppointmentManagement> createState() => _AppointmentManagementState();
}

class _AppointmentManagementState extends State<AppointmentManagement> {
  final supabase = Supabase.instance.client;

  // Function to update status (Accept/Reject/Complete)
  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await supabase
          .from('tbl_appointment')
          .update({'appointment_status': newStatus})
          .eq('appointment_id', id);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Marked as $newStatus"),
          backgroundColor: newStatus == 'rejected' ? Colors.redAccent : Colors.blueAccent,
        ),
      );
    } catch (e) {
      debugPrint("Error updating: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          title: const Text("Management", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
          bottom: TabBar(
            indicatorColor: Colors.blueAccent,
            indicatorWeight: 3,
            labelColor: Colors.blueAccent,
            unselectedLabelColor: Colors.white24,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: "PENDING", icon: Icon(Icons.hourglass_empty_rounded, size: 20)),
              Tab(text: "APPROVED", icon: Icon(Icons.check_circle_outline_rounded, size: 20)),
              Tab(text: "CONSULTED", icon: Icon(Icons.history_edu_rounded, size: 20)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAppointmentList('pending'),
            _buildAppointmentList('accepted'),
            _buildAppointmentList('consulted'),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(String statusFilter) {
  final drId = supabase.auth.currentUser?.id;

  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: supabase
        .from('tbl_appointment')
        .stream(primaryKey: ['appointment_id']) // Define primary key here
        .eq('dermatologist_id', drId ?? '')     // First filter
        .order('appointment_date', ascending: true),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
      }

      // MANUALLY FILTER the list by status here
      // This is because .stream() only supports one .eq() filter in some plugin versions
      final allAppointments = snapshot.data ?? [];
      final list = allAppointments.where((item) => 
        item['appointment_status'].toString().toLowerCase() == statusFilter.toLowerCase()
      ).toList();

      if (list.isEmpty) {
        return Center(
          child: Text(
            "No ${statusFilter.toUpperCase()} appointments",
            style: const TextStyle(color: Colors.white10, fontSize: 16),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          // Your existing FutureBuilder logic for tbl_user...
          return FutureBuilder(
            future: supabase.from('tbl_user').select().eq('user_id', item['user_id']).maybeSingle(),
            builder: (context, userSnap) {
              final user = userSnap.data ?? {};
              return _buildPatientRecordCard(item, user, statusFilter);
            },
          );
        },
      );
    },
  );
}

  Widget _buildPatientRecordCard(Map<String, dynamic> appointment, Map<String, dynamic> user, String status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.black,
                backgroundImage: user['user_photo'] != null ? NetworkImage(user['user_photo']) : null,
                child: user['user_photo'] == null ? const Icon(Icons.person, color: Colors.white10) : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['user_name'] ?? "Patient", 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text("${appointment['appointment_date']} | ${appointment['appointment_time']}", 
                        style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildActionButtons(appointment['appointment_id'].toString(), status),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String id, String currentStatus) {
    if (currentStatus == 'pending') {
      return Row(
        children: [
          Expanded(
            child: _actionBtn("ACCEPT", Colors.blueAccent, () => _updateStatus(id, 'accepted')),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn("REJECT", Colors.redAccent.withOpacity(0.5), () => _updateStatus(id, 'rejected')),
          ),
        ],
      );
    } else if (currentStatus == 'accepted') {
      return _actionBtn("MARK AS CONSULTED", Colors.greenAccent.withOpacity(0.8), () => _updateStatus(id, 'consulted'));
    } else {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, color: Colors.white10, size: 14),
          SizedBox(width: 5),
          Text("CONSULTATION COMPLETED", style: TextStyle(color: Colors.white10, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      );
    }
  }

  Widget _actionBtn(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}