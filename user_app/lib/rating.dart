import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRatingScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final bool isUpdating;

  const ProductRatingScreen({
    super.key,
    required this.product,
    this.isUpdating = false,
  });

  @override
  State<ProductRatingScreen> createState() => _ProductRatingScreenState();
}

class RatingModel {
  final int? ratingId;
  final String ratingValue;
  final String ratingContent;
  final String ratingDatetime;
  final String userId;
  final String productId;
  final String userName;
  final String? userAvatarUrl;
  final List<String> attachmentUrls;

  RatingModel({
    key,
    this.ratingId,
    required this.ratingValue,
    required this.ratingContent,
    required this.ratingDatetime,
    required this.userId,
    required this.productId,
    this.userName = 'Verified Customer',
    this.userAvatarUrl,
    this.attachmentUrls = const [],
  });

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'rating_value': ratingValue,
      'rating_content': ratingContent,
      'rating_datetime': ratingDatetime,
      'user_id': userId,
      'product_id': int.parse(productId),
    };
    if (ratingId != null) data['rating_id'] = ratingId;
    return data;
  }

  factory RatingModel.fromMap(Map<String, dynamic> map) {
    List<String> urls = [];

    // 1. Check for the direct rating_image column first (Fixes your missing upload visual)
    if (map['rating_image'] != null &&
        map['rating_image'].toString().isNotEmpty) {
      urls.add(map['rating_image'].toString());
    }

    // 2. Check for alternative multi-image setup from related tables if it exists
    if (map['tbl_gallery'] != null) {
      final List<dynamic> galleryList = map['tbl_gallery'] as List;
      final additionalUrls = galleryList
          .map((item) => item['gallery_file']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList();
      urls.addAll(additionalUrls);
    }

    final userTable = map['tbl_user'] as Map<String, dynamic>?;
    final parsedName =
        userTable?['user_name']?.toString() ?? 'Verified Customer';
    final parsedAvatar = userTable?['user_photo']?.toString();

    return RatingModel(
      ratingId: int.tryParse(map['rating_id']?.toString() ?? ''),
      ratingValue: map['rating_value']?.toString() ?? '0',
      ratingContent: map['rating_content']?.toString() ?? '',
      ratingDatetime: map['rating_datetime']?.toString() ?? '',
      userId: map['user_id']?.toString() ?? '',
      productId: map['product_id']?.toString() ?? '0',
      userName: parsedName,
      userAvatarUrl: parsedAvatar,
      attachmentUrls: urls,
    );
  }
}

class _ProductRatingScreenState extends State<ProductRatingScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  int _ratingValue = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;
  bool _isLoadingExisting = false;

  // New Variables for Image Upload
  File? _selectedImage;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.isUpdating) {
      _loadExistingReviewData();
    }
  }

  Future<void> _loadExistingReviewData() async {
    setState(() => _isLoadingExisting = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('tbl_rating')
          .select('rating_value, rating_content, rating_image')
          .eq('user_id', user.id)
          .eq('product_id', widget.product['product_id'])
          .maybeSingle();

      if (data != null && mounted) {
        setState(() {
          _ratingValue = int.tryParse(data['rating_value'].toString()) ?? 0;
          _reviewController.text = data['rating_content'] ?? '';
          _existingImageUrl = data['rating_image'];
        });
      }
    } catch (e) {
      debugPrint("Error loading single review text fallback details: $e");
    } finally {
      // <--- FIXED HERE
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  /// Helper method to pick image from device gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80, // Compress slightly to save network transfer latency
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  /// Handles local state removal of selected or loaded image
  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _existingImageUrl = null;
    });
  }

  Future<void> _submitRating() async {
    if (_ratingValue == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please select a star rating before submitting.",
            style: GoogleFonts.outfit(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception("User authentication missing.");
      }

      String? finalImageUrl = _existingImageUrl;

      // 1. If a new image was picked, upload it to Supabase Storage bucket first
      if (_selectedImage != null) {
        final fileName =
            '${user.id}_${widget.product['product_id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await supabase.storage
            .from(
              'review',
            ) // Ensure this bucket exists in your Supabase instance
            .upload(fileName, _selectedImage!);

        // Generate the Public URL pointing to your uploaded object
        finalImageUrl = supabase.storage.from('review').getPublicUrl(fileName);
      }

      // 2. Upsert record with the uploaded image URL string injected into 'rating_image'
      await supabase.from('tbl_rating').upsert({
        'user_id': user.id,
        'product_id': widget.product['product_id'],
        'rating_value': _ratingValue,
        'rating_content': _reviewController.text.trim(),
        'rating_image': finalImageUrl, // Saved URL reference string
        'rating_datetime': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,product_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isUpdating
                  ? "Your review has been updated successfully!"
                  : "Thank you for your feedback!",
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: const Color(0xFF8E71FF),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Review upsert action failed execution: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Submission failed. Please try again.",
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          widget.isUpdating ? 'Edit Review' : 'Write Review',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: const Color(0xFF161B22),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF8E71FF),
                size: 18,
              ),
            ),
          ),
        ),
      ),
      body: _isLoadingExisting
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E71FF)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 10),
                  _buildProductHero(widget.product),
                  const SizedBox(height: 30),

                  Text(
                    "How was your overall experience?",
                    style: GoogleFonts.outfit(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _ratingValue = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Icon(
                            index < _ratingValue
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: index < _ratingValue
                                ? const Color(0xFF8E71FF)
                                : Colors.white24,
                            size: 44,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 35),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Write your thoughts (Optional)",
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "Tell us what you liked or disliked about this item...",
                      hintStyle: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 14,
                      ),
                      fillColor: const Color(0xFF161B22),
                      filled: true,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFF8E71FF),
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Integrated Image Picker Section matching exact style guidelines
                  _buildImagePickerSection(),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E71FF),
                        disabledBackgroundColor: const Color(
                          0xFF8E71FF,
                        ).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              widget.isUpdating
                                  ? "Update Review"
                                  : "Submit Review",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Builds the image selection attachment area beneath the review description box
  Widget _buildImagePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "Add Photo (Optional)",
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
        if (_selectedImage == null && _existingImageUrl == null)
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 90,
              decoration: BoxDecoration(
                color: const Color(0xFF161B22),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Color(0xFF8E71FF),
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Tap to select an image",
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF161B22),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : Image.network(_existingImageUrl!, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: _clearSelectedImage,
                  child: const CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 16,
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildProductHero(Map<String, dynamic> product) {
    final String? url = product['product_photo'];
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 110,
            width: 110,
            color: const Color(0xFF161B22),
            child: (url != null && url.isNotEmpty)
                ? Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.broken_image,
                      color: Colors.white12,
                      size: 40,
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white12,
                    size: 40,
                  ),
          ),
        ),
        const SizedBox(height: 15),
        Text(
          product['product_name'] ?? 'Product Name',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Price: ₹${product['product_price']}",
          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
        ),
      ],
    );
  }
}
