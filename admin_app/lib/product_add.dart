import 'dart:typed_data';
import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';

class AddProduct extends StatefulWidget {
  const AddProduct({super.key});

  @override
  State<AddProduct> createState() => _AddProductState();
}

class _AddProductState extends State<AddProduct> {
  // JosKart Dashboard Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);
  static const Color fieldColor = Color(0xFF0D0D0D);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  PlatformFile? _pickedFile;
  Uint8List? _webImage;
  String? _existingImageUrl; // Tracks current remote image during an edit
  String? _editingProductId; // Tracks the record ID if updating an asset
  bool _isUploading = false;

  String? _selectedCategory, _selectedLevel, _selectedHeat, _selectedSkin;

  List<Map<String, dynamic>> _products = [], _categories = [], _levels = [], _heatAbsorption = [], _skinTypes = [];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      fetchProducts(),
      fetchCategory(),
      fetchLevel(),
      fetchHeat(),
      fetchSkinType(),
    ]);
  }

  // --- Image Picker Logic ---
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _pickedFile = result.files.first;
          _webImage = _pickedFile!.bytes;
        });
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
    }
  }

  // --- Supabase Logic ---
  Future<void> fetchCategory() async {
    final res = await supabase.from('tbl_category').select();
    setState(() => _categories = res);
  }

  Future<void> fetchLevel() async {
    final res = await supabase.from('tbl_level').select();
    setState(() => _levels = res);
  }

  Future<void> fetchHeat() async {
    final res = await supabase.from('tbl_heatabsorption').select();
    setState(() => _heatAbsorption = res);
  }

  Future<void> fetchSkinType() async {
    final res = await supabase.from('tbl_type').select();
    setState(() => _skinTypes = res);
  }

  Future<void> fetchProducts() async {
    final res = await supabase.from('tbl_product').select();
    setState(() => _products = res);
  }

  // Populates the control panel fields with targeted product values
  void _prepareEdit(Map<String, dynamic> prod) {
    setState(() {
      _editingProductId = prod['product_id'].toString();
      nameController.text = prod['product_name'] ?? "";
      descController.text = prod['product_description'] ?? "";
      priceController.text = prod['product_price']?.toString() ?? "";
      _selectedCategory = prod['category_id']?.toString();
      _selectedLevel = prod['level_id']?.toString();
      _selectedHeat = prod['heatabsorption_id']?.toString();
      _selectedSkin = prod['type_id']?.toString();
      _existingImageUrl = prod['product_photo'];
      _webImage = null; // Prioritizes network URL rendering over raw local memory bytes
      _pickedFile = null;
    });

    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  // Unified save engine handling both New Insertions and Targeted Edits
  Future<void> saveProduct() async {
    if (nameController.text.isEmpty || _selectedCategory == null) {
      _showSnackBar('Please complete all required fields', isError: true);
      return;
    }

    if (_editingProductId == null && _webImage == null) {
      _showSnackBar('Please pick an image for the new product', isError: true);
      return;
    }

    setState(() => _isUploading = true);
    try {
      String? finalImageUrl = _existingImageUrl;

      // Handle raw file transmission if a fresh target file has been loaded locally
      if (_webImage != null && _pickedFile != null) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final extension = _pickedFile!.extension ?? 'png';
        final filePath = "product_photos/$fileName.$extension";

        await supabase.storage.from('product').uploadBinary(
              filePath,
              _webImage!,
              fileOptions: FileOptions(upsert: true, contentType: 'image/$extension'),
            );

        finalImageUrl = supabase.storage.from('product').getPublicUrl(filePath);
      }

      final payload = {
        'product_name': nameController.text.trim(),
        'product_description': descController.text.trim(),
        'product_price': priceController.text.trim(),
        'product_photo': finalImageUrl,
        'category_id': _selectedCategory,
        'level_id': _selectedLevel,
        'heatabsorption_id': _selectedHeat,
        'type_id': _selectedSkin,
      };

      if (_editingProductId != null) {
        // Run targeted updates inside Supabase
        await supabase.from('tbl_product').update(payload).eq('product_id', _editingProductId!);
        _showSnackBar('Product Updated Successfully');
      } else {
        // Run clean document insertion inside Supabase
        await supabase.from('tbl_product').insert(payload);
        _showSnackBar('Product Added Successfully');
      }

      _clearForm();
      fetchProducts();
    } catch (e) {
      _showSnackBar('Error processing transaction data', isError: true);
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _clearForm() {
    nameController.clear();
    descController.clear();
    priceController.clear();
    setState(() {
      _webImage = null;
      _pickedFile = null;
      _existingImageUrl = null;
      _editingProductId = null;
      _selectedCategory = _selectedLevel = _selectedHeat = _selectedSkin = null;
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: isError ? Colors.redAccent : accentColor, 
        behavior: SnackBarBehavior.floating, 
        width: 400
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildFormCard(),
                  const SizedBox(height: 50),
                  const Text("Catalog Inventory", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
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
        IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        const SizedBox(width: 15),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Product Management", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
            Text("Add new formulations and manage global stock details", style: TextStyle(color: Colors.white38, fontSize: 16)),
          ],
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    final bool isEditing = _editingProductId != null;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePickerSection(),
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildDarkTextField(nameController, "PRODUCT NAME", Icons.shopping_bag_outlined)),
                        const SizedBox(width: 20),
                        Expanded(child: _buildDarkTextField(priceController, "UNIT PRICE (₹)", Icons.payments_outlined, isNumber: true)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Row(
                      children: [
                        Expanded(child: _buildDarkDropdown("CATEGORY", _selectedCategory, _categories, 'category_id', 'category_name', (v) => setState(() => _selectedCategory = v))),
                        const SizedBox(width: 20),
                        Expanded(child: _buildDarkDropdown("SKIN TYPE", _selectedSkin, _skinTypes, 'type_id', 'type_name', (v) => setState(() => _selectedSkin = v))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            children: [
              Expanded(child: _buildDarkDropdown("ABSORPTION LEVEL", _selectedLevel, _levels, 'level_id', 'level_name', (v) => setState(() => _selectedLevel = v))),
              const SizedBox(width: 20),
              Expanded(child: _buildDarkDropdown("HEAT SENSITIVITY", _selectedHeat, _heatAbsorption, 'heatabsorption_id', 'heatabsorption_name', (v) => setState(() => _selectedHeat = v))),
            ],
          ),
          const SizedBox(height: 25),
          _buildDarkTextField(descController, "PRODUCT DESCRIPTION", Icons.notes_rounded, maxLines: 3),
          const SizedBox(height: 35),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearForm, 
                child: Text(isEditing ? "CANCEL EDIT" : "RESET FORM", style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold))
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : saveProduct,
                icon: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_isUploading ? "SAVING..." : (isEditing ? "UPDATE PRODUCT" : "PUBLISH PRODUCT")),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor, 
                  foregroundColor: Colors.white, 
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerSection() {
    Widget imagePreview = const Column(
      mainAxisAlignment: MainAxisAlignment.center, 
      children: [
        Icon(Icons.add_a_photo_rounded, color: Colors.white24, size: 48), 
        SizedBox(height: 12), 
        Text("Upload Preview", style: TextStyle(color: Colors.white24))
      ]
    );

    if (_webImage != null) {
      imagePreview = Image.memory(_webImage!, fit: BoxFit.cover);
    } else if (_existingImageUrl != null) {
      imagePreview = Image.network(
        _existingImageUrl!, 
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white10, size: 48),
      );
    }

    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: fieldColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: (_webImage == null && _existingImageUrl == null) ? Colors.white10 : accentColor, width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14), 
              child: imagePreview
            ),
          ),
        ),
        if (_webImage != null || _existingImageUrl != null) 
          TextButton(onPressed: _pickImage, child: const Text("Replace Photo", style: TextStyle(color: accentColor))),
      ],
    );
  }

  Widget _buildDarkTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white24, size: 20),
            filled: true,
            fillColor: fieldColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accentColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildDarkDropdown(String label, String? value, List<Map<String, dynamic>> items, String idKey, String nameKey, Function(String?) onChanged) {
    // Validates if active ID exists inside loaded map properties to protect against layout rendering faults
    final bool hasValidMatch = items.any((element) => element[idKey].toString() == value);
    final String? cleanValue = hasValidMatch ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: fieldColor, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: cleanValue,
              isExpanded: true,
              dropdownColor: cardColor,
              icon: const Icon(Icons.expand_more_rounded, color: Colors.white24),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: onChanged,
              items: items.map((item) => DropdownMenuItem(value: item[idKey].toString(), child: Text(item[nameKey]))).toList(),
              hint: const Text("Select option", style: TextStyle(color: Colors.white10)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTableCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.white10),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.white.withOpacity(0.02)),
            dataRowMaxHeight: 90,
            columns: const [
              DataColumn(label: Text("SL", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text("PRODUCT", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text("DESCRIPTION", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text("PRICE", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
              DataColumn(label: Text("ACTIONS", style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12))),
            ],
            rows: _products.asMap().entries.map((entry) {
              final prod = entry.value;
              return DataRow(cells: [
                DataCell(Text("${entry.key + 1}", style: const TextStyle(color: Colors.white24))),
                DataCell(Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(prod['product_photo'] ?? "", width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white10))),
                  const SizedBox(width: 15),
                  Text(prod['product_name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ])),
                DataCell(SizedBox(width: 250, child: Text(prod['product_description'] ?? "", maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)))),
                DataCell(Text("₹${prod['product_price']}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))),
                DataCell(Row(children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20), 
                    onPressed: () => _prepareEdit(prod)
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), 
                    onPressed: () async {
                      try {
                        final targetId = prod['product_id'];
                        // Instantly wipe from active view for premium interaction responsiveness
                        setState(() {
                          _products.removeWhere((p) => p['product_id'] == targetId);
                        });
                        await supabase.from('tbl_product').delete().eq('product_id', targetId);
                        _showSnackBar('Product Removed Successfully');
                      } catch (e) {
                        _showSnackBar('Error removing product entries', isError: true);
                        fetchProducts(); // Restore original UI set state if network crash drops execution
                      }
                    }
                  ),
                ])),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}