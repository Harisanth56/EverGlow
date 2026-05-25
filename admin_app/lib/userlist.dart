import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Userlist extends StatefulWidget {
  const Userlist({super.key});

  @override
  State<Userlist> createState() => _UserlistState();
}

class _UserlistState extends State<Userlist> {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);

  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _approvedUsers = [];
  List<Map<String, dynamic>> _rejectedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() => _isLoading = true);
    Future.wait([
      _fetchPending(),
      _fetchApproved(),
      _fetchRejected(),
    ]).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _fetchPending() async {
    try {
      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('user_status', 'pending');
      if (mounted) {
        setState(() => _pendingUsers = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint("Fetch Pending Error: $e");
    }
  }

  Future<void> _fetchApproved() async {
    try {
      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('user_status', 'approved');
      if (mounted) {
        setState(() => _approvedUsers = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint("Fetch Approved Error: $e");
    }
  }

  Future<void> _fetchRejected() async {
    try {
      final response = await supabase
          .from('tbl_user')
          .select()
          .eq('user_status', 'rejected');
      if (mounted) {
        setState(() => _rejectedUsers = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint("Fetch Rejected Error: $e");
    }
  }

  Future<void> _updateStatus(String userId, String status) async {
    try {
      await supabase
          .from('tbl_user')
          .update({'user_status': status})
          .eq('user_id', userId);

      if (mounted) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'approved' ? 'User Approved' : 'User Rejected'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Status Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorColor: accentColor,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                tabs: const [
                  Tab(text: "Pending Registrations"),
                  Tab(text: "Approved Users"),
                  Tab(text: "Rejected Users"),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: accentColor))
                    : TabBarView(
                        children: [
                          _buildTableSection(_pendingUsers, type: "Pending"),
                          _buildTableSection(_approvedUsers, type: "Approved"),
                          _buildTableSection(_rejectedUsers, type: "Rejected"),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 15),
        const Text(
          "User Records",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
      ],
    );
  }

  Widget _buildTableSection(List<Map<String, dynamic>> data, {required String type}) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No $type Users found",
          style: const TextStyle(color: Colors.white24, fontSize: 16),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width - 100,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.white10,
                  textTheme: const TextTheme(
                    bodyMedium: TextStyle(color: Colors.white),
                  ),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    Colors.white.withOpacity(0.03),
                  ),
                  columnSpacing: 24,
                  horizontalMargin: 20,
                  columns: _buildColumns(),
                  rows: data.asMap().entries.map((entry) {
                    return DataRow(
                      cells: _buildCells(entry.key + 1, entry.value, type),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    return const [
      DataColumn(label: Text("SL.NO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("PHOTO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("NAME", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("EMAIL", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("CONTACT", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("GENDER", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("TYPE ID", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
    ];
  }

  List<DataCell> _buildCells(int index, Map<String, dynamic> user, String type) {
    return [
      DataCell(Text("$index", style: const TextStyle(color: Colors.white54))),
      DataCell(
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white10,
          backgroundImage: user['user_photo'] != null && user['user_photo'] != ''
              ? NetworkImage(user['user_photo'])
              : null,
          child: user['user_photo'] == null || user['user_photo'] == ''
              ? const Icon(Icons.person, size: 20, color: Colors.white24)
              : null,
        ),
      ),
      DataCell(Text(user['user_name'] ?? 'N/A', style: const TextStyle(color: Colors.white))),
      DataCell(Text(user['user_email'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
      DataCell(Text(user['user_contact']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.white70))),
      DataCell(Text(user['user_gender'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
      DataCell(Text(user['type_id']?.toString() ?? 'N/A', style: const TextStyle(color: Colors.white70))),
      DataCell(_buildActionButtons(user, type)),
    ];
  }

  Widget _buildActionButtons(Map<String, dynamic> user, String type) {
    final String id = user['user_id'].toString();

    if (type == "Pending") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Approve",
            icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
            onPressed: () => _updateStatus(id, 'approved'),
          ),
          IconButton(
            tooltip: "Reject",
            icon: const Icon(Icons.highlight_off, color: Colors.redAccent, size: 20),
            onPressed: () => _updateStatus(id, 'rejected'),
          ),
        ],
      );
    } else if (type == "Approved") {
      return IconButton(
        tooltip: "Revoke / Reject",
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
        onPressed: () => _updateStatus(id, 'rejected'),
      );
    } else {
      return IconButton(
        tooltip: "Re-approve",
        icon: const Icon(Icons.restore, color: Colors.blueAccent, size: 20),
        onPressed: () => _updateStatus(id, 'approved'),
      );
    }
  }
}