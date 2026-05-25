import 'package:admin_app/addstock.dart';
import 'package:admin_app/gallery.dart';
import 'package:admin_app/main.dart'; // Ensure this contains your 'supabase' instance
import 'package:flutter/material.dart';

class MyProducts extends StatefulWidget {
  const MyProducts({super.key});

  @override
  State<MyProducts> createState() => _MyProductsState();
}

class _MyProductsState extends State<MyProducts> {
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);

  // 1. Initialize an empty list for products
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  // 2. Fetch Product Function
  Future<void> fetchProducts() async {
    try {
      // Joining with category table to get category name if needed
      final response = await supabase
          .from('tbl_product')
          .select('*, tbl_category(category_name)');
      
      setState(() {
        products = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching products: $e");
      setState(() => isLoading = false);
    }
  }

  // 3. Updated Delete Logic for Supabase
  void showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text("Delete Product", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to remove this item?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final productId = products[index]['product_id'];
              await supabase.from('tbl_product').delete().eq('product_id', productId);
              Navigator.pop(context);
              fetchProducts(); // Refresh list
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    products.isEmpty 
                      ? const Center(child: Text("No products found", style: TextStyle(color: Colors.white54)))
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: products.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 25,
                            crossAxisSpacing: 25,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) => _buildProductCard(index),
                        ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Product Inventory",
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
        ),
        Text(
          "Manage your stock, galleries, and product visibility",
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildProductCard(int index) {
    final product = products[index];
    
    // Mapping DB columns to UI
    final String name = product['product_name'] ?? 'Unknown';
    final String productId = product['product_id']?.toString() ?? '';
    final String price = "₹${product['product_price']}";
    final String photoUrl = product['product_photo'] ?? '';
    // Fetching category name from the joined table
    final String category = product['tbl_category'] != null 
        ? product['tbl_category']['category_name'] 
        : "General";

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: photoUrl.isNotEmpty
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                      )
                    : const Icon(Icons.image_not_supported, color: Colors.white24, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.toUpperCase(),
                  style: const TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildIconButton(Icons.inventory_2_outlined, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => AddStock(productId: productId)));
                    }),
                    _buildIconButton(Icons.collections_outlined, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ProductGallery(productId: productId)));
                    }),
                    _buildIconButton(
                      Icons.delete_outline,
                      () => showDeleteDialog(index),
                      isDelete: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {bool isDelete = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDelete ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: isDelete ? Colors.redAccent : Colors.white70),
      ),
    );
  }
}