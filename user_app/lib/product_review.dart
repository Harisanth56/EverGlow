import 'package:flutter/material.dart';
import 'package:user_app/main.dart';
import 'package:user_app/rating.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS — Deep Space Dark Theme
// ─────────────────────────────────────────────
class _Theme {
  // Backgrounds
  static const bg = Color(0xFF080D14);
  static const surface = Color(0xFF0F1923);
  static const surfaceAlt = Color(0xFF131E2B);
  static const card = Color(0xFF111C2A);
  static const cardBorder = Color(0xFF1E2E42);

  // Accent
  static const teal = Color(0xFF00D4AA);
  static const tealDim = Color(0xFF00907A);
  static const tealGlow = Color(0x2200D4AA);
  static const amber = Color(0xFFFFB800);
  static const amberDim = Color(0xFF7A5800);
  static const orange = Color(0xFFFF7A2F);

  // Text
  static const textPrimary = Color(0xFFE8EDF4);
  static const textSecondary = Color(0xFF7A90A8);
  static const textMuted = Color(0xFF3E5268);

  // Gradients
  static const scoreGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF0096FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class ProductReviewsPage extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductReviewsPage({
    Key? key,
    required this.productId,
    required this.productName,
  }) : super(key: key);

  @override
  State<ProductReviewsPage> createState() => _ProductReviewsPageState();
}

