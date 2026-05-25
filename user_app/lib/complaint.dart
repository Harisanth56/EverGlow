import 'dart:io'; // Needed for File
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/mycomplaints.dart';

class Complaint extends StatefulWidget {
  const Complaint({super.key});

  @override
  State<Complaint> createState() => _ComplaintState();
}

class _ComplaintState extends State<Complaint> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  // Variable to store the selected image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Function to pick image
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress slightly for better performance
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _submitComplaint() async {
    final supabase = Supabase.instance.client;

    // Basic Validation
    if (titleController.text.isEmpty || contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in the title and content")),
      );
      return;
    }

    // Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      String? imageUrl;

      // 1. UPLOAD IMAGE TO STORAGE (if selected)
      if (_selectedImage != null) {
        final fileName =
            'complaint_${DateTime.now().millisecondsSinceEpoch}.png';
        final path = 'complaints/$fileName';
        await supabase.storage.from('complaint').upload(path, _selectedImage!);

        // Get Public URL
        imageUrl = supabase.storage.from('complaint').getPublicUrl(path);
      }

      // 2. INSERT ROW INTO TABLE
      await supabase.from('tbl_complaint').insert({
        'complaint_title': titleController.text.trim(),
        'complaint_content': contentController.text.trim(),
        'complaint_date': DateTime.now().toIso8601String(),
        'complaint_status': 'Pending',
        'complaint_ss': imageUrl, // The image URL
        'user_id': supabase.auth.currentUser?.id, // Assuming user is logged in
        'dermatologist_id':null,
        // 'complaint_reply' is left null initially
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context); // Return to previous screen

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint registered successfully!")),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF8E71FF),
                        size: 22,
                      ),
                    ),
                    const Text(
                      'Register Complaint',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ComplaintHistory(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E71FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF8E71FF).withOpacity(0.2),
                          ),
                        ),
                        child: const Text(
                          'History',
                          style: TextStyle(
                            color: Color(0xFF8E71FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildMidnightInput(
                              label: 'Complaint Title',
                              hint: 'Brief summary of the issue',
                              controller: titleController,
                              icon: Icons.title_rounded,
                            ),
                            const SizedBox(height: 25),
                            _buildMidnightInput(
                              label: 'Content',
                              hint: 'Describe your issue in detail...',
                              controller: contentController,
                              icon: Icons.description_outlined,
                              maxLines: 6,
                            ),
                            const SizedBox(height: 25),

                            /// SCREENSHOT UPLOAD SECTION
                            _buildScreenshotUpload(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      /// SUBMIT BUTTON
                      GestureDetector(
                        onTap: _submitComplaint,
                        child: Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B4EE6).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Submit Complaint',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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

  Widget _buildScreenshotUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  Screenshot (Optional)",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: _selectedImage != null
                    ? const Color(0xFF8E71FF)
                    : Colors.white.withOpacity(0.05),
              ),
            ),
            child: _selectedImage != null
                ? Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Expanded(
                        child: Text(
                          "Image Selected",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _selectedImage = null),
                        icon: const Icon(
                          Icons.close,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Color(0xFF8E71FF),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Upload Screenshot",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 14,
                        ),
                      ),
                    ],
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
    int maxLines = 1,
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
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: EdgeInsets.only(bottom: maxLines > 1 ? 110 : 0),
              child: Icon(icon, color: const Color(0xFF8E71FF), size: 20),
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.2),
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.all(18),
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
