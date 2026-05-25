import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/main.dart';

class ComplaintHistory extends StatefulWidget {
  const ComplaintHistory({super.key});

  @override
  State<ComplaintHistory> createState() => _ComplaintHistoryState();
}

class _ComplaintHistoryState extends State<ComplaintHistory> {
  late Stream<List<Map<String, dynamic>>> _complaintsStream;

  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Hero(
                tag: imageUrl,
                child: InteractiveViewer(
                  // Allows users to pinch and zoom
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser?.id;
    _complaintsStream = supabase
        .from('tbl_complaint')
        .stream(primaryKey: ['complaint_id'])
        .eq('user_id', userId ?? '')
        .order('complaint_date', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF8E71FF),
            size: 22,
          ),
        ),
        title: const Text(
          'My Complaints',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _complaintsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E71FF)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final complaints = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              return _buildComplaintCard(complaints[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> data) {
    final String status = data['complaint_status'] ?? 'Pending';
    final bool isResolved = status.toLowerCase() == 'resolved';
    final String dateStr = data['complaint_date'] ?? '';
    final String formattedDate = dateStr.isNotEmpty
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(dateStr))
        : 'N/A';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW: Status & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isResolved
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: isResolved
                        ? Colors.greenAccent
                        : Colors.orangeAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          /// TITLE
          Text(
            data['complaint_title'] ?? 'No Title',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          /// CONTENT
          Text(
            data['complaint_content'] ?? '',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14,
              height: 1.4,
            ),
          ),

          /// IMAGE PREVIEW (If exists)
          /// IMAGE PREVIEW (If exists)
          if (data['complaint_ss'] != null &&
              data['complaint_ss'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: GestureDetector(
                onTap: () {
                  _showFullImage(context, data['complaint_ss']);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Hero(
                    tag:
                        data['complaint_ss'], // Added Hero for smooth transition
                    child: Image.network(
                      data['complaint_ss'],
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(),
                    ),
                  ),
                ),
              ),
            ),

          /// ADMIN REPLY SECTION
          if (data['complaint_reply'] != null &&
              data['complaint_reply'].toString().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF8E71FF).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF8E71FF).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.reply_rounded,
                        color: Color(0xFF8E71FF),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Admin Reply",
                        style: TextStyle(
                          color: Color(0xFF8E71FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['complaint_reply'],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            )
          else if (isResolved)
            const Padding(
              padding: EdgeInsets.only(top: 15),
              child: Text(
                "This issue has been resolved.",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          Text(
            "No complaints found",
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Go Back",
              style: TextStyle(color: Color(0xFF8E71FF)),
            ),
          ),
        ],
      ),
    );
  }
}
