import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:user_app/navigator.dart';

class MyAppointments extends StatefulWidget {
  const MyAppointments({super.key});

  @override
  State<MyAppointments> createState() => _MyAppointmentsState();
}

class _MyAppointmentsState extends State<MyAppointments> {
  final supabase = Supabase.instance.client;

  // Tracks if the initial database payload collection has completed loading
  bool _isInitialLoading = true;

  Future<void> _cancelAppointment(String appointmentId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        title: const Text(
          "Cancel Appointment",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to cancel this appointment?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8E71FF)),
      ),
    );

    try {
      await supabase
          .from('tbl_appointment')
          .update({'appointment_status': 'cancelled'})
          .eq('appointment_id', appointmentId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Appointment Cancelled"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: _buildCircleBtn(Icons.arrow_back_ios_new, () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // Instead of destroying the stack, cleanly replace it or push standardly
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => IndexPage()),
            );
          }
        }),
        title: const Text(
          "My Schedule",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase
            .from('tbl_appointment')
            .stream(primaryKey: ['appointment_id'])
            .eq('user_id', userId ?? '')
            .order('appointment_date', ascending: false),
        builder: (context, snapshot) {
          // Check connection state or evaluate our custom loading tracker variable
          if (snapshot.connectionState == ConnectionState.waiting &&
              _isInitialLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E71FF)),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                "Error fetching data",
                style: TextStyle(color: Colors.white38),
              ),
            );
          }

          // Once data drops in, we safely toggled off initial loader flag background flashes
          if (snapshot.hasData && _isInitialLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _isInitialLoading = false;
                });
              }
            });
          }

          final appointments = snapshot.data ?? [];

          if (appointments.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final item = appointments[index];
              return FutureBuilder(
                future: supabase
                    .from('tbl_dermatologist')
                    .select('dermatologist_name')
                    .eq('dermatologist_id', item['dermatologist_id'])
                    .maybeSingle(),
                builder: (context, drSnapshot) {
                  // While doctor's name is loading in the card, show a tiny adaptive buffer structure
                  if (drSnapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF12161D),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      child: const Center(
                        child: SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Color(0xFF8E71FF),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    );
                  }

                  String drName = drSnapshot.hasData && drSnapshot.data != null
                      ? drSnapshot.data!['dermatologist_name']
                      : "Dermatologist";

                  return _buildAppointmentCard(item, drName);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> data, String drName) {
    final String status = data['appointment_status'] ?? 'Pending';
    final String dateStr = data['appointment_date'] ?? '';
    final String timeStr = data['appointment_time'] ?? '';
    final DateTime? parsedDate = DateTime.tryParse(dateStr);

    final String day = parsedDate != null
        ? DateFormat('dd').format(parsedDate)
        : '--';
    final String month = parsedDate != null
        ? DateFormat('MMM').format(parsedDate).toUpperCase()
        : '---';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF12161D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        color: Color(0xFF8E71FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      day,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "REF #${data['appointment_id']}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Dr. $drName",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_filled,
                            color: Colors.white.withOpacity(0.3),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (status.toLowerCase() == 'pending')
            Container(
              margin: const EdgeInsets.only(top: 15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_toggle_off,
                    color: Color.fromARGB(255, 148, 148, 148),
                    size: 14,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Awaiting doctor's response",
                    style: TextStyle(
                      color: Color.fromARGB(255, 148, 148, 148),
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        _cancelAppointment(data['appointment_id'].toString()),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: const Text(
                      "Cancel Request",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: const Color(0xFF161B22),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: const Color(0xFF8E71FF), size: 18),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return Colors.greenAccent;
      case 'rejected':
      case 'cancelled':
        return Colors.redAccent;
      case 'pending':
        return Colors.orangeAccent;
      default:
        return const Color(0xFF8E71FF);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy,
              size: 60,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Appointments",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Your scheduled consultations will appear here",
            style: TextStyle(color: Colors.white24, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
