import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/cart.dart';
import 'package:user_app/main.dart'; 
import 'package:user_app/poduct_detail.dart';

class ProductGridScreen extends StatefulWidget {
  const ProductGridScreen({super.key});

  @override
  State<ProductGridScreen> createState() => _ProductGridScreenState();
}

class _ProductGridScreenState extends State<ProductGridScreen> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  int cartItemCount = 0;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    int count = await fetchCartItemCount();
    if (mounted) {
      setState(() {
        cartItemCount = count;
      });
    }
  }

  void checkCartStatus() {
    if (cartItemCount > 0) {
      print("User has items in the cart!");
    }
  }

  Future<int> fetchCartItemCount() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 0;

      final activeBooking = await supabase
          .from('tbl_booking')
          .select('booking_id')
          .eq('user_id', user.id)
          .eq('booking_status', 0)
          .maybeSingle();

      if (activeBooking == null) return 0;

      final int bookingId = activeBooking['booking_id'];
      final cartResponse = await supabase
          .from('tbl_cart')
          .select('cart_quantity')
          .eq('booking_id', bookingId);

      final List cartList = cartResponse as List;
      
      final int totalCount = cartList.fold<int>(
        0,
        (sum, item) => sum + (int.tryParse(item['cart_quantity'].toString()) ?? 0),
      );
      return totalCount;
    } catch (e) {
      debugPrint("Error fetching cart count: $e");
      return 0;
    }
  }

  Future<void> fetchProducts() async {
    try {
      final response = await supabase.from('tbl_product').select('''
          *, 
          tbl_category(category_name), 
          tbl_type(type_name), 
          tbl_heatabsorption(heatabsorption_name)
        ''');
      if (mounted) {
        setState(() {
          products = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _addToCart(BuildContext context, Map<String, dynamic> product) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('user_id', user.id)
          .eq('booking_status', 0)
          .maybeSingle();

      int bookingId;
      if (booking != null) {
        bookingId = booking['booking_id'];
        final existing = await supabase
            .from('tbl_cart')
            .select()
            .eq('booking_id', bookingId)
            .eq('product_id', product['product_id'])
            .maybeSingle();

        if (existing != null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Already in cart"),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          return;
        }
      } else {
        final nb = await supabase
            .from('tbl_booking')
            .insert({
              'user_id': user.id,
              'booking_status': 0,
              'booking_amount': 0, 
              'booking_date': DateTime.now().toIso8601String(),
            })
            .select()
            .single();
        bookingId = nb['booking_id'];
      }

      await supabase.from('tbl_cart').insert({
        'booking_id': bookingId,
        'product_id': product['product_id'],
        'cart_quantity': 1,
        'cart_status': 0,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${product['product_name'] ?? 'Product'} added to cart"),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Automatically syncs badge update immediately following addition
      _loadCartCount();
    } catch (e) {
      debugPrint("Cart addition error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearchBar(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8E71FF)))
                  : RefreshIndicator(
                      color: const Color(0xFF8E71FF),
                      onRefresh: fetchProducts,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) => _buildProductCard(context, products[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          const Expanded(
            child: Text(
              'Store',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen())).then((_) {
                    _loadCartCount(); // Refresh badge when returning from Cart screen
                  });
                },
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF8E71FF), shape: BoxShape.circle),
                    child: Text(
                      '$cartItemCount', 
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF161B22),
          hintText: "Search products...",
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final String photoUrl = product['product_photo'] ?? '';
    final String name = product['product_name'] ?? 'Unknown';
    final String price = "₹${product['product_price'] ?? '0'}";
    final String category = product['tbl_category']?['category_name'] ?? "General";

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ProductDetailScreen(product: product)),
      ).then((_) => _loadCartCount()), // Refresh badge count on detail closure exit
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.all(8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A0E14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: photoUrl.isNotEmpty
                          ? Image.network(photoUrl, fit: BoxFit.cover)
                          : const Icon(Icons.image_not_supported, color: Colors.white10),
                    ),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 15,
                    child: GestureDetector(
                      onTap: () {
                        // Calls the cart function, passing context and specific row payload
                        _addToCart(context, product);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8E71FF),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8E71FF).withOpacity(0.3), 
                              blurRadius: 8, 
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF8E71FF), 
                      fontSize: 9, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}