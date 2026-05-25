import 'package:flutter/material.dart';
import 'package:admin_app/main.dart'; // Ensure this points to your supabase instance

class OrderStatusPage extends StatefulWidget {
  const OrderStatusPage({super.key});

  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage> {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);

  // Data grouped by Booking ID
  Map<String, List<Map<String, dynamic>>> _groupedPaid = {};
  Map<String, List<Map<String, dynamic>>> _groupedShipped = {};
  Map<String, List<Map<String, dynamic>>> _groupedDelivered = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    setState(() => _isLoading = true);
    // Fetch based on integer status IDs from your DB screenshot
    await _fetchAndGroup(2, (data) => setState(() => _groupedPaid = data));      // 2 = Paid
    await _fetchAndGroup(3, (data) => setState(() => _groupedShipped = data));   // 3 = Shipped
    await _fetchAndGroup(4, (data) => setState(() => _groupedDelivered = data)); // 4 = Delivered
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAndGroup(int statusId, Function(Map<String, List<Map<String, dynamic>>>) updateState) async {
    try {
      final response = await supabase
          .from('tbl_booking')
          .select('''
            booking_id,
            booking_date,
            booking_amount,
            tbl_cart (
              cart_quantity,
              tbl_product (
                product_name,
                product_photo,
                product_price
              )
            )
          ''')
          .eq('booking_status', statusId);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      
      for (var booking in response) {
        final String bId = booking['booking_id'].toString();
        grouped[bId] = List<Map<String, dynamic>>.from(booking['tbl_cart']);
        
        if (grouped[bId]!.isNotEmpty) {
          grouped[bId]![0]['booking_date'] = booking['booking_date'];
          grouped[bId]![0]['total_amount'] = booking['booking_amount'];
        }
      }
      updateState(grouped);
    } catch (e) {
      debugPrint("Fetch Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        body: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              const TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorColor: accentColor,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                tabs: [
                  Tab(text: "Paid"),
                  Tab(text: "Shipped"),
                  Tab(text: "Delivered"), // Renamed from Cancelled
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator(color: accentColor))
                  : TabBarView(
                      children: [
                        _buildBookingList(_groupedPaid, "Paid"),
                        _buildBookingList(_groupedShipped, "Shipped"),
                        _buildBookingList(_groupedDelivered, "Delivered"),
                      ],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 15),
        const Text("Order Management",
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
      ],
    );
  }

  Widget _buildBookingList(Map<String, List<Map<String, dynamic>>> groupedData, String status) {
    if (groupedData.isEmpty) {
      return Center(child: Text("No $status orders found", style: const TextStyle(color: Colors.white24)));
    }

    return ListView(
      children: groupedData.entries.map((entry) {
        return _buildBookingCard(entry.key, entry.value, status);
      }).toList(),
    );
  }

  Widget _buildBookingCard(String bookingId, List<Map<String, dynamic>> cartItems, String status) {
    final meta = cartItems.first;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ORDER #$bookingId", style: const TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
              _buildActionButtons(bookingId, status),
            ],
          ),
          const Divider(color: Colors.white10, height: 40),
          ...cartItems.map((item) {
            final product = item['tbl_product'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: product?['product_photo'] != null 
                        ? Image.network(product!['product_photo'], fit: BoxFit.cover)
                        : const Icon(Icons.shopping_bag_outlined, color: Colors.white12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product?['product_name'] ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text("Qty: ${item['cart_quantity']}", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text("₹${product?['product_price'] ?? '0'}", style: const TextStyle(color: Colors.white70)),
                ],
              ),
            );
          }).toList(),
          const Divider(color: Colors.white10, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Date: ${meta['booking_date'].toString().split('T')[0]}", style: const TextStyle(color: Colors.white24, fontSize: 12)),
              Text("Total Amount: ₹${meta['total_amount']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String id, String status) {
    if (status == "Paid") {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: "Mark Shipped",
            icon: const Icon(Icons.local_shipping_outlined, color: Colors.blueAccent, size: 20),
            onPressed: () => _updateBookingStatus(id, 3), // Status 3 = Shipped
          ),
          IconButton(
            tooltip: "Cancel Order",
            icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
            onPressed: () => _updateBookingStatus(id, 0), // Status 0 = Cancelled
          ),
        ],
      );
    } else if (status == "Shipped") {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.withOpacity(0.2),
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () => _updateBookingStatus(id, 4), // Status 4 = Delivered
        child: const Text("Mark Delivered", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      );
    } else { // Delivered section
      return const Icon(Icons.verified, color: Colors.green, size: 24);
    }
  }

  Future<void> _updateBookingStatus(String id, int newStatusId) async {
    try {
      await supabase.from('tbl_booking').update({'booking_status': newStatusId}).eq('booking_id', id);
      _refreshData();
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }
}