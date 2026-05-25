import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/main.dart';
import 'package:user_app/welcome.dart';

class Registration extends StatefulWidget {
  const Registration({super.key});

  @override
  State<Registration> createState() => _RegistrationState();
}

class _RegistrationState extends State<Registration> {
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpasswordController = TextEditingController();

  String? _gender;
  List<Map<String, dynamic>> _skinTypes = [];
  String? _selectedSkinType;
  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;

  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _allPlaces = [];
  List<Map<String, dynamic>> _filteredPlaces = [];
  String? _selectedDistrictId;
  String? _selectedPlaceName;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _fetchSkinTypes();
    _fetchLocationData();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmpasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchSkinTypes() async {
    try {
      final response = await supabase.from('tbl_type').select();
      setState(() {
        _skinTypes = (response as List)
            .map(
              (item) => {
                'type_name': item['type_name'] as String,
                'type_id': item['type_id'] as int,
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching skin types: $e");
    }
  }

  Future<void> _fetchLocationData() async {
    try {
      final districtResponse = await supabase.from('tbl_district').select();
      final placeResponse = await supabase.from('tbl_place').select();

      setState(() {
        _districts = (districtResponse as List)
            .map(
              (item) => {
                'district_id': item['district_id'].toString(),
                'district_name': item['district_name'] as String,
              },
            )
            .toList();

        _allPlaces = (placeResponse as List)
            .map(
              (item) => {
                'place_id': item['place_id'].toString(),
                'place_name': item['place_name'] as String,
                'district_id': item['district_id'].toString(),
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint("Error fetching locations: $e");
    }
  }

  void _onDistrictChanged(String? districtId) {
    setState(() {
      _selectedDistrictId = districtId;
      _selectedPlaceName = null;
      if (districtId != null) {
        _filteredPlaces = _allPlaces
            .where((place) => place['district_id'] == districtId)
            .toList();
      } else {
        _filteredPlaces = [];
      }
    });
  }

  Future<void> insert() async {
    setState(() {
      _submitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar("Please fix the errors in red before proceeding");
      return;
    }

    if (imageBytes == null || _gender == null) {
      _showErrorSnackBar("Please fill out all missing profile details");
      return;
    }

    // 2. SHOW A LOADING INDICATOR TO PREVENT MULTIPLE TAPS
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8E71FF)),
      ),
    );

    try {
      final email = emailController.text.trim();
      final name = nameController.text.trim();
      final contact = phoneController.text.trim();
      final password = passwordController.text;

      // Create authentication instance entry
      final authResponse = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      final String? uid = authResponse.user?.id;

      if (uid == null) {
        throw Exception("User registration failed.");
      }

      String? profileImageUrl = await photoUpload(uid);
      
      // Insert profile metadata into custom DB table
      await supabase.from('tbl_user').insert({
        'user_id': uid,
        'user_email': email,
        'user_name': name,
        'user_password': password,
        'user_contact': contact,
        'user_address': _selectedPlaceName,
        'user_gender': _gender,
        'type_id': _selectedSkinType,
        'user_photo': profileImageUrl,
        'user_status': 'pending', // Matches your verification design flow
      });

      // 3. LOG OUT IMMEDIATELY AFTER SIGN UP
      // Supabase auto-logs users in on signUp by default. We close the session here
      // to keep them in a true unapproved status.
      await supabase.auth.signOut();

      if (!mounted) return;
      Navigator.pop(context); // Close the loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration complete! Please await verification approval."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Reset state completely
      emailController.clear();
      passwordController.clear();
      nameController.clear();
      phoneController.clear();
      confirmpasswordController.clear();
      
      setState(() {
        _selectedDistrictId = null;
        _selectedPlaceName = null;
        _selectedSkinType = null;
        _gender = null;
        imageBytes = null;
        _submitted = false;
      });

      // 4. ROUTE CLEANLY BACK TO WELCOME SCREEN & OVERWRITE NAVIGATION STACK
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Welcome()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading indicator dialog on catch exception
      _showErrorSnackBar("Error: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result = await file_picker.FilePicker.pickFiles(
        type: file_picker.FileType.image, withData: true);

    if (result == null) return;
    setState(() {
      pickedImage = result.files.first;
      imageBytes = pickedImage!.bytes;
    });
  }

  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;
      const bucketName = 'User';
      final filePath = "profile/$uid.${pickedImage!.extension}";

      await supabase.storage.from(bucketName).uploadBinary(
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

  Widget _buildInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'This field is required';
        }
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF8E71FF), size: 20),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        errorStyle: const TextStyle(color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF8E71FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildGenderSection() {
    final bool isInvalid = _submitted && _gender == null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isInvalid ? Colors.redAccent : Colors.transparent,
          width: isInvalid ? 1.5 : 0,
        ),
        color: isInvalid ? Colors.redAccent.withOpacity(0.05) : Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "  Gender",
            style: TextStyle(
              color: isInvalid ? Colors.redAccent : Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Male', 'Female', 'Other']
                .map(
                  (g) => Row(
                    children: [
                      Text(
                        g,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                      Radio<String>(
                        value: g,
                        groupValue: _gender,
                        activeColor: const Color(0xFF8E71FF),
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkinTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSkinType,
      dropdownColor: const Color(0xFF161B22),
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null ? 'Please select a skin type' : null,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.opacity, color: Color(0xFF8E71FF), size: 20),
        labelText: "Skin Type",
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        errorStyle: const TextStyle(color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      items: _skinTypes
          .map((type) => DropdownMenuItem(
                value: type['type_id'].toString(),
                child: Text(type['type_name']),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedSkinType = v),
    );
  }

  Widget _buildDistrictDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDistrictId,
      dropdownColor: const Color(0xFF161B22),
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null ? 'Please select a district' : null,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.map_outlined, color: Color(0xFF8E71FF), size: 20),
        labelText: "District",
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        errorStyle: const TextStyle(color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF8E71FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      items: _districts
          .map<DropdownMenuItem<String>>((dist) => DropdownMenuItem<String>(
                value: dist['district_id']?.toString(),
                child: Text(dist['district_name']?.toString() ?? ''),
              ))
          .toList(),
      onChanged: _onDistrictChanged,
    );
  }

  Widget _buildPlaceDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPlaceName,
      dropdownColor: const Color(0xFF161B22),
      style: const TextStyle(color: Colors.white),
      validator: (v) => v == null ? 'Please select a location place' : null,
      disabledHint: Text(
        "Select a district first",
        style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 14),
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.location_on_outlined, color: Color(0xFF8E71FF), size: 20),
        labelText: "Place",
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        errorStyle: const TextStyle(color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF8E71FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
      items: _filteredPlaces
          .map<DropdownMenuItem<String>>((pl) => DropdownMenuItem<String>(
                value: pl['place_name']?.toString(),
                child: Text(pl['place_name']?.toString() ?? ''),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedPlaceName = v),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password cannot be empty';
        if (value.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF8E71FF), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF8E71FF).withOpacity(0.6),
            size: 20,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        errorStyle: const TextStyle(color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF8E71FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: confirmpasswordController,
      obscureText: _obscureConfirmPassword,
      style: const TextStyle(color: Colors.white),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please retype your password';
        if (value != passwordController.text) return 'Passwords do not match';
        return null;
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.check_circle_outline, color: Color(0xFF8E71FF), size: 20),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: const Color(0xFF8E71FF).withOpacity(0.6),
            size: 20,
          ),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        labelText: 'Confirm Password',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
        filled: true,
        fillColor: Colors.black.withOpacity(0.2),
        errorStyle: const TextStyle(color: Colors.redAccent),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF8E71FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isImageInvalid = _submitted && imageBytes == null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E14),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      'Create Account',
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Form(
                    key: _formKey,
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
                                          color: isImageInvalid ? Colors.redAccent : const Color(0xFF8E71FF),
                                          width: 2.5,
                                        ),
                                        color: Colors.black,
                                        image: imageBytes != null
                                            ? DecorationImage(
                                                image: MemoryImage(imageBytes!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: imageBytes == null
                                          ? Icon(
                                              Icons.camera_alt_outlined,
                                              color: isImageInvalid ? Colors.redAccent : Colors.white24,
                                              size: 36,
                                            )
                                          : null,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: isImageInvalid ? Colors.redAccent : const Color(0xFF8E71FF),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.add_a_photo,
                                        size: 14,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildInput(nameController, 'Full Name', Icons.person_outline),
                              const SizedBox(height: 15),
                              _buildInput(
                                emailController,
                                'Email',
                                Icons.mail_outline,
                                type: TextInputType.emailAddress,
                              ),
                              const SizedBox(height: 15),
                              _buildGenderSection(),
                              const SizedBox(height: 15),
                              _buildInput(
                                phoneController,
                                'Phone',
                                Icons.phone_android_outlined,
                                type: TextInputType.phone,
                              ),
                              const SizedBox(height: 15),
                              _buildSkinTypeDropdown(),
                              const SizedBox(height: 15),
                              _buildDistrictDropdown(),
                              const SizedBox(height: 15),
                              _buildPlaceDropdown(),
                              const SizedBox(height: 15),
                              _buildPasswordField(),
                              const SizedBox(height: 15),
                              _buildConfirmPasswordField(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        GestureDetector(
                          onTap: insert,
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
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}