import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/main.dart';
import 'package:user_app/review_detail.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int cartQuantity = 0;
  int stockQuantity = 0;
  bool isOutOfStock = false;
  Map<String, dynamic>? product;
  int _currentImageIndex = 0;

  Map<String, dynamic>? detailedProduct;
  List<dynamic> _productReviews = [];
  double _averageRating = 0.0;

  // Rating breakdown state derived dynamically from incoming review data structures
  Map<int, double> ratingBreakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  bool isReviewsLoading = true;

  @override
  void initState() {
    super.initState();
    detailedProduct = widget.product;
    _loadAllProductData();
  }

  Future<void> _loadAllProductData() async {
    final productId = widget.product['product_id'];
    if (productId == null) return;
    await Future.wait([
      fetchProductStatus(productId),
      _fetchMissingRelations(productId),
      _fetchProductReviews(productId),
    ]);
  }

  Future<void> _fetchMissingRelations(dynamic productId) async {
    try {
      final updatedData = await supabase
          .from('tbl_product')
          .select('''
            *,
            tbl_category(category_name),
            tbl_type(type_name),
            tbl_level(level_name),
            tbl_heatabsorption(heatabsorption_name),
            tbl_gallery(gallery_file)
          ''')
          .eq('product_id', productId)
          .maybeSingle();
      if (updatedData != null && mounted) {
        setState(() {
          detailedProduct = updatedData;
        });
      }
    } catch (e) {
      debugPrint("Error fetching product relations: $e");
    }
  }

  Future<void> fetchProductStatus(dynamic productId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final cartResponse = await supabase
          .from('tbl_cart')
          .select('cart_quantity,cart_status')
          .eq('cart_status', 2)
          .eq('product_id', productId);
      final int cartsum =
          (cartResponse as List<dynamic>?)?.fold<int>(
            0,
            (total, item) => total + (item['cart_quantity'] as int? ?? 0),
          ) ??
          0;

      final stockResponse = await supabase
          .from('tbl_stock')
          .select('stock_count')
          .eq('product_id', productId);
      final int stockSum =
          (stockResponse as List<dynamic>?)?.fold<int>(
            0,
            (total, item) => total + (item['stock_count'] as int? ?? 0),
          ) ??
          0;

      if (mounted) {
        setState(() {
          final int availableStock = stockSum - cartsum;
          cartQuantity = cartsum;
          stockQuantity = availableStock;
          isOutOfStock = stockQuantity <= 0;
        });
      }
    } catch (e) {
      debugPrint("Error fetching product status: $e");
    }
  }

  Future<void> _fetchProductReviews(dynamic productId) async {
    if (!mounted) return;
    setState(() => isReviewsLoading = true);
    try {
      final response = await supabase
          .from('tbl_rating')
          .select('''
            rating_value,
            rating_content,
            rating_image,
            rating_datetime,
            tbl_user(user_name)
          ''')
          .eq('product_id', productId)
          .order('rating_datetime', ascending: false);

      if (response != null && mounted) {
        final List<dynamic> reviews = response as List<dynamic>;
        double totalStars = 0.0;
        Map<int, int> counts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

        for (var review in reviews) {
          final int ratingVal =
              int.tryParse(review['rating_value'].toString()) ?? 0;
          totalStars += ratingVal;
          if (ratingVal >= 1 && ratingVal <= 5) {
            counts[ratingVal] = (counts[ratingVal] ?? 0) + 1;
          }
        }

        Map<int, double> percentages = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
        if (reviews.isNotEmpty) {
          counts.forEach((key, val) {
            percentages[key] = (val / reviews.length) * 100;
          });
        }

        setState(() {
          _productReviews = reviews;
          _averageRating = reviews.isNotEmpty
              ? totalStars / reviews.length
              : 0.0;
          ratingBreakdown = percentages;
          isReviewsLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching product reviews: $e");
      if (mounted) setState(() => isReviewsLoading = false);
    }
  }

  Future<void> _addToCart(BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user == null || detailedProduct == null) return;

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
            .eq('product_id', detailedProduct!['product_id'])
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
        'product_id': detailedProduct!['product_id'],
        'cart_quantity': 1,
        'cart_status': 0,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Added to cart"),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      fetchProductStatus(detailedProduct!['product_id']);
    } catch (e) {
      debugPrint("Cart error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProduct = detailedProduct ?? widget.product;
    final String name = currentProduct['product_name'] ?? 'Product';
    final String price = "₹${currentProduct['product_price'] ?? '0'}";
    final String description =
        currentProduct['product_description'] ?? "No description available.";
    final String category =
        currentProduct['tbl_category']?['category_name'] ?? "General";
    final String skinType =
        currentProduct['tbl_type']?['type_name'] ?? "All Types";
    final String heatAbsorb =
        currentProduct['tbl_heatabsorption']?['heatabsorption_name'] ??
        "Normal";
    final String heatLevel =
        currentProduct['tbl_level']?['level_name'] ?? "Unknown";

    List<String> allImages = [];
    if (currentProduct['product_photo'] != null &&
        currentProduct['product_photo'].toString().isNotEmpty) {
      allImages.add(currentProduct['product_photo'].toString());
    }

    if (currentProduct['tbl_gallery'] != null) {
      final List galleryItems = currentProduct['tbl_gallery'] is List
          ? currentProduct['tbl_gallery']
          : [currentProduct['tbl_gallery']];
      for (var item in galleryItems) {
        final String? url = item['gallery_file'];
        if (url != null && url.isNotEmpty && !allImages.contains(url)) {
          allImages.add(url);
        }
      }
    }

    if (_currentImageIndex >= allImages.length) {
      _currentImageIndex = 0;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        actions: [
          CircleAvatar(
            backgroundColor: const Color(0xFF161B22),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.share_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF161B22),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 360,
                    width: MediaQuery.of(context).size.width * 0.85,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8E71FF).withOpacity(0.1),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: allImages.isNotEmpty
                          ? Image.network(
                              allImages[_currentImageIndex],
                              fit: BoxFit.cover,
                            )
                          : Container(
                              color: const Color(0xFF161B22),
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.white24,
                                size: 60,
                              ),
                            ),
                    ),
                  ),
                  if (allImages.length > 1)
                    Positioned(
                      left: 20,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_left_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _currentImageIndex =
                                  (_currentImageIndex - 1 + allImages.length) %
                                  allImages.length;
                            });
                          },
                        ),
                      ),
                    ),
                  if (allImages.length > 1)
                    Positioned(
                      right: 20,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            setState(() {
                              _currentImageIndex =
                                  (_currentImageIndex + 1) % allImages.length;
                            });
                          },
                        ),
                      ),
                    ),
                  if (allImages.length > 1)
                    Positioned(
                      bottom: 35,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(allImages.length, (dotIndex) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == dotIndex ? 18 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == dotIndex
                                  ? const Color(0xFF8E71FF)
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF161B22),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category.toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF8E71FF),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        price,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildReviewSummaryHeader(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isOutOfStock
                              ? Colors.red.withOpacity(0.1)
                              : const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOutOfStock
                                ? Colors.red.withOpacity(0.3)
                                : const Color(0xFF4CAF50).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          isOutOfStock ? "NO STOCK" : "$stockQuantity ITEMS",
                          style: TextStyle(
                            color: isOutOfStock
                                ? Colors.red
                                : const Color(0xFF4CAF50),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Row(
                    children: [
                      _buildRefinedChip(Icons.face, skinType),
                      _buildRefinedChip(Icons.wb_sunny_outlined, heatAbsorb),
                      _buildRefinedChip(Icons.local_fire_department, heatLevel),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "About this product",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Brand new contextual integrated review analytics breakdown card layout
                  _buildReviewsCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0E14).withOpacity(0),
              const Color(0xFF0A0E14).withOpacity(0.8),
              const Color(0xFF0A0E14),
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            if (isOutOfStock) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Out of stock"),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              _addToCart(context);
            }
          },
          child: Container(
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: isOutOfStock
                  ? const LinearGradient(colors: [Colors.grey, Colors.black45])
                  : const LinearGradient(
                      colors: [Color(0xFF6B4EE6), Color(0xFF8E71FF)],
                    ),
              boxShadow: isOutOfStock
                  ? []
                  : [
                      BoxShadow(
                        color: const Color(0xFF6B4EE6).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOutOfStock
                      ? Icons.block_outlined
                      : Icons.shopping_bag_outlined,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  isOutOfStock ? 'Out of Stock' : 'Add to Cart',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReviewSummaryHeader() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, color: Colors.yellow),
        const SizedBox(width: 4),
        Text(
          _averageRating.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          "(${_productReviews.length} Reviews)",
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
      ],
    );
  }

  // ── REVIEWS COMPLEX BREAKDOWN CARD ─────────────────────────────────────────
  Widget _buildReviewsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Reviews",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              GestureDetector(
                onTap: () {
                  final activeProduct = detailedProduct ?? widget.product;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductReviewsPage(
                        productId:
                            activeProduct['product_id']?.toString() ?? '',
                        productName:
                            activeProduct['product_name']?.toString() ??
                            'Reviews',
                      ),
                    ),
                  );
                },
                child: const Text(
                  "View all →",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(
                    _averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  _starRow(_averageRating),
                  const SizedBox(height: 4),
                  Text(
                    "${_productReviews.length} ratings",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((s) {
                    final pct = ratingBreakdown[s] ?? 0;
                    final isLow = s <= 2;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Row(
                        children: [
                          Text(
                            "$s",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct / 100,
                                minHeight: 5,
                                backgroundColor: Colors.white.withOpacity(0.05),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isLow && pct > 0
                                      ? Colors.redAccent
                                      : const Color(0xFF8E71FF),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 28,
                            child: Text(
                              "${pct.round()}%",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.4),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          _divider(),
          if (isReviewsLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8E71FF),
                strokeWidth: 2,
              ),
            )
          else if (_productReviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  "No reviews yet.",
                  style: TextStyle(color: Colors.white.withOpacity(0.3)),
                ),
              ),
            )
          else
            ..._productReviews.take(3).map((r) => _reviewTile(r)),
        ],
      ),
    );
  }

  Widget _starRow(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < rating.floor();
        final half = !filled && (rating - i >= 0.5);
        return Icon(
          filled
              ? Icons.star_rounded
              : half
              ? Icons.star_half_rounded
              : Icons.star_border_rounded,
          color: Colors.yellow,
          size: size,
        );
      }),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0E14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }

  Widget _divider() => Container(
    height: 0.5,
    color: Colors.white.withOpacity(0.08),
    margin: const EdgeInsets.symmetric(vertical: 16),
  );

  Widget _reviewTile(Map<String, dynamic> r) {
    final double val =
        double.tryParse(r['rating_value']?.toString() ?? '0') ?? 0;
    final String name =
        r['tbl_user']?['user_name']?.toString() ?? "Verified User";
    final String initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2).map((w) => w[0].toUpperCase()).join()
        : "U";
    final String? reviewImg = r['rating_image']?.toString();

    String reviewDate = "Recent";
    if (r['rating_datetime'] != null) {
      try {
        final parsedDate = DateTime.parse(r['rating_datetime'].toString());
        reviewDate =
            "${parsedDate.year}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.day.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF8E71FF).withOpacity(0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Color(0xFF8E71FF),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    _starRow(val, size: 12),
                  ],
                ),
              ),
              Text(
                reviewDate,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          if ((r['rating_content'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              r['rating_content'].toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          if (reviewImg != null &&
              reviewImg.isNotEmpty &&
              reviewImg != "NULL") ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 75,
                width: 75,
                color: const Color(0xFF0A0E14),
                child: Image.network(
                  reviewImg,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      const Icon(Icons.broken_image, color: Colors.white12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRefinedChip(IconData icon, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF8E71FF), size: 16),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

