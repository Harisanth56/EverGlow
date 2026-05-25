import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DermaList extends StatefulWidget {
  const DermaList({super.key});

  @override
  State<DermaList> createState() => _DermaListState();
}

class _DermaListState extends State<DermaList> {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);

  List<Map<String, dynamic>> _pendingDerma = [];
  List<Map<String, dynamic>> _approvedDerma = [];
  List<Map<String, dynamic>> _rejectedDerma = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() => _isLoading = true);
    Future.wait([fetchPending(), fetchApproved(), fetchRejected()]).then((_) {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  // 2. HELPER METHOD TO OPEN & DOWNLOAD URL
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      // Launch URL in external browser which handles automatic asset downloading
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $urlString');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Could not open file link: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> fetchPending() async {
    try {
      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_status', 'pending');

      if (mounted) {
        setState(() => _pendingDerma = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint("Error Pending: $e");
    }
  }

  Future<void> fetchApproved() async {
    try {
      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_status', 'verified');

      if (mounted) {
        setState(() => _approvedDerma = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint("Error Approved: $e");
    }
  }

  Future<void> fetchRejected() async {
    try {
      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_status', 'rejected');

      if (mounted) {
        setState(() => _rejectedDerma = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint("Error Rejected: $e");
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
                  Tab(text: "Pending Requests"),
                  Tab(text: "Verified Specialists"),
                  Tab(text: "Rejected Requests"),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: accentColor))
                    : TabBarView(
                        children: [
                          _buildTableSection(_pendingDerma, type: "Pending"),
                          _buildTableSection(_approvedDerma, type: "Verified"),
                          _buildTableSection(_rejectedDerma, type: "Rejected"),
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
          "Dermatologist Management",
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
      ],
    );
  }

  Widget _buildTableSection(List<Map<String, dynamic>> data, {required String type}) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          "No $type Dermatologists found",
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
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 100),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.white10,
                  textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.03)),
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
      DataColumn(label: Text("SPECIALIZATION", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("EXP (YRS)", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("PROOF", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
      DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold))),
    ];
  }

  List<DataCell> _buildCells(int index, Map<String, dynamic> derma, String type) {
    final String? proofUrl = derma['dermatologist_proof'];
    final bool hasProof = proofUrl != null && proofUrl.isNotEmpty;

    return [
      DataCell(Text("$index", style: const TextStyle(color: Colors.white54))),
      DataCell(
        CircleAvatar(
          radius: 18,
          backgroundColor: Colors.white10,
          backgroundImage: (derma['dermatologist_photo'] != null && derma['dermatologist_photo'] != '')
              ? NetworkImage(derma['dermatologist_photo'])
              : null,
          child: (derma['dermatologist_photo'] == null || derma['dermatologist_photo'] == '')
              ? const Icon(Icons.person, size: 20, color: Colors.white24)
              : null,
        ),
      ),
      DataCell(Text(derma['dermatologist_name'] ?? 'N/A', style: const TextStyle(color: Colors.white))),
      DataCell(Text(derma['dermatologist_email'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
      DataCell(Text(derma['dermatologist_specialization'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
      DataCell(Text(derma['dermatologist_experience']?.toString() ?? '0', style: const TextStyle(color: Colors.white70))),
      
      // 3. UPDATED PROOF CELL (TEXT LINK WIDGET)
      DataCell(
        hasProof
            ? InkWell(
                onTap: () => _launchURL(proofUrl),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download, size: 16, color: Colors.blueAccent),
                      SizedBox(width: 6),
                      Text(
                        "View Document",
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : const Text("No Document", style: TextStyle(color: Colors.white24)),
      ),
      
      DataCell(_buildActionButtons(derma, type)),
    ];
  }

  Widget _buildActionButtons(Map<String, dynamic> derma, String type) {
    final String id = derma['dermatologist_id'].toString();

    if (type == "Pending") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Approve",
            icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
            onPressed: () => _updateStatus(id, 'verified'),
          ),
          IconButton(
            tooltip: "Reject",
            icon: const Icon(Icons.highlight_off, color: Colors.redAccent, size: 20),
            onPressed: () => _updateStatus(id, 'rejected'),
          ),
        ],
      );
    } else if (type == "Verified") {
      return IconButton(
        tooltip: "Revoke / Reject",
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
        onPressed: () => _updateStatus(id, 'rejected'),
      );
    } else {
      return IconButton(
        tooltip: "Re-approve",
        icon: const Icon(Icons.restore, color: Colors.blueAccent, size: 20),
        onPressed: () => _updateStatus(id, 'verified'),
      );
    }
  }

  Future<void> _updateStatus(dynamic id, String? status) async {
    try {
      await supabase
          .from('tbl_dermatologist')
          .update({'dermatologist_status': status})
          .eq('dermatologist_id', id);

      if (mounted) {
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'verified' ? 'Specialist Verified' : 'Status Updated'),
            backgroundColor: status == 'verified' ? Colors.green : Colors.red,
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }
}