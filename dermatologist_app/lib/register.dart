import 'package:dermatologist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart' as file_picker;

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  // Controllers
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmpasswordController = TextEditingController();
  final specializationController = TextEditingController();
  final experienceController = TextEditingController();
  final photoController = TextEditingController();
  final proofController = TextEditingController();

  bool isPasswordVisible = false;

  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;
  file_picker.PlatformFile? pickedProof;
  Uint8List? proofBytes;

  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result = await file_picker
        .FilePicker.pickFiles(type: file_picker.FileType.image, withData: true);

    if (result == null) return;

    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;

    setState(() {});
  }

  Future<void> handleProofPick() async {
    file_picker.FilePickerResult? result =
        await file_picker.FilePicker.pickFiles(
          type: file_picker.FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: true,
        );

    if (result == null) return;

    setState(() {
      pickedProof = result.files.first;
      proofBytes = pickedProof!.bytes;
      // Update the text field with the picked file name
      proofController.text = pickedProof!.name;
    });
  }
  Future<String?> proofUpload(String uid) async {
    try {
      if (proofBytes == null) return null;

      const bucketName = 'Dermatologist';
      // Saves to a distinct folder: proof/uid.extension
      final filePath = "proof/$uid.${pickedProof!.extension}";

      // Set the content type dynamically based on the file extension
      String contentType = 'image/jpeg';
      if (pickedProof!.extension == 'pdf') {
        contentType = 'application/pdf';
      } else if (pickedProof!.extension == 'png') {
        contentType = 'image/png';
      }

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            proofBytes!,
            fileOptions: FileOptions(
              upsert: true,
              contentType: contentType,
            ),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Proof upload error: ${e.toString()}");
      return null;
    }
  }

  /// PHOTO UPLOAD
  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;

      const bucketName = 'Dermatologist';
      final filePath = "profile/$uid.${pickedImage!.extension}";

      await supabase.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    // Clean up controllers
    emailController.dispose();
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    specializationController.dispose();
    experienceController.dispose();
    photoController.dispose();
    proofController.dispose();
    super.dispose();
  }

  Future<void> insert() async {
  try {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final experience = experienceController.text.trim();
    final password = passwordController.text;
    final cpass = confirmpasswordController.text;
    final specialization = specializationController.text.trim();

    // Basic validation
    if (email.isEmpty || name.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (password != cpass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password mismatched"),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    // 1. Sign up the user in Supabase Auth
    final authResponse = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final String? uid = authResponse.user?.id;

    if (uid == null) {
      throw Exception("User registration failed.");
    }

    // 2. Upload assets using the UID
    String? profileImageUrl = await photoUpload(uid);
    String? proofUrl = await proofUpload(uid);

    // 3. Insert into database
    await supabase.from('tbl_dermatologist').insert({
      'dermatologist_id': uid, // Good practice to link Auth ID to your table
      'dermatologist_email': email,
      'dermatologist_name': name,
      'dermatologist_password': password, 
      'dermatologist_experience': experience,
      'dermatologist_specialization': specialization,
      'dermatologist_photo': profileImageUrl,
      'dermatologist_proof': proofUrl,
      'dermatologist_status':'pending',
    });

    // CRITICAL CHECK: Ensure the user hasn't closed the screen during awaits
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Registration completed"),
        backgroundColor: Colors.black,
      ),
    );

    // Clear fields
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    confirmpasswordController.clear();
    specializationController.clear();
    experienceController.clear();
    
    print("Registration completed");
  } catch (e) {
    print("Error: $e");

    // CRITICAL CHECK for the catch block as well
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.black, // Midnight Base
          body: SafeArea(
            child: Column(
              children: [
                /// HEADER
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E1E1E), // Midnight Grey Container
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(40),
                      ),
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: handleImagePick,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  height: 110,
                                  width: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Color(0xFF8E71FF),
                                      width: 2,
                                    ),
                                    gradient: imageBytes == null
                                        ? LinearGradient(
                                            colors: [
                                              Colors.black,
                                              Colors.black,
                                            ],
                                          )
                                        : null,
                                    image: imageBytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(imageBytes!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: imageBytes == null
                                      ? const Icon(
                                          Icons.camera_alt,
                                          color: Colors.black,
                                          size: 40,
                                        )
                                      : null,
                                ),

                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF8E71FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildMidnightField(
                            'Full Name',
                            Icons.person_outline,
                            nameController,
                          ),
                          const SizedBox(height: 20),
                          _buildMidnightField(
                            'Email Address',
                            Icons.mail_outline,
                            emailController,
                            type: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 20),
                          _buildMidnightField(
                            'Specialization',
                            Icons.medication_outlined,
                            specializationController,
                          ),
                          const SizedBox(height: 20),
                          _buildMidnightField(
                            'Experience',
                            Icons.history_edu_outlined,
                            experienceController,
                          ),
                          const SizedBox(height: 20),

                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: TextFormField(
                              controller: proofController,
                              readOnly: true,
                              onTap: () {
                                handleProofPick(); // Triggers proof picker
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please upload a proof document';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  Icons.attach_file_sharp,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                hintText: 'Upload Proof',
                                hintStyle: const TextStyle(
                                  color: Colors.white24,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.3),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.white10,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: const BorderSide(
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // _buildMidnightField(
                          //   'Medical Proof URL',
                          //   Icons.file_present_outlined,
                          //   proofController,
                          // ),
                          const SizedBox(height: 20),
                          _buildMidnightField(
                            'Phone Number',
                            Icons.phone_android_outlined,
                            phoneController,
                            type: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),
                          _buildMidnightField(
                            'Address',
                            Icons.location_on_outlined,
                            addressController,
                            maxLines: 2,
                          ),
                          const SizedBox(height: 20),
                          _buildMidnightField(
                            'Password',
                            Icons.lock_outline,
                            passwordController,
                            isPassword: true,
                          ),
                          const SizedBox(height: 20),
                          _buildMidnightField(
                            'Confirm Password',
                            Icons.lock_reset_outlined,
                            confirmpasswordController,
                            isPassword: true,
                          ),
                          const SizedBox(height: 40),

                          /// REGISTER BUTTON
                          GestureDetector(
                            onTap: insert,
                            child: Container(
                              height: 60,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4facfe),
                                    Color(0xFF00f2fe),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blueAccent.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Register Now',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Midnight Field Builder
  Widget _buildMidnightField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
    TextInputType type = TextInputType.text,
    int maxLines = 1,
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
          maxLines: maxLines,
          keyboardType: type,
          obscureText: isPassword ? !isPasswordVisible : false,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => isPasswordVisible = !isPasswordVisible),
                  )
                : null,
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            filled: true,
            fillColor: Colors.black.withOpacity(0.3),
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
