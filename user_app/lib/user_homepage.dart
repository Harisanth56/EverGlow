import 'dart:convert';
import 'package:user_app/dr_grid.dart';
import 'package:user_app/gemini_service.dart';
import 'package:user_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:user_app/poduct_detail.dart';
import 'package:user_app/pro_grid.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with SingleTickerProviderStateMixin {
  static const Color bgBlack = Color(0xFF0A0A0F);
  static const Color darkCard = Color(0xFF141420);
  static const Color gold = Color(0xFF8E71FF);
  static const Color copper = Color(0xFF7A4E2D);
  static const Color glass = Color(0xFF1E1E2E);
  static const Color accent = Color(0xFF8E71FF);

  double uvIndex = 0.0;
  String temperature = "--";
  String locationName = "Detecting location...";
  bool isLoading = true;
  List<dynamic> recommendedProducts = [];

  String? userSkinType;
  String? aiLog;
  String? userName;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _initLocationAndWeather();
    _loadUserName();
    _fetchRecommendedProducts();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final data = await supabase
            .from('tbl_user')
            .select('user_name')
            .eq('user_id', user.id)
            .single();
        if (mounted) setState(() => userName = data['user_name']);
      }
    } catch (_) {}
  }

  Future<void> _fetchRecommendedProducts() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final d = await supabase
            .from('tbl_user')
            .select('type_id')
            .eq('user_id', user.id)
            .single();

        if (mounted) {
          setState(() {
            userSkinType = d['type_id']?.toString();
          });
        }
      }

      // Begin building the query
      var query = supabase.from('tbl_product').select();

      if (userSkinType != null && userSkinType!.isNotEmpty) {
        // Matches products where type_id is equal to userSkinType OR equal to 'all'
        query = query.or('type_id.eq.$userSkinType,type_id.eq.5');
      } else {
        // Fallback: Use current environmental UV level if user profile has no skin type
        final levelRes = await supabase
            .from('tbl_level')
            .select('level_id')
            .ilike('level_name', '%${_getUvLevel(uvIndex)}%')
            .limit(1);

        if (levelRes.isNotEmpty) {
          query = query.eq('level_id', levelRes[0]['level_id']);
        }
      }

      // Fetch dataset up to 8 items
      final products = await query.limit(8);

      if (mounted) {
        setState(() {
          recommendedProducts = products;
        });
      }
    } catch (e) {
      debugPrint("Product Recommendation Error: $e");
    }
  }

  Future<void> _initLocationAndWeather() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          locationName = "India";
          isLoading = false;
        });
        _fetchWeather(20.5937, 78.9629);
        return;
      }
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _fetchWeather(pos.latitude, pos.longitude);
    } catch (e) {
      setState(() {
        locationName = "India";
      });
      _fetchWeather(20.5937, 78.9629);
    }
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    try {
      final res = await http.get(
        Uri.parse('https://wttr.in/$lat,$lon?format=j1'),
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        print(data);
        final current = data['current_condition'][0];
        final area = data['nearest_area'][0];
        setState(() {
          uvIndex = double.tryParse(current['uvIndex'] ?? "0") ?? 0.0;

          temperature = current['temp_C'] ?? "--";
          locationName =
              "${area['areaName'][0]['value']}, ${area['region'][0]['value']}";
        });
        await _fetchRecommendedProducts();
        _fetchAiLog();
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchAiLog() async {
    try {
      final advice = await GeminiService.getSkinCareAdvice(
        uvIndex,
        userSkinType,
      );
      if (mounted) {
        setState(() {
          aiLog = advice;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error $e");
    }
  }

  // Future<void> _fetchRecommendedProducts() async {
  //   try {
  //     final user = supabase.auth.currentUser;
  //     if (user != null) {
  //       final d = await supabase
  //           .from('tbl_user')
  //           .select('type_id')
  //           .eq('user_id', user.id)
  //           .single();
  //       userSkinType = d['type_id']?.toString();
  //     }
  //     final levelRes = await supabase
  //         .from('tbl_level')
  //         .select('level_id')
  //         .ilike('level_name', '%${_getUvLevel(uvIndex)}%')
  //         .limit(1);
  //     var query = supabase.from('tbl_product').select();
  //     if (levelRes.isNotEmpty) {
  //       query = query.eq('level_id', levelRes[0]['level_id']);
  //     } else if (userSkinType != null) {
  //       query = query.eq('type_id', userSkinType!);
  //     }
  //     final products = await query.limit(8);
  //     setState(() => recommendedProducts = products);
  //   } catch (e) {
  //     debugPrint("Product Error: $e");
  //   }
  // }

  String _getUvLevel(double uv) {
    if (uv <= 2) return "Low";
    if (uv <= 5) return "Moderate";
    if (uv <= 7) return "High";
    if (uv <= 10) return "Very High";
    return "Extreme";
  }

  Color _getUvColor(double uv) {
    if (uv <= 2) return const Color(0xFF4CAF50);
    if (uv <= 5) return const Color(0xFFFFEB3B);
    if (uv <= 7) return const Color(0xFFFF9800);
    if (uv <= 10) return const Color(0xFFF44336);
    return const Color(0xFF9C27B0);
  }

  String _getUvEmoji(double uv) {
    if (uv <= 2) return "😊";
    if (uv <= 5) return "🌤️";
    if (uv <= 7) return "☀️";
    if (uv <= 10) return "🔥";
    return "⚠️";
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bgBlack,
        extendBodyBehindAppBar: true,
        extendBody: true,

        body: FadeTransition(
          opacity: _fadeAnim,
          child: RefreshIndicator(
            color: gold,
            backgroundColor: darkCard,
            onRefresh: _initLocationAndWeather,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                /// ── TOP HEADER ──
                SliverToBoxAdapter(child: _buildHeader()),

                /// ── UV HERO CARD ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: _buildUVHeroCard(),
                  ),
                ),

                /// ── UV GAUGE BAR ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: _buildUVGaugeBar(),
                  ),
                ),

                /// ── AI SKIN LOG ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: _buildSection(
                      title: "AI Skin Care Log",
                      icon: Icons.auto_awesome_rounded,
                      child: _buildAiLog(),
                    ),
                  ),
                ),

                /// ── RECOMMENDED PRODUCTS ──
                /// ── RECOMMENDED PRODUCTS ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(
                          "Daily Protection",
                          Icons.spa_rounded,
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductGridScreen(),
                            ),
                          ),
                          child: Text(
                            "See All",
                            style: GoogleFonts.outfit(
                              color: gold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height:
                        210, // Adjusted compact baseline to minimize vertical whitespace gaps
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: gold,
                              strokeWidth: 2,
                            ),
                          )
                        : recommendedProducts.isEmpty
                        ? Center(
                            child: Text(
                              "No custom products matched your skin type profile.",
                              style: GoogleFonts.outfit(
                                color: Colors.white24,
                                fontSize: 13,
                              ),
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics:
                                const BouncingScrollPhysics(), // Premium native momentum scrolling feel
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: recommendedProducts.length,
                            itemBuilder: (ctx, i) =>
                                _buildProductChip(recommendedProducts[i]),
                          ),
                  ),
                ),

                /// ── BOOK A DERM ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    child: _buildDoctorBanner(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 16, // dynamic safe area
        24,
        24,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 107, 82, 245).withOpacity(.3),
            bgBlack,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName != null
                        ? "Hello, ${userName!.split(' ')[0]} 👋"
                        : "Hello 👋",
                    style: GoogleFonts.outfit(fontSize: 14, color: Colors.white54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "UV Sense",
                    style: GoogleFonts.outfit(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: gold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: glass,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: gold.withOpacity(.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: gold, size: 14),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            locationName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Transparent light shade at bottom
          Positioned(
            bottom: 0,
            left: -24,
            right: -24,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUVHeroCard() {
    final uvColor = _getUvColor(uvIndex);
    final uvLevel = _getUvLevel(uvIndex);
    final emoji = _getUvEmoji(uvIndex);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [uvColor.withOpacity(.25), darkCard],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: uvColor.withOpacity(.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: uvColor.withOpacity(.2),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: isLoading
          ? const SizedBox(
              height: 140,
              child: Center(
                child: CircularProgressIndicator(color: gold, strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "$temperature°C",
                          style: GoogleFonts.outfit(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: uvColor.withOpacity(.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: uvColor.withOpacity(.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wb_sunny_rounded,
                                color: uvColor,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "UV $uvLevel · Index ${uvIndex.toStringAsFixed(1)}",
                                style: GoogleFonts.outfit(
                                  color: uvColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: uvColor.withOpacity(.1),
                        border: Border.all(
                          color: uvColor.withOpacity(.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildUVGaugeBar() {
    final uvColor = _getUvColor(uvIndex);
    final pct = (uvIndex / 11).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "UV Exposure Risk",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
              ),
              Text(
                _getUvLevel(uvIndex),
                style: GoogleFonts.outfit(
                  color: uvColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(.08),
              valueColor: AlwaysStoppedAnimation<Color>(uvColor),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ["Low", "Moderate", "High", "Very High", "Extreme"]
                .map(
                  (l) => Text(
                    l,
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAiLog() {
    if (aiLog == null) {
      return Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: gold, strokeWidth: 2),
          ),
          const SizedBox(width: 15),
          Text(
            "Analyzing skin data...",
            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
          ),
        ],
      );
    }

    List<String> lines = aiLog!.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        String trimmedLine = line.trim();
        if (trimmedLine.isEmpty) return const SizedBox(height: 8);

        if (trimmedLine.startsWith('**') && trimmedLine.endsWith('**')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lines.indexOf(line) != 0)
                  Divider(
                    color: gold.withOpacity(0.1),
                    thickness: 1,
                    height: 24,
                  ),
                Text(
                  trimmedLine.replaceAll('**', '').toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: gold,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          );
        }

        if (trimmedLine.contains('Elite Tip') || trimmedLine.startsWith('*')) {
          return _buildAdviceTile(trimmedLine);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            trimmedLine.replaceAll('**', ''),
            style: GoogleFonts.outfit(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdviceTile(String text) {
    String cleanText = text.replaceAll('*', '').replaceAll('**', '').trim();
    bool isTip = cleanText.contains('Elite Tip');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isTip
                ? Icons.lightbulb_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: isTip ? gold : const Color(0xFF81C784),
            size: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cleanText,
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.9),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: glass,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: gold.withOpacity(.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: gold, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: gold, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ],
    );
  }

  Widget _buildProductChip(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: item),
          ),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: glass,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: gold.withOpacity(.12)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.3), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child:
                  item['product_photo'] != null &&
                      item['product_photo'].toString().isNotEmpty
                  ? Image.network(
                      item['product_photo'],
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: darkCard,
                        child: const Icon(
                          Icons.spa_outlined,
                          color: gold,
                          size: 40,
                        ),
                      ),
                    )
                  : Container(
                      height: 120,
                      color: darkCard,
                      child: const Icon(
                        Icons.spa_outlined,
                        color: gold,
                        size: 40,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['product_name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "₹${item['product_price'] ?? '0'}",
                    style: GoogleFonts.outfit(
                      color: gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorBanner() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 93, 71, 192), Color(0xFF8E71FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gold.withOpacity(.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Specialist Care",
                    style: GoogleFonts.outfit(
                      color: const Color.fromARGB(135, 255, 255, 255),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Book a Dermatologist",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Expert guidance for your skin type",
                  style: GoogleFonts.outfit(
                    color: const Color.fromARGB(137, 255, 255, 255),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DoctorGridScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: gold,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "Book Now →",
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: gold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.medical_services_outlined,
            size: 70,
            color: Colors.black12,
          ),
        ],
      ),
    );
  }
}
