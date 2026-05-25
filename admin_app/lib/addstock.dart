import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class AddStock extends StatefulWidget {
  final dynamic productId;

  const AddStock({super.key, required this.productId});

  @override
  State<AddStock> createState() => _AddStockState();
}

class _AddStockState extends State<AddStock> {
  final TextEditingController stockController = TextEditingController();

  // JosKart Theme Palette
  static const Color bgColor = Color(0xFF0D0D0D);
  static const Color cardColor = Color(0xFF1A1A1A);
  static const Color accentColor = Color(0xFFE94E1B);
  static const Color fieldColor = Color(0xFF0D0D0D);

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        // Use green for success, red for error, and accentColor as default
        backgroundColor: isError ? Colors.redAccent : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> insert() async {
    final stockValue = stockController.text.trim();

    // 1. Validation
    if (stockValue.isEmpty) {
      _showSnackBar('Please enter a quantity');
      return;
    }

    final int? quantity = int.tryParse(stockValue);
    if (quantity == null) {
      _showSnackBar('Please enter a valid number');
      return;
    }

    try {
      // 2. Just Insert (No existence check)
      await supabase.from('tbl_stock').insert({
        'stock_count': quantity,
        'product_id': widget.productId,
      });

      _showSnackBar('Stock Added Successfully');

      // 3. UI Cleanup
      stockController.clear();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      debugPrint("Stock Operation Error: $e");
      _showSnackBar('Error saving stock: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Align(
          alignment: Alignment.center, // Centered for a clean form look
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 500,
            ), // Narrower for a simple form
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Hug content
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                _buildFormCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 10),
        const Text(
          "Update Inventory",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
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
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "STOCK QUANTITY",
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: stockController,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: InputDecoration(
              filled: true,
              fillColor: fieldColor,
              hintText: "Enter units (e.g. 50)",
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
              prefixIcon: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white38,
              ),
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
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: insert,
              child: const Text(
                "UPDATE STOCK",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
