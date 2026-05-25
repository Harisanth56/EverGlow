import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/main.dart'; // Ensure this points to your supabase instance

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

// ... existing imports ...

class _EditProfileState extends State<EditProfile> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  String? selectedGender;
  String? selectedSkinTypeId;
  List<Map<String, dynamic>> skinTypes = [];

  // Image handling variables
  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;
  String? photo; 
  bool _isUpdating = false; // Added loading state for button

  Future<void> handleImagePick() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.image,
      withData: true,
    );
    if (result == null) return;
    setState(() {
      pickedImage = result.files.first;
      imageBytes = pickedImage!.bytes;
    });
  }

  Future<String?> photoUpload(String uid) async {
    try {
      // Create a unique file path
      final filePath = "profile/$uid.${pickedImage!.extension}";
      
      // Upload to Supabase Storage
      await supabase.storage.from('Dermatologist').uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      
      // Return the public URL
      return supabase.storage.from('Dermatologist').getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchInitialData();
  }

  Future<void> fetchInitialData() async {
    try {
      final typeResponse = await supabase.from('tbl_type').select();
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final userData = await supabase
          .from('tbl_user')
          .select()
          .eq('user_id', user.id)
          .single();

      setState(() {
        skinTypes = List<Map<String, dynamic>>.from(typeResponse);
        nameController.text = userData['user_name'] ?? "";
        contactController.text = userData['user_contact'] ?? "";
        addressController.text = userData['user_address'] ?? "";
        selectedGender = userData['user_gender'];
        selectedSkinTypeId = userData['type_id']?.toString();
        photo = userData['user_photo']; // Load existing photo URL
      });
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E14),
        body: SafeArea(
          child: Column(
            children: [
              /// HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8E71FF), size: 22),
                    ),
                    const Text('Edit Profile', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      /// PROFILE IMAGE (Functionality Fixed)
                      GestureDetector(
                        onTap: handleImagePick,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: const Color(0xFF161B22),
                              backgroundImage: imageBytes != null
                                  ? MemoryImage(imageBytes!)
                                  : (photo != null ? NetworkImage(photo!) : null) as ImageProvider?,
                              child: (imageBytes == null && photo == null)
                                  ? const Icon(Icons.person, size: 50, color: Colors.white24)
                                  : null,
                            ),
                            const CircleAvatar(
                              radius: 15,
                              backgroundColor: Color(0xFF8E71FF),
                              child: Icon(Icons.camera_alt, size: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// FORM CONTAINER
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildMidnightInput(label: 'Full Name', hint: 'Enter your name', controller: nameController, icon: Icons.person_outline),
                            const SizedBox(height: 10),
                            _buildMidnightInput(label: 'Contact Number', hint: 'Enter contact number', controller: contactController, icon: Icons.phone_android_outlined, type: TextInputType.phone),
                            const SizedBox(height: 10),
                            _buildMidnightDropdown(
                              label: 'Gender',
                              hint: 'Choose your gender',
                              value: selectedGender,
                              icon: Icons.wc_outlined,
                              items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                              onChanged: (val) => setState(() => selectedGender = val),
                            ),
                            const SizedBox(height: 10),
                            _buildMidnightDropdown(
                              label: 'Skin Type',
                              hint: 'Choose your skin type',
                              value: selectedSkinTypeId,
                              icon: Icons.opacity_outlined,
                              items: skinTypes.map((type) {
                                return DropdownMenuItem(
                                  value: type['type_id'].toString(),
                                  child: Text(type['type_name'] ?? "Unknown"),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => selectedSkinTypeId = val),
                            ),
                            const SizedBox(height: 10),
                            _buildMidnightInput(label: 'Address', hint: 'Enter your address', controller: addressController, icon: Icons.location_on_outlined, type: TextInputType.streetAddress),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// UPDATE BUTTON (Fixed with Photo Upload logic)
                      GestureDetector(
                        onTap: _isUpdating ? null : () async {
                          setState(() => _isUpdating = true);
                          try {
                            final uid = supabase.auth.currentUser!.id;
                            String? finalPhotoUrl = photo;

                            // 1. Upload photo if a new one was picked
                            if (imageBytes != null) {
                              finalPhotoUrl = await photoUpload(uid);
                            }

                            // 2. Update database
                            await supabase.from('tbl_user').update({
                              'user_name': nameController.text,
                              'user_contact': contactController.text,
                              'user_gender': selectedGender,
                              'type_id': selectedSkinTypeId,
                              'user_address': addressController.text,
                              'user_photo': finalPhotoUrl, // Fixed field name
                            }).eq('user_id', uid);

                            if (mounted) Navigator.pop(context);
                          } catch (e) {
                            debugPrint("Update error: $e");
                          } finally {
                            if (mounted) setState(() => _isUpdating = false);
                          }
                        },
                        child: Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)]),
                            boxShadow: [BoxShadow(color: const Color(0xFF6B4EE6).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                          ),
                          child: Center(
                            child: _isUpdating 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMidnightDropdown({
    required String label,
    required String hint,
    required String? value,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: const Color(0xFF161B22),
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8E71FF)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF8E71FF), size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 18,
              horizontal: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF8E71FF)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMidnightInput({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF8E71FF), size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.1),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF8E71FF)),
            ),
          ),
        ),
      ],
    );
  }
  
}