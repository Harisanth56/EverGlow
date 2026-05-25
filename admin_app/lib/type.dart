import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class SkinType extends StatefulWidget {
  const SkinType({super.key});

  @override
  State<SkinType> createState() => _SkinTypeState();
}

class _SkinTypeState extends State<SkinType> {
  final TextEditingController typeController = TextEditingController();
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;

  // JosKart Dashboard Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D); 
  static const Color cardColor = Color(0xFF1A1A1A); 
  static const Color accentColor = Color(0xFFE94E1B); 
  static const Color fieldColor = Color(0xFF0D0D0D);

  @override
  void initState() {
    super.initState();
    fetchType();
  }

  Future<void> fetchType() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase.from('tbl_type').select().order('type_id', ascending: true);
      setState(() {
        _types = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> insert() async {
    final name = typeController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a skin type name', isError: true);
      return;
    }

    try {
      await supabase.from('tbl_type').insert({'type_name': name});
      _showSnackBar('Skin Type "$name" Added Successfully');
      typeController.clear();
      fetchType();
    } catch (e) {
      _showSnackBar('Error adding skin type', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: isError ? Colors.redAccent : Colors.green,
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
                    "Dermatological Classifications",
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
              "Skin Type Management",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            Text(
              "Define and manage skin categories for intelligent product recommendations",
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("NEW CLASSIFICATION", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                TextField(
                  controller: typeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "e.g. Oily, Combination, Sensitive",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: fieldColor,
                    prefixIcon: const Icon(Icons.face_retouching_natural, color: Colors.white24, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor, width: 1.5)),
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
              icon: const Icon(Icons.add, size: 18),
              label: const Text("SAVE TYPE"),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
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
                  DataColumn(label: Text("SKIN TYPE NAME", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: _types.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final data = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text("$index", style: const TextStyle(color: Colors.white54))),
                      DataCell(Text(data['type_name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15))),
                      DataCell(Row(
                        children: [
                          _buildActionButton(Icons.edit_outlined, Colors.blueAccent, () => showEditDialog(data)),
                          const SizedBox(width: 10),
                          _buildActionButton(Icons.delete_outline, Colors.redAccent, () async {
                            await supabase.from('tbl_type').delete().eq('type_id', data['type_id']);
                            fetchType();
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
        tooltip: icon == Icons.edit_outlined ? 'Edit' : 'Delete',
      ),
    );
  }

  void showEditDialog(Map<String, dynamic> data) {
    TextEditingController editController = TextEditingController(text: data['type_name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Classification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("UPDATE NAME", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
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
            child: const Text('CANCEL', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;
              await supabase.from('tbl_type').update({'type_name': editController.text.trim()}).eq('type_id', data['type_id']);
              if (mounted) Navigator.pop(context);
              fetchType();
            },
            child: const Text('UPDATE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}