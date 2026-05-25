import 'package:admin_app/replay.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewComplaints extends StatefulWidget {
  const ViewComplaints({super.key});

  @override
  State<ViewComplaints> createState() => _ViewComplaintsState();
}

class _ViewComplaintsState extends State<ViewComplaints> {
  static const Color bgColor = Color(0xFF0A0A0A);
  static const Color cardBorder = Color(0xFF222222);
  static const Color accentColor = Color(0xFFE94E1B);

  late Future<List<Map<String, dynamic>>> _complaintsFuture;

  @override
  void initState() {
    super.initState();
    _complaintsFuture = _fetchComplaints();
  }

  Future<List<Map<String, dynamic>>> _fetchComplaints() async {
    final data = await Supabase.instance.client
        .from('tbl_complaint')
        .select('*, tbl_user(user_name)')
        .order('complaint_date', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> _openScreenshot(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Management Console",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w300, fontSize: 18, letterSpacing: 2),
        ),
        actions: [
          IconButton(onPressed: () => setState(() {}), icon: const Icon(Icons.sort, color: accentColor))
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _complaintsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentColor, strokeWidth: 1));
          }
          if (snapshot.hasError) {
            return Center(child: Text("System Error", style: TextStyle(color: accentColor)));
          }

          final complaints = snapshot.data ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: complaints.length,
            itemBuilder: (context, index) => _buildModernRecord(complaints[index]),
          );
        },
      ),
    );
  }

  Widget _buildModernRecord(Map<String, dynamic> item) {
    final String status = item['complaint_status'] ?? 'Pending';
    final bool isPending = status.toLowerCase() == 'pending';
    final String? screenshotUrl = item['complaint_ss'];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(4), // Sharp, professional corners
        border: const Border(left: BorderSide(color: accentColor, width: 3)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Meta Data Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "REF: #${item['complaint_id']}".toUpperCase(),
                      style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      item['complaint_date'].toString().split('T')[0],
                      style: const TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Title & User
                Text(
                  item['complaint_title']?.toUpperCase() ?? 'UNTITLED',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1),
                ),
                Text(
                  "BY: ${item['tbl_user']?['user_name'] ?? 'UNKNOWN'}",
                  style: const TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: cardBorder, thickness: 1),
                ),
                // The Content Body
                Text(
                  item['complaint_content'] ?? '',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
          // Control Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF181818),
            ),
            child: Row(
              children: [
                _indicator(isPending ? "ACTION REQUIRED" : "RESOLVED", isPending),
                const Spacer(),
                if (screenshotUrl != null && screenshotUrl.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.collections_outlined, color: Colors.white38, size: 20),
                    onPressed: () => _openScreenshot(screenshotUrl),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Reply(
                          complaintId: item['complaint_id'].toString(),
                          userId: item['user_id'].toString(),
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text("REPLY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _indicator(String label, bool isPending) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isPending ? accentColor : Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isPending ? accentColor : Colors.green,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}