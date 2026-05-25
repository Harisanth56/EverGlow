import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Reply extends StatefulWidget {
  // Use final fields to store the IDs passed from ViewComplaints
  final String complaintId;
  final String userId;

  const Reply({super.key, required this.complaintId, required this.userId});

  @override
  State<Reply> createState() => _ReplyState();
}

class _ReplyState extends State<Reply> {
  final TextEditingController replyController = TextEditingController();
  bool _isLoading = false;

  // JosKart Dashboard Palette
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);
  static const Color fieldColor = Color(0xFF0D0D0D);

  /// Logic to update the complaint row in Supabase
  Future<void> _sendReply() async {
    if (replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a response")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update the 'complaint_reply' and 'complaint_status' columns
      await Supabase.instance.client
          .from('tbl_complaint')
          .update({
            'complaint_reply': replyController.text.trim(),
            'complaint_status': 'Replied', // Optional: update status
          })
          .eq('complaint_id', widget.complaintId); // Match specific row

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Reply Sent Successfully"),
          backgroundColor: accentColor,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 30),
                _buildReplyCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        const Text(
          "Send Reply",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReplyCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MESSAGE CONTENT",
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: replyController,
            maxLines: 8,
            enabled: !_isLoading,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: fieldColor,
              hintText: "Type your response here...",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: accentColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _sendReply,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      "SEND RESPONSE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}