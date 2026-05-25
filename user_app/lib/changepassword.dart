import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/main.dart'; // Ensure this matches your project name

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
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showSnackBar('All fields are required', isError: true);
      return;
    }

    if (newPass.length < 6) {
      _showSnackBar('New password must be at least 6 characters', isError: true);
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

      final response = await supabase
          .from('tbl_user')
          .select('user_password')
          .eq('user_id', user.id)
          .single();

      String dbPassword = response['user_password'] ?? "";

      if (dbPassword != oldPass) {
        _showSnackBar('Incorrect old password', isError: true);
        setState(() => _isUpdating = false);
        return;
      }

      // Update Supabase Auth
      await supabase.auth.updateUser(UserAttributes(password: newPass));

      // Update Local Table
      await supabase
          .from('tbl_user')
          .update({'user_password': newPass})
          .eq('user_id', user.id);

      if (mounted) {
        _showSnackBar('Password updated successfully!');
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

  @override
  Widget build(BuildContext context) {
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
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161B22),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Column(
                          children: [
                            _buildGlassField(
                              label: 'Old Password',
                              hint: 'Enter old password',
                              controller: _oldPassController,
                              icon: Icons.lock_outline,
                              isObscured: _obscureOld,
                              onToggle: () => setState(() => _obscureOld = !_obscureOld),
                            ),
                            const SizedBox(height: 20),
                            _buildGlassField(
                              label: 'New Password',
                              hint: 'Enter new password',
                              controller: _newPassController,
                              icon: Icons.vpn_key_outlined,
                              isObscured: _obscureNew,
                              onToggle: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                            const SizedBox(height: 20),
                            _buildGlassField(
                              label: 'Confirm Password',
                              hint: 'Confirm new password',
                              controller: _confirmPassController,
                              icon: Icons.check_circle_outline,
                              isObscured: _obscureConfirm,
                              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      GestureDetector(
                        onTap: _isUpdating ? null : _handlePasswordUpdate,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
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

  Widget _buildGlassField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    required bool isObscured,
    required VoidCallback onToggle,
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
          obscureText: isObscured, // Updated from hardcoded true
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF8E71FF), size: 20),
            // Added suffix icon to allow toggling visibility
            suffixIcon: IconButton(
              icon: Icon(
                isObscured ? Icons.visibility_off : Icons.visibility,
                color: Colors.white.withOpacity(0.3),
                size: 20,
              ),
              onPressed: onToggle,
            ),
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