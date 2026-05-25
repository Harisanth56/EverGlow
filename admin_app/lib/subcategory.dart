import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class SubCategory extends StatefulWidget {
  const SubCategory({super.key});

  @override
  State<SubCategory> createState() => _SubCategoryState();
}

class _SubCategoryState extends State<SubCategory> {
  final TextEditingController subcategoryController = TextEditingController();
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCategories = [];
  String? _selectedValue;
  bool _isLoading = true;

  // JosKart Dashboard Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D); 
  static const Color cardColor = Color(0xFF1A1A1A); 
  static const Color accentColor = Color(0xFFE94E1B); 
  static const Color fieldColor = Color(0xFF0D0D0D); 

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await fetchCategory();
    await fetchSubCategory();
    setState(() => _isLoading = false);
  }

  Future<void> fetchCategory() async {
    try {
      final response = await supabase.from('tbl_category').select().order('category_name');
      setState(() {
        _categories = response;
        if (_categories.isNotEmpty && _selectedValue == null) {
          _selectedValue = _categories.first['category_id'].toString();
        }
      });
    } catch (e) {
      debugPrint("Category Fetch Error: $e");
    }
  }

  Future<void> fetchSubCategory() async {
    try {
      // Maintaining your relational inner join
      final response = await supabase.from('tbl_subcategory').select(
            'subcategory_id, subcategory_name, category_id, tbl_category!inner(category_name)',
          ).order('subcategory_id');
      setState(() => _subCategories = response);
    } catch (e) {
      debugPrint("SubCategory Fetch Error: $e");
    }
  }

  Future<void> insert() async {
    final name = subcategoryController.text.trim();
    if (_selectedValue == null || name.isEmpty) {
      _showSnackBar('Select a parent category and enter a sub-category name', isError: true);
      return;
    }

    try {
      await supabase.from('tbl_subcategory').insert({
        'subcategory_name': name,
        'category_id': int.parse(_selectedValue!),
      });
      _showSnackBar('Sub-Category "$name" added successfully');
      subcategoryController.clear();
      fetchSubCategory();
    } catch (e) {
      _showSnackBar('Failed to add Sub-Category', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        width: 450,
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
                    "Hierarchy Overview",
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
              "SubCategory Management",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            Text(
              "Define granular classifications for JosKart inventory",
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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Parent Category Dropdown
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PARENT CATEGORY", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedValue,
                      dropdownColor: cardColor,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      iconEnabledColor: accentColor,
                      isExpanded: true,
                      onChanged: (val) => setState(() => _selectedValue = val),
                      items: _categories.map((c) {
                        return DropdownMenuItem(
                          value: c['category_id'].toString(),
                          child: Text(c['category_name']),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 25),
          // Sub-Category Name Input
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SUB-CATEGORY NAME", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                TextField(
                  controller: subcategoryController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "e.g. Cleansers, Moisturizers",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: fieldColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentColor, width: 1)),
                  ),
                  onSubmitted: (_) => insert(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 25),
          ElevatedButton.icon(
            onPressed: insert,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("CREATE ENTRY"),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
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
          ? const Padding(padding: EdgeInsets.all(100), child: Center(child: CircularProgressIndicator(color: accentColor)))
          : Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.white10),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.02)),
                dataRowMinHeight: 65,
                dataRowMaxHeight: 75,
                columns: const [
                  DataColumn(label: Text("SL NO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("PARENT CATEGORY", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("SUB-CATEGORY NAME", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: _subCategories.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final sub = entry.value;
                  final category = sub['tbl_category'] as Map<String, dynamic>?;
                  return DataRow(cells: [
                    DataCell(Text("$index", style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(category?['category_name'] ?? 'N/A', style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(sub['subcategory_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                    DataCell(Row(
                      children: [
                        _buildActionButton(Icons.edit_outlined, Colors.blueAccent, () => showEditDialog(sub)),
                        const SizedBox(width: 10),
                        _buildActionButton(Icons.delete_outline, Colors.redAccent, () async {
                          await supabase.from('tbl_subcategory').delete().eq('subcategory_id', sub['subcategory_id']);
                          fetchSubCategory();
                        }),
                      ],
                    )),
                  ]);
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
    TextEditingController editController = TextEditingController(text: data['subcategory_name']);
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
              await supabase.from('tbl_subcategory').update({'subcategory_name': editController.text.trim()}).eq('subcategory_id', data['subcategory_id']);
              if (mounted) Navigator.pop(context);
              fetchSubCategory();
            },
            child: const Text('SAVE UPDATES', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}