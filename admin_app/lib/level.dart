import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class HeatLevel extends StatefulWidget {
  const HeatLevel({super.key});

  @override
  State<HeatLevel> createState() => _HeatLevelState();
}

class _HeatLevelState extends State<HeatLevel> {
  final TextEditingController levelController = TextEditingController();
  List<Map<String, dynamic>> _levels = [];
  bool _isLoading = true;

  // JosKart Dashboard Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D); 
  static const Color cardColor = Color(0xFF1A1A1A); 
  static const Color accentColor = Color(0xFFE94E1B); 
  static const Color fieldColor = Color(0xFF0D0D0D);

  @override
  void initState() {
    super.initState();
    fetchLevels();
  }

  Future<void> fetchLevels() async {
    setState(() => _isLoading = true);
    try {
      // Fetching and ordering by ID for a consistent table view
      final response = await supabase.from('tbl_level').select().order('level_id', ascending: true);
      setState(() {
        _levels = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> insert() async {
    final text = levelController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Please enter a level name', isError: true);
      return;
    }
    try {
      await supabase.from('tbl_level').insert({'level_name': text});
      _showSnackBar('Level "$text" Added Successfully');
      levelController.clear();
      fetchLevels();
    } catch (e) {
      _showSnackBar('Error adding level', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : accentColor,
        behavior: SnackBarBehavior.floating,
        width: 400,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildInputCard(),
                  const SizedBox(height: 40),
                  const Text(
                    "Configured Levels",
                    style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildDataTableCard(),
                ],
              ),
            ),
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
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Level Management",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            Text(
              "Configure product intensity or performance levels",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("NEW LEVEL NAME", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                TextField(
                  controller: levelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "e.g. Level 1, High, Beginner",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: fieldColor,
                    prefixIcon: const Icon(Icons.leaderboard_outlined, color: Colors.white24, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 1)),
                  ),
                  onSubmitted: (_) => insert(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 25),
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: ElevatedButton.icon(
              onPressed: insert,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("SAVE LEVEL"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTableCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _isLoading 
          ? const Padding(padding: EdgeInsets.all(80), child: Center(child: CircularProgressIndicator(color: accentColor)))
          : Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.white10),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.02)),
                dataRowMinHeight: 65,
                dataRowMaxHeight: 75,
                columns: const [
                  DataColumn(label: Text("SL NO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("LEVEL NAME", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: _levels.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final data = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text("$index", style: const TextStyle(color: Colors.white54))),
                      DataCell(Text(data['level_name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15))),
                      DataCell(Row(
                        children: [
                          _buildActionButton(Icons.edit_outlined, Colors.blueAccent, () => showEditDialog(data)),
                          const SizedBox(width: 10),
                          _buildActionButton(Icons.delete_outline, Colors.redAccent, () async {
                            await supabase.from('tbl_level').delete().eq('level_id', data['level_id']);
                            fetchLevels();
                          }),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        icon: Icon(icon, color: color, size: 18),
        onPressed: onTap,
        splashRadius: 20,
      ),
    );
  }

  void showEditDialog(Map<String, dynamic> data) {
    TextEditingController editController = TextEditingController(text: data['level_name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Level', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ENTER NEW NAME", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: editController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: fieldColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;
              await supabase.from('tbl_level').update({'level_name': editController.text.trim()}).eq('level_id', data['level_id']);
              if (mounted) Navigator.pop(context);
              fetchLevels();
            },
            child: const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}