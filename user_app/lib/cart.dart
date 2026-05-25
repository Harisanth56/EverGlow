import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/main.dart'; // Ensure this contains your supabase instance
import 'package:user_app/navigator.dart';
import 'package:user_app/payment.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cartItems = [];
  double _grandTotal = 0; // From 222.txt

  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  /// Fetch data based on tbl_cart and tbl_booking
  Future<void> fetchCartData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final bookingResponse = await supabase
          .from('tbl_booking')
          .select('booking_id')
          .eq('user_id', user.id)
          .eq('booking_status', 0) // 0 = Pending/In-cart
          .maybeSingle();

      if (bookingResponse == null) {
        if (mounted)
          setState(() {
            _cartItems = [];
            _isLoading = false;
          });
        return;
      }

      final bookingId = bookingResponse['booking_id'];

      final response = await supabase
          .from('tbl_cart')
          .select(
            'cart_id, booking_id, product_id, cart_quantity, cart_status, tbl_product(*)',
          )
          .eq('booking_id', bookingId);

      if (mounted) {
        setState(() {
          _cartItems = List<Map<String, dynamic>>.from(response);
          _calcTotal();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Calculate totals dynamically
  void _calcTotal() {
    _grandTotal = _cartItems.fold(0.0, (sum, item) {
      final price =
          (item['tbl_product']['product_price'] as num?)?.toDouble() ?? 0;
      final qty = item['cart_quantity'] ?? 0;
      return sum + (price * qty);
    });
  }

  /// Update cart_quantity in database
  /// Update cart_quantity in database with strict stock validation
  Future<void> updateQty(int index, int delta) async {
    final cartItem = _cartItems[index];
    final cartId = cartItem['cart_id'];
    final productId =
        cartItem['product_id']; // Ensure product_id is selected in fetchCartData
    final currentCartQty = cartItem['cart_quantity'] ?? 0;
    final newQty = currentCartQty + delta;

    // 1. Handle item removal if quantity falls below 1
    if (newQty < 1) {
      removeItem(cartId, index);
      return;
    }

    // 2. Only validate stock if the user is trying to INCREMENT (+) the quantity
    if (delta > 0) {
      try {
        // Fetch total stock counts for this specific product
        final stockResponse = await supabase
            .from('tbl_stock')
            .select('stock_count')
            .eq('product_id', productId);

        final int totalStock =
            (stockResponse as List<dynamic>?)?.fold<int>(
              0,
              (total, item) => total + (item['stock_count'] as int? ?? 0),
            ) ??
            0;

        // Fetch what OTHER users (or this user) have locked in placed orders (cart_status = 2)
        // If you also want to count pending items in other people's carts, adjust the eq() filters here
        final globalCartResponse = await supabase
            .from('tbl_cart')
            .select('cart_quantity')
            .eq('product_id', productId)
            .eq('cart_status', 2);

        final int globalOrderedQty =
            (globalCartResponse as List<dynamic>?)?.fold<int>(
              0,
              (total, item) => total + (item['cart_quantity'] as int? ?? 0),
            ) ??
            0;

        // Available Physical Stock = Total Stock - Already Sold/Ordered Quantities
        final int availableStock = totalStock - globalOrderedQty;

        // Block increment if it exceeds available inventory
        if (newQty > availableStock) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Cannot add more. Only $availableStock items left in stock!",
                ),
                backgroundColor: Colors.orangeAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return; // Halt execution here
        }
      } catch (e) {
        debugPrint("Stock Validation Error: $e");
        return;
      }
    }

    // 3. Database Update if validation passes
    try {
      await supabase
          .from('tbl_cart')
          .update({'cart_quantity': newQty})
          .eq('cart_id', cartId);
      fetchCartData();
    } catch (e) {
      debugPrint("Update Error: $e");
    }
  }

  /// Delete item from cart
  Future<void> removeItem(int cartId, int index) async {
    try {
      await supabase.from('tbl_cart').delete().eq('cart_id', cartId);
      fetchCartData();
    } catch (e) {
      debugPrint("Delete Error: $e");
    }
  }

  /// Clear All functionality from 222.txt
  Future<void> clearAll() async {
    for (int i = _cartItems.length - 1; i >= 0; i--) {
      await removeItem(_cartItems[i]['cart_id'], i);
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
          'My Cart',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: _buildCircleBtn(Icons.arrow_back_ios_new, () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // Instead of destroying the stack, cleanly replace it or push standardly
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const IndexPage()),
            );
          }
        }),
        actions: [
          if (_cartItems.isNotEmpty)
            TextButton(
              onPressed: clearAll,
              child: Text(
                "Clear All",
                style: GoogleFonts.outfit(
                  color: Colors.redAccent,
                  fontSize: 13,
                ),
              ),
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E71FF)),
            )
          : Column(
              children: [
                Expanded(
                  child: _cartItems.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) =>
                              _buildCartCard(_cartItems[index], index),
                        ),
                ),
                if (_cartItems.isNotEmpty) _buildSummarySection(),
              ],
            ),
    );
  }

  Widget _buildCartCard(Map<String, dynamic> item, int index) {
    final product = item['tbl_product'];
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22), // UI from 111.txt
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 85,
              width: 85,
              color: const Color(0xFF0A0E14),
              child: product['product_photo'] != null
                  ? Image.network(product['product_photo'], fit: BoxFit.cover)
                  : const Icon(Icons.spa_outlined, color: Colors.white10),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['product_name'],
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "₹${product['product_price']}",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF8E71FF),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          _buildQtyControls(item, index),
          IconButton(
            onPressed: () => removeItem(item['cart_id'], index),
            icon: const Icon(
              Icons.delete_outline,
              color: Colors.redAccent,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQtyControls(Map<String, dynamic> item, int index) {
    int currentQty = item['cart_quantity'] ?? 1;
    return Column(
      children: [
        _qtyBtn(Icons.add, () => updateQty(index, 1)),
        Text(
          "$currentQty",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        _qtyBtn(Icons.remove, () => updateQty(index, -1)),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF161B22), // UI from 111.txt
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _row("Total Items", "${_cartItems.length}", false),
            const Divider(color: Colors.white10, height: 30),
            _row("Total Amount", "₹${_grandTotal.toStringAsFixed(0)}", true),
            const SizedBox(height: 20),
            _checkoutBtn(),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, String val, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: isBold ? Colors.white : Colors.white54,
            fontSize: isBold ? 18 : 14,
          ),
        ),
        Text(
          val,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: isBold ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Checkout functionality navigating to payment
  Widget _checkoutBtn() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentGatewayScreen(
              id: _cartItems[0]['booking_id'],
              amt: _grandTotal.toInt(),
            ),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8E71FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Text(
          "PAY ₹${_grandTotal.toStringAsFixed(0)} →",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 20),
          Text(
            "Your cart is empty",
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 18),
          ),
        ],
      ),
    );
  }
}
