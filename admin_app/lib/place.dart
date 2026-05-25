import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Place extends StatefulWidget {
  const Place({super.key});

  @override
  State<Place> createState() => _PlaceState();
}

class _PlaceState extends State<Place> {
  final TextEditingController placeController = TextEditingController();
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _places = [];
  String? _selectedValue;
  bool _isLoading = true;

  // JosKart Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D); 
  static const Color cardColor = Color(0xFF1A1A1A); 
  static const Color accentColor = Color(0xFFE94E1B); 
  static const Color fieldColor = Color(0xFF0D0D0D); 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await fetchDistricts();
    await fetchPlaces();
    setState(() => _isLoading = false);
  }

  Future<void> fetchDistricts() async {
    try {
      final response = await supabase.from('tbl_district').select();
      setState(() {
        _districts = response;
        if (_districts.isNotEmpty && _selectedValue == null) {
          _selectedValue = _districts.first['district_id'].toString();
        }
      });
    } catch (e) {
      debugPrint("District Fetch Error: $e");
    }
  }

  Future<void> fetchPlaces() async {
    try {
      final response = await supabase.from('tbl_place').select(
            'place_id, place_name, district_id, tbl_district!inner(district_name)',
          );
      setState(() => _places = response);
    } catch (e) {
      debugPrint("Place Fetch Error: $e");
    }
  }

  Future<void> insert() async {
    final name = placeController.text.trim();
    if (_selectedValue == null || name.isEmpty) {
      _showSnackBar('Please select a district and enter a place name', isError: true);
      return;
    }

    try {
      await supabase.from('tbl_place').insert({
        'place_name': name,
        'district_id': int.parse(_selectedValue!),
      });
      _showSnackBar('Place "$name" Added Successfully');
      placeController.clear();
      fetchPlaces();
    } catch (e) {
      _showSnackBar('Error adding place', isError: true);
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
                    "Location Directory",
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
              "Place Management",
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            Text(
              "Link specific locations to their respective districts",
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // District Dropdown
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("SELECT DISTRICT", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: fieldColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedValue,
                      dropdownColor: cardColor,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: accentColor,
                      isExpanded: true,
                      onChanged: (val) => setState(() => _selectedValue = val),
                      items: _districts.map((d) {
                        return DropdownMenuItem(
                          value: d['district_id'].toString(),
                          child: Text(d['district_name']),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Place Name Input
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("PLACE NAME", style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                TextField(
                  controller: placeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Enter location name",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                    filled: true,
                    fillColor: fieldColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: accentColor)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: insert,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("ADD PLACE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
          ? const Padding(padding: EdgeInsets.all(50), child: Center(child: CircularProgressIndicator(color: accentColor)))
          : Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.white10),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.02)),
                dataRowMinHeight: 65,
                dataRowMaxHeight: 75,
                columns: const [
                  DataColumn(label: Text("SL NO", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("DISTRICT", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("PLACE NAME", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
                ],
                rows: _places.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final place = entry.value;
                  final district = place['tbl_district'] as Map<String, dynamic>?;
                  return DataRow(cells: [
                    DataCell(Text("$index", style: const TextStyle(color: Colors.white54))),
                    DataCell(Text(district?['district_name'] ?? '', style: const TextStyle(color: Colors.white70))),
                    DataCell(Text(place['place_name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
                    DataCell(Row(
                      children: [
                        _buildActionButton(Icons.edit_outlined, Colors.blueAccent, () => showEditDialog(place)),
                        const SizedBox(width: 10),
                        _buildActionButton(Icons.delete_outline, Colors.redAccent, () async {
                          await supabase.from('tbl_place').delete().eq('place_id', place['place_id']);
                          fetchPlaces();
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
    TextEditingController editController = TextEditingController(text: data['place_name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Place', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("NEW PLACE NAME", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
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
            style: ElevatedButton.styleFrom(backgroundColor: accentColor),
            onPressed: () async {
              if (editController.text.trim().isEmpty) return;
              await supabase.from('tbl_place').update({'place_name': editController.text.trim()}).eq('place_id', data['place_id']);
              if (mounted) Navigator.pop(context);
              fetchPlaces();
            },
            child: const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}