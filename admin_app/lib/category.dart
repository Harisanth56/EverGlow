import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Category extends StatefulWidget {
  const Category({super.key});

  @override
  State<Category> createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  final TextEditingController categoryController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  // JosKart Dashboard Palette
  static const Color bgColor = Color(0xFF0D0D0D); 
  static const Color cardColor = Color(0xFF1A1A1A); 
  static const Color accentColor = Color(0xFFE94E1B); // JosKart Orange
  static const Color fieldColor = Color(0xFF0D0D0D);

  @override
  void initState() {
    super.initState();
    fetchCategory();
  }

  Future<void> fetchCategory() async {
    setState(() => _isLoading = true);
    try {
      // Fetching all data from tbl_category
      final response = await supabase.from('tbl_category').select().order('category_id', ascending: true);
      setState(() {
        _categories = response;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch Error: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> insert() async {
    final name = categoryController.text.trim();
    if (name.isEmpty) {
      _showSnackBar('Please enter a category name', isError: true);
      return;
    }

    try {
      await supabase.from('tbl_category').insert({'category_name': name});
      _showSnackBar('Category "$name" Added Successfully');
      categoryController.clear();
      fetchCategory();
    } catch (e) {
      _showSnackBar('Error adding category', isError: true);
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
                    "Product Categories",
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
              "Category Management",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            Text(
              "Create and organize the core taxonomy of JosKart products",
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
                const Text("NEW CATEGORY NAME", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "e.g. Skin Care, Hair Care",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: fieldColor,
                    prefixIcon: const Icon(Icons.category_outlined, color: Colors.white24, size: 20),
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
              icon: const Icon(Icons.add, size: 18),
              label: const Text("CREATE CATEGORY"),
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
                  DataColumn(label: Text("CATEGORY NAME", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: _categories.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final data = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(Text("$index", style: const TextStyle(color: Colors.white54))),
                      DataCell(Text(data['category_name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15))),
                      DataCell(Row(
                        children: [
                          _buildActionButton(Icons.edit_outlined, Colors.blueAccent, () => showEditDialog(data)),
                          const SizedBox(width: 8),
                          _buildActionButton(Icons.delete_outline, Colors.redAccent, () async {
                            await supabase.from('tbl_category').delete().eq('category_id', data['category_id']);
                            fetchCategory();
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
    TextEditingController editController = TextEditingController(text: data['category_name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("ENTER NEW NAME", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
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
              await supabase.from('tbl_category').update({'category_name': editController.text.trim()}).eq('category_id', data['category_id']);
              if (mounted) Navigator.pop(context);
              fetchCategory();
            },
            child: const Text('SAVE CHANGES', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}