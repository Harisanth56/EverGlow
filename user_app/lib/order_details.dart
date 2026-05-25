import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/rating.dart'; 

class OrderDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const OrderDetailsScreen({super.key, required this.booking});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  Set<String> _ratedProductIds = {};
  bool _checkingRatings = true;

  @override
  void initState() {
    super.initState();
    _checkExistingReviews();
  }

  Future<void> _checkExistingReviews() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final List cartItems = widget.booking['tbl_cart'] ?? [];
      if (cartItems.isEmpty) return;

      List<String> productIds = cartItems
          .map((item) => (item['tbl_product']?['product_id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      if (productIds.isEmpty) return;

      final response = await supabase
          .from('tbl_rating')
          .select('product_id')
          .eq('user_id', user.id)
          .inFilter('product_id', productIds);

      final List data = response as List;
      
      if (mounted) {
        setState(() {
          _ratedProductIds = data.map((row) => row['product_id'].toString()).toSet();
          _checkingRatings = false;
        });
      }
    } catch (e) {
      debugPrint("Error checking reviews: $e");
      if (mounted) {
        setState(() => _checkingRatings = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List cartItems = widget.booking['tbl_cart'] ?? [];
    final String date = widget.booking['booking_date'].toString().split('T')[0];

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Order Details', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF161B22),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF8E71FF), size: 18),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Order ID", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text("#ORD-${widget.booking['booking_id']}", 
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("Delivered On", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(date, style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            Text("Items Ordered", style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                final product = item['tbl_product'] ?? {};
                final String productId = (product['product_id'] ?? '').toString();
                
                // Instead of blocking, we evaluate if this is an update state layout
                final bool isAlreadyRated = _ratedProductIds.contains(productId);

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B22),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.03)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _buildProductImage(product),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['product_name'] ?? 'Product', 
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text("Quantity: ${item['cart_quantity']}", 
                                  style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text("₹${product['product_price']}", 
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      
                      const Divider(color: Colors.white10, height: 25),
                      
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: _checkingRatings
                            ? Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: const Color(0xFF8E71FF).withOpacity(0.5),
                                  ),
                                ),
                              )
                            : TextButton.icon(
                                onPressed: () async {
                                  // Always clickable now! Passes a flag if it's an update scenario
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductRatingScreen(
                                        product: product,
                                        isUpdating: isAlreadyRated,
                                      ),
                                    ),
                                  );
                                  setState(() => _checkingRatings = true);
                                  _checkExistingReviews();
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: isAlreadyRated
                                      ? const Color(0xFF8E71FF).withOpacity(0.04)
                                      : const Color(0xFF8E71FF).withOpacity(0.1),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: const BorderSide(
                                      color: Color(0xFF8E71FF), 
                                      width: 1,
                                    ),
                                  ),
                                ),
                                icon: Icon(
                                  isAlreadyRated ? Icons.published_with_changes_rounded : Icons.star_rate_rounded, 
                                  color: const Color(0xFF8E71FF), 
                                  size: 18,
                                ),
                                label: Text(
                                  isAlreadyRated ? "Update Your Review" : "Rate This Product",
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF8E71FF), 
                                    fontSize: 14, 
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
            const Divider(color: Colors.white10, height: 1),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Payment Amount", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
                Text("₹${widget.booking['booking_amount']}", 
                  style: GoogleFonts.outfit(color: const Color(0xFF8E71FF), fontSize: 20, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Map<String, dynamic> product) {
    final String? url = product['product_photo'];
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 55,
        width: 55,
        color: const Color(0xFF0A0E14),
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                    const Icon(Icons.broken_image, color: Colors.white12, size: 22),
              )
            : const Icon(Icons.shopping_bag_outlined, color: Colors.white12, size: 22),
      ),
    );
  }
}