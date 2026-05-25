import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/main.dart';
import 'package:user_app/order_details.dart';
import 'package:user_app/user_homepage.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _allBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_booking')
          .select('*, tbl_cart(*, tbl_product(*, tbl_gallery(gallery_file)))')
          .eq('user_id', user.id)
          .neq('booking_status', 0)
          .order('booking_date', ascending: false);

      if (mounted) {
        setState(() {
          _allBookings = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Orders Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'My Orders',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _buildCircleBtn(Icons.arrow_back_ios_new, () {
          // Check if there's a valid history stack to slide back to safely
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // If we arrived from a success page loop, flush the stack and establish HomeScreen as root
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const UserHomePage()),
              (route) => false,
            );
          }
        }),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8E71FF),
          labelColor: const Color(0xFF8E71FF),
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: "Current"),
            Tab(text: "Refund"),
            Tab(text: "History"),
          ],
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E71FF)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrderList(isHistory: false),
                _buildRefundDummyState(),
                _buildOrderList(isHistory: true),
              ],
            ),
    );
  }

  Widget _buildOrderList({required bool isHistory}) {
    final filtered = _allBookings.where((o) {
      int status = int.tryParse(o['booking_status'].toString()) ?? 0;
      return isHistory ? status >= 4 : (status >= 1 && status < 4);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        isHistory ? "No history found" : "No active orders",
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final booking = filtered[index];
        final cardWidget = _buildOrderCard(booking);

        // If it's the history tab, wrap it with a GestureDetector to make it clickable
        if (isHistory) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(booking: booking),
                ),
              );
            },
            child: cardWidget,
          );
        }

        return cardWidget;
      },
    );
  }

  Widget _buildRefundDummyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          Text(
            "No refund requests found",
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> booking) {
    final List cartItems = booking['tbl_cart'] ?? [];
    final int status = int.tryParse(booking['booking_status'].toString()) ?? 0;
    final String date = booking['booking_date'].toString().split('T')[0];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "#ORD-${booking['booking_id']}",
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 15),

          ...cartItems.map((item) {
            final product = item['tbl_product'] ?? {};
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _buildProductImage(product),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product['product_name'] ?? 'Product',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Qty: ${item['cart_quantity']}",
                          style: GoogleFonts.outfit(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${product['product_price']}",
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(color: Colors.white10, height: 30),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
              ),
              Text(
                "₹${booking['booking_amount']}",
                style: GoogleFonts.outfit(
                  color: const Color(0xFF8E71FF),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildShippingTimeline(status),
        ],
      ),
    );
  }

  Widget _buildShippingTimeline(int status) {
    return Row(
      children: [
        _buildStep(Icons.check_circle, "Placed", status >= 1),
        _buildLine(status >= 2),
        _buildStep(Icons.payment, "Paid", status >= 2),
        _buildLine(status >= 3),
        _buildStep(Icons.local_shipping, "Shipped", status >= 3),
        _buildLine(status >= 4),
        _buildStep(Icons.home, "Delivered", status >= 4),
      ],
    );
  }

  Widget _buildStep(IconData icon, String label, bool isDone) {
    return Column(
      children: [
        Icon(
          icon,
          color: isDone ? const Color(0xFF8E71FF) : Colors.white12,
          size: 18,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            color: isDone ? Colors.white70 : Colors.white12,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isDone
            ? const Color(0xFF8E71FF).withOpacity(0.5)
            : Colors.white12,
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    final String? url = product['product_photo'];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        width: 50,
        color: const Color(0xFF0A0E14),
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.white12,
                  size: 20,
                ),
              )
            : const Icon(
                Icons.shopping_bag_outlined,
                color: Colors.white12,
                size: 20,
              ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.05),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleBtn(IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: CircleAvatar(
        backgroundColor: const Color(0xFF161B22),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: const Color(0xFF8E71FF), size: 18),
        ),
      ),
    );
  }
}

// --- Dummy Destination Page ---
// class OrderDetailsScreen extends StatelessWidget {
//   final Map<String, dynamic> booking;

//   const OrderDetailsScreen({super.key, required this.booking});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0E14),
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Text('Order Details', style: GoogleFonts.outfit(color: Colors.white)),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8E71FF)),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Center(
//         child: Text(
//           "Details for Order #${booking['booking_id']}",
//           style: GoogleFonts.outfit(color: Colors.white, fontSize: 18),
//         ),
//       ),
//     );
//   }
// }
