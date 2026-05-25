import 'package:dermatologist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  bool _isLoading = false;

  // Controllers (Removed contactController)
  final TextEditingController nameController = TextEditingController();
  final TextEditingController expController = TextEditingController();
  final TextEditingController proofController = TextEditingController();
  final TextEditingController specController = TextEditingController();

  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;
  file_picker.PlatformFile? pickedProof;
  Uint8List? proofBytes;
  String? photo;
  String? existingProofUrl;

  @override
  void initState() {
    super.initState();
    fetchderma();
  }

  Future<void> fetchderma() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          nameController.text = response['dermatologist_name'] ?? "";
          specController.text = response['dermatologist_specialization'] ?? "";
          expController.text =
              response['dermatologist_experience']?.toString() ?? "";
          photo = response['dermatologist_photo'];
          existingProofUrl = response['dermatologist_proof'];

          if (existingProofUrl != null && existingProofUrl!.isNotEmpty) {
            proofController.text = existingProofUrl!.split('/').last;
          }
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  Future<void> updateProfile() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) throw Exception("User not authenticated");

      String? finalPhotoUrl = photo;
      String? finalProofUrl = existingProofUrl;

      // 1. Image upload processing
      if (imageBytes != null) {
        final uploadedPhoto = await photoUpload(uid);
        if (uploadedPhoto != null) {
          finalPhotoUrl = uploadedPhoto; // Only update if upload succeeded
        } else {
          throw Exception("Image upload failed");
        }
      }

      // 2. Proof upload processing
      if (proofBytes != null) {
        final uploadedProof = await proofUpload(uid);
        if (uploadedProof != null) {
          finalProofUrl = uploadedProof;
        } else {
          throw Exception("Proof document upload failed");
        }
      }

      // 3. Prepared database update payload
      final Map<String, dynamic> updates = {
        'dermatologist_name': nameController.text.trim(),
        'dermatologist_specialization': specController.text.trim(),
        'dermatologist_experience': expController.text.trim(),
        'dermatologist_photo': finalPhotoUrl,
        'dermatologist_proof': finalProofUrl,
      };

      await supabase
          .from('tbl_dermatologist')
          .update(updates)
          .eq('dermatologist_id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Update Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to update profile: ${e.toString().replaceAll("Exception: ", "")}",
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- File Pickers & Uploaders remain same ---
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

  Future<void> handleProofPick() async {
    final result = await file_picker.FilePicker.pickFiles(
      type: file_picker.FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      withData: true,
    );
    if (result == null) return;
    setState(() {
      pickedProof = result.files.first;
      proofBytes = pickedProof!.bytes;
      proofController.text = pickedProof!.name;
    });
  }

  Future<String?> photoUpload(String uid) async {
    try {
      final filePath = "profile/$uid.${pickedImage!.extension}";
      await supabase.storage
          .from('Dermatologist')
          .uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      // Grab the raw public URL
      final rawUrl = supabase.storage
          .from('Dermatologist')
          .getPublicUrl(filePath);

      // Append a unique cache-busting timestamp (e.g., ?v=1716492345)
      final bustCacheUrl = "$rawUrl?v=${DateTime.now().millisecondsSinceEpoch}";
      return bustCacheUrl;
    } catch (e) {
      debugPrint("Photo Upload Storage Error: $e");
      return null;
    }
  }

  Future<String?> proofUpload(String uid) async {
    try {
      final filePath = "proof/$uid.${pickedProof!.extension}";
      String cType = pickedProof!.extension == 'pdf'
          ? 'application/pdf'
          : 'image/jpeg';
      await supabase.storage
          .from('Dermatologist')
          .uploadBinary(
            filePath,
            proofBytes!,
            fileOptions: FileOptions(upsert: true, contentType: cType),
          );
      return supabase.storage.from('Dermatologist').getPublicUrl(filePath);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: handleImagePick,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: const Color(0xFF161B22),
                              backgroundImage: imageBytes != null
                                  ? MemoryImage(imageBytes!)
                                  : (photo != null
                                            ? NetworkImage(photo!)
                                            : null)
                                        as ImageProvider?,
                              child: (imageBytes == null && photo == null)
                                  ? const Icon(
                                      Icons.person,
                                      size: 70,
                                      color: Colors.white24,
                                    )
                                  : null,
                            ),
                            const CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              radius: 20,
                              child: Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Column(
                          children: [
                            _buildTextField(
                              'Full Name',
                              Icons.person_outline,
                              nameController,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              'Specialization',
                              Icons.medication_outlined,
                              specController,
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              'Experience',
                              Icons.history_edu_outlined,
                              expController,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                            _buildProofField(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildSubmitButton(),
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

  Widget _buildProofField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "  Proof Document",
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: proofController,
          readOnly: true,
          onTap: handleProofPick,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.file_present,
              color: Colors.blueAccent,
            ),
            suffixIcon: (existingProofUrl != null && proofBytes == null)
                ? IconButton(
                    icon: const Icon(
                      Icons.open_in_new,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    onPressed: () => launchUrl(
                      Uri.parse(existingProofUrl!),
                      mode: LaunchMode.externalApplication,
                    ),
                  )
                : null,
            hintText: 'Upload Proof',
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : updateProfile,
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4facfe), Color(0xFF00f2fe)],
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Save Changes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
            filled: true,
            fillColor: Colors.black.withOpacity(0.4),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.blueAccent),
            ),
          ),
        ),
      ],
    );
  }
}