class _ProductReviewsPageState extends State<ProductReviewsPage>
    with SingleTickerProviderStateMixin {
  List<RatingModel> _ratings = [];
  List<Map<String, dynamic>> _ratingsData = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  Map<int, int> _starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  late AnimationController _controller;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _fetchProductReviews();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchProductReviews() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('tbl_rating')
          .select('''
            *,
            tbl_gallery (gallery_file),
            tbl_user (user_name, user_photo)
          ''')
          .eq('product_id', int.parse(widget.productId));

      final List<Map<String, dynamic>> rawData =
          List<Map<String, dynamic>>.from(response);
      final List<RatingModel> loadedRatings = rawData
          .map((m) => RatingModel.fromMap(m))
          .toList();

      double totalSum = 0;
      Map<int, int> temporaryStars = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (var review in loadedRatings) {
        final int score = double.tryParse(review.ratingValue)?.round() ?? 0;
        totalSum += score;
        if (score >= 1 && score <= 5) {
          temporaryStars[score] = (temporaryStars[score] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _ratingsData = rawData;
          _ratings = loadedRatings;
          _averageRating = loadedRatings.isNotEmpty
              ? (totalSum / loadedRatings.length)
              : 0.0;
          _starCounts = temporaryStars;
          _isLoading = false;
        });
        _controller.forward(from: 0);
      }
    } catch (e) {
      debugPrint("REVIEWS FETCH ERROR: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDisplayTime(String dbTimeValue) {
    if (dbTimeValue.isEmpty || dbTimeValue == 'null') return "Recent";
    if (dbTimeValue.contains(':')) {
      final elements = dbTimeValue.split(':');
      if (elements.length >= 2) return "${elements[0]}:${elements[1]}";
    }
    return dbTimeValue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Theme.bg,
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoader() : _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: _Theme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: _Theme.cardBorder),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _Theme.textPrimary,
              size: 16,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.productName,
            style: const TextStyle(
              color: _Theme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Text(
            'Customer Reviews',
            style: TextStyle(
              color: _Theme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: const AlwaysStoppedAnimation(_Theme.teal),
              backgroundColor: _Theme.tealGlow,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loading reviews…',
            style: TextStyle(
              color: _Theme.textSecondary,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return FadeTransition(
      opacity: _fadeIn,
      child: RefreshIndicator(
        onRefresh: _fetchProductReviews,
        color: _Theme.teal,
        backgroundColor: _Theme.surface,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 110)),

            // ─── SUMMARY CARD ───────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSummaryCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // ─── SECTION HEADER ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 18,
                      decoration: BoxDecoration(
                        gradient: _Theme.scoreGradient,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Top Customer Reviews',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _Theme.textPrimary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _Theme.tealGlow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _Theme.tealDim, width: 0.5),
                      ),
                      child: Text(
                        '${_ratings.length}',
                        style: const TextStyle(
                          color: _Theme.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 14)),

            // ─── REVIEW CARDS ────────────────────────────────────
            if (_ratings.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final rating = _ratings[index];
                  final rawReview = _ratingsData[index];
                  final userData =
                      rawReview['tbl_user'] as Map<String, dynamic>?;
                  final String userName =
                      userData?['user_name']?.toString() ?? "Anonymous";
                  final String userPhotoUrl =
                      userData?['user_photo']?.toString() ?? "";
                  final int parsedStars =
                      double.tryParse(rating.ratingValue)?.round() ?? 0;

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildReviewCard(
                      rating: rating,
                      userName: userName,
                      userPhotoUrl: userPhotoUrl,
                      parsedStars: parsedStars,
                    ),
                  );
                }, childCount: _ratings.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SUMMARY CARD
  // ─────────────────────────────────────────────
  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: _Theme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _Theme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: _Theme.teal.withOpacity(0.04),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── LEFT: Score ────────────────────────────────
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        _Theme.scoreGradient.createShader(bounds),
                    child: Text(
                      _averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _DarkStarRow(rating: _averageRating, size: 18),
                  const SizedBox(height: 8),
                  Text(
                    '${_ratings.length} ratings',
                    style: const TextStyle(
                      color: _Theme.textSecondary,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

            // ── DIVIDER ────────────────────────────────────
            Container(
              height: 90,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _Theme.cardBorder,
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // ── RIGHT: Bar chart ───────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                children: List.generate(5, (index) {
                  final int starLevel = 5 - index;
                  final int count = _starCounts[starLevel] ?? 0;
                  final double percent = _ratings.isNotEmpty
                      ? (count / _ratings.length)
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 38,
                          child: Row(
                            children: [
                              Text(
                                '$starLevel',
                                style: const TextStyle(
                                  color: _Theme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.star_rounded,
                                size: 11,
                                color: _Theme.amber,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _Theme.surfaceAlt,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: percent,
                                child: Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: starLevel >= 4
                                          ? [_Theme.teal, _Theme.tealDim]
                                          : starLevel == 3
                                          ? [_Theme.amber, _Theme.amberDim]
                                          : [
                                              _Theme.orange,
                                              _Theme.orange.withOpacity(.6),
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 34,
                          child: Text(
                            '${(percent * 100).toStringAsFixed(0)}%',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              color: _Theme.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  REVIEW CARD
  // ─────────────────────────────────────────────
  Widget _buildReviewCard({
    required RatingModel rating,
    required String userName,
    required String userPhotoUrl,
    required int parsedStars,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _Theme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _Theme.cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── User Header ──────────────────────────────────
            Row(
              children: [
                _buildAvatar(userPhotoUrl, userName),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: _Theme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 12,
                            color: _Theme.teal,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Verified Purchase',
                            style: TextStyle(
                              color: _Theme.teal,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Timestamp chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _Theme.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _Theme.cardBorder),
                  ),
                  child: Text(
                    _formatDisplayTime(rating.ratingDatetime),
                    style: const TextStyle(
                      color: _Theme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Divider ──────────────────────────────────────
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _Theme.cardBorder,
                    Colors.transparent,
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Stars ────────────────────────────────────────
            _DarkStarRow(rating: parsedStars.toDouble(), size: 16),

            const SizedBox(height: 10),

            // ── Review Text ──────────────────────────────────
            Text(
              rating.ratingContent,
              style: const TextStyle(
                color: _Theme.textPrimary,
                fontSize: 13.5,
                height: 1.55,
                letterSpacing: 0.1,
              ),
            ),

            // ── Attached Images ──────────────────────────────
            if (rating.attachmentUrls.isNotEmpty) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: rating.attachmentUrls.length,
                  itemBuilder: (context, imgIdx) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _Theme.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 8,
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(rating.attachmentUrls[imgIdx]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String photoUrl, String name) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _Theme.scoreGradient,
        boxShadow: [
          BoxShadow(
            color: _Theme.teal.withOpacity(0.25),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        radius: 19,
        backgroundColor: _Theme.surface,
        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
        child: photoUrl.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: _Theme.teal,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _Theme.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: _Theme.cardBorder),
              ),
              child: const Icon(
                Icons.rate_review_outlined,
                color: _Theme.textMuted,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No reviews yet',
              style: TextStyle(
                color: _Theme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Be the first to share your experience.',
              style: TextStyle(color: _Theme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DARK STAR ROW — replaces StarRating widget
// ─────────────────────────────────────────────
class _DarkStarRow extends StatelessWidget {
  final double rating;
  final double size;

  const _DarkStarRow({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    final int full = rating.floor();
    final bool half = (rating - full) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        IconData icon;
        Color color;

        if (i < full) {
          icon = Icons.star_rounded;
          color = _Theme.amber;
        } else if (i == full && half) {
          icon = Icons.star_half_rounded;
          color = _Theme.amber;
        } else {
          icon = Icons.star_outline_rounded;
          color = _Theme.textMuted;
        }

        return Icon(icon, color: color, size: size);
      }),
    );
  }
}