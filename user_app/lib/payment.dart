import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/main.dart'; // Using your project's supabase instance
import 'package:user_app/success.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final int id; // booking_id
  final int amt; // total amount

  const PaymentGatewayScreen({super.key, required this.id, required this.amt});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  // Controllers for card details
  final TextEditingController cardNumber = TextEditingController();
  final TextEditingController cardName = TextEditingController();
  final TextEditingController expiry = TextEditingController();
  final TextEditingController cvv = TextEditingController();

  /// Logic to update database and finalize payment
  Future<void> checkout() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isProcessing = true);

  try {
    // 1. Update cart status to completed/purchased (2) 
    // This instantly updates fetchProductStatus calculations globally!
    await supabase
        .from('tbl_cart')
        .update({'cart_status': 2}) // Changed from 1 to 2 to match fetchProductStatus
        .eq('booking_id', widget.id);

    // 2. Update booking status to completed (2) and set final amount
    await supabase
        .from('tbl_booking')
        .update({
          'booking_status': 2, 
          'booking_amount': widget.amt,
        })
        .eq('booking_id', widget.id);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentSuccessPage()),
      );
    }
  } catch (e) {
    debugPrint("Checkout Error: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Failed")),
      );
      setState(() => _isProcessing = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14), // Dark Theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Secure Payment",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF8E71FF),
            size: 18,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              /// CREDIT CARD UI
              _buildCreditCardDisplay(),
              const SizedBox(height: 30),

              /// PAYMENT FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildThemedTextField(
                      controller: cardNumber,
                      label: "Card Number",
                      keyboardType: TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        CardFormatter(),
                      ],
                      validator: (value) {
                        if (value == null ||
                            value.replaceAll(" ", "").length != 16) {
                          return "Enter valid 16 digit card number";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildThemedTextField(
                      controller: cardName,
                      label: "Card Holder Name",
                      validator: (value) {
                        if (value == null || value.isEmpty) return "Enter name";
                        if (!RegExp(r'^[a-zA-Z ]{3,15}$').hasMatch(value))
                          return "Enter valid name";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildThemedTextField(
                            controller: expiry,
                            label: "Expiry MM/YY",
                            keyboardType: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              ExpiryFormatter(),
                            ],
                            validator: (value) {
                              if (value == null || value.length != 5)
                                return "Invalid";

                              // Logic to check if expiry date is valid
                              final parts = value.split('/');
                              if (parts.length != 2) return "Invalid";

                              final int? month = int.tryParse(parts[0]);
                              final int? year = int.tryParse(parts[1]);

                              if (month == null ||
                                  year == null ||
                                  month < 1 ||
                                  month > 12) {
                                return "Invalid Month";
                              }

                              final now = DateTime.now();
                              final currentYear =
                                  now.year % 100; // Get last two digits
                              final currentMonth = now.month;

                              if (year < currentYear ||
                                  (year == currentYear &&
                                      month < currentMonth)) {
                                return "Card Expired";
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: _buildThemedTextField(
                            controller: cvv,
                            label: "CVV",
                            obscure: true,
                            keyboardType: TextInputType.number,
                            formatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            validator: (value) {
                              if (value == null || value.length != 3)
                                return "Invalid";
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    /// PAY BUTTON
                    _buildPayButton(),
                    const SizedBox(height: 20),
                    const Text(
                      "Secure Payment Powered by UvSense",
                      style: TextStyle(color: Colors.white24, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// UI for the interactive Card Display
  Widget _buildCreditCardDisplay() {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)], // Your Brand Colors
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EE6).withOpacity(.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.credit_card, color: Colors.white, size: 40),
          const Spacer(),
          Text(
            cardNumber.text.isEmpty ? "XXXX XXXX XXXX XXXX" : cardNumber.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                cardName.text.isEmpty
                    ? "CARD HOLDER"
                    : cardName.text.toUpperCase(),
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                expiry.text.isEmpty ? "MM/YY" : expiry.text,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Themed input field to match your app's style
  Widget _buildThemedTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatters,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white24),
        filled: true,
        fillColor: const Color(0xFF161B22),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF8E71FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  /// Themed Checkout Button
  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : checkout,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8E71FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          shadowColor: const Color(0xFF8E71FF).withOpacity(0.4),
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                "Pay ₹${widget.amt}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}

// --- Text Formatters ---

class CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(" ", "");
    if (text.length > 16) return oldValue;
    var newText = "";
    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) newText += " ";
      newText += text[i];
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll("/", "");
    if (text.length > 4) return oldValue;
    if (text.length >= 3) {
      text = "${text.substring(0, 2)}/${text.substring(2)}";
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
