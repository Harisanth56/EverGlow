import 'package:dermatologist_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePass extends StatefulWidget {
  const ChangePass({super.key});

  @override
  State<ChangePass> createState() => _ChangePassState();
}

class _ChangePassState extends State<ChangePass> {
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _isUpdating = false;

  // 1. Add individual states for password visibility
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handlePasswordUpdate() async {
    // 1. Trim inputs to avoid hidden space errors
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    // 2. Validation Checks
    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar('All fields are required', isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showSnackBar(
        'New password must be at least 6 characters',
        isError: true,
      );
      return;
    }

    if (newPass != confirmPass) {
      _showSnackBar('New passwords do not match', isError: true);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 3. Verify current password from your custom table
      final response = await supabase
          .from('tbl_dermatologist')
          .select('dermatologist_password')
          .eq('dermatologist_id', user.id)
          .single();

      String dbPassword = response['dermatologist_password'] ?? "";

      if (dbPassword != oldPass) {
        _showSnackBar('Incorrect old password', isError: true);
        setState(() => _isUpdating = false);
        return;
      }

      // 4. Update Supabase Auth (The real security layer)
      await supabase.auth.updateUser(UserAttributes(password: newPass));

      // 5. Update your local Table (For your data records)
      await supabase
          .from('tbl_dermatologist')
          .update({'dermatologist_password': newPass})
          .eq('dermatologist_id', user.id);

      // 6. Success Feedback
      if (mounted) {
        _showSnackBar('Password updated successfully!');
        // Small delay so they can read the snackbar before it pops
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      _showSnackBar('An unexpected error occurred', isError: true);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // ... (Keep your _showSnackBar and _handlePasswordUpdate functions the same)

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                /// HEADER SECTION
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
                          size: 24,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Change Password',
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
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        const Icon(
                          Icons.lock_reset_rounded,
                          size: 80,
                          color: Colors.white24,
                        ),
                        const SizedBox(height: 30),

                        /// INPUT CONTAINER
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            children: [
                              // Pass the obscure state and the toggle function
                              _buildPasswordField(
                                'Old Password',
                                _oldPassController,
                                _obscureOld,
                                () =>
                                    setState(() => _obscureOld = !_obscureOld),
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordField(
                                'New Password',
                                _newPassController,
                                _obscureNew,
                                () =>
                                    setState(() => _obscureNew = !_obscureNew),
                              ),
                              const SizedBox(height: 20),
                              _buildPasswordField(
                                'Confirm New Password',
                                _confirmPassController,
                                _obscureConfirm,
                                () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        /// UPDATE BUTTON
                        GestureDetector(
                          onTap: _isUpdating ? null : _handlePasswordUpdate,
                          child: Container(
                            height: 55,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF667eea,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isUpdating
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Update Password',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
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
      ),
    );
  }

  // 2. Modified helper widget to accept obscure state and toggle callback
  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool isObscured,
    VoidCallback onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "  $label",
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isObscured, // Uses the passed state
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.blueAccent,
              size: 20,
            ),
            // Added suffixIcon for the eye button
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                isObscured
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
            ),
            filled: true,
            fillColor: Colors.black.withOpacity(0.4),
            hintText: 'Enter $label',
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: Colors.blueAccent,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
