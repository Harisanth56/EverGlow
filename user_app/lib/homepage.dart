import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/cart.dart';
import 'package:user_app/dr_grid.dart';
import 'package:user_app/main.dart';
import 'package:user_app/my_booking.dart';
import 'package:user_app/myprofile.dart';
import 'package:user_app/poduct_detail.dart';
import 'package:user_app/pro_grid.dart';
import 'package:user_app/doctor.dart';

abstract class _AppColors {
  static const background = Color(0xFF0A0E14);
  static const surface = Color(0xFF161B22);
  static const accent = Color(0xFF8E71FF);
  static const accentDark = Color(0xFF6B4EE6);
  static const orange = Color(0xFFE94E1B);
  static const white = Colors.white;
  static const white54 = Colors.white54;
  static const white38 = Colors.white38;
  static const white10 = Colors.white10;
}

abstract class _AppTextStyles {
  static const sectionTitle = TextStyle(
    color: _AppColors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({required this.icon, required this.label});
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _dermatologists = [];
  List<Map<String, dynamic>> _products = [];
  String? _userName;
  String? _userLocation;
  
  // Tracks database fetching lifecycle state to prevent partial/null text rendering flashes
  bool _isInitialLoading = true;
  bool _isLoading = true;
  int _selectedIndex = 0;

  static const _navItems = [
    _NavItem(icon: Icons.home_filled, label: 'Home'),
    _NavItem(icon: Icons.calendar_today_outlined, label: 'Booking'),
    _NavItem(icon: Icons.shopping_cart, label: 'Cart'),
    _NavItem(icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      // Parallel execution block waits until absolutely everything is retrieved before turning off loading state
      await Future.wait([
        _fetchUserProfile(),
        _fetchProducts(),
        _fetchDermatologists(),
      ]);
    } catch (e) {
      debugPrint('Error during lifecycle batch execution: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('tbl_user')
          .select()
          .eq('user_id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _userName = data['user_name'] ?? '';
          _userLocation = data['user_address'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select(
            '*, tbl_category(category_name), tbl_type(type_name), tbl_heatabsorption(heatabsorption_name)',
          );

      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDermatologists() async {
    try {
      final response = await supabase
          .from('tbl_dermatologist')
          .select()
          .eq('dermatologist_status', 'approved');

      if (mounted) {
        setState(() {
          _dermatologists = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Error fetching dermatologists: $e');
    }
  }

  Future<void> _handleRefresh() async {
    await Future.wait([_fetchDermatologists(), _fetchProducts(), _fetchUserProfile()]);
  }

  void _onNavTap(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _isInitialLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _AppColors.accent,
              ),
            )
          : _HomeContent(
              userName: _userName,
              userLocation: _userLocation,
              products: _products,
              dermatologists: _dermatologists,
              isLoading: _isLoading,
              onRefresh: _handleRefresh,
            ),
      const MyAppointments(),
      const CartScreen(),
      const MyProfile(),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _AppColors.background,
        body: pages[_selectedIndex],
        bottomNavigationBar: _BottomNavBar(
          items: _navItems,
          selectedIndex: _selectedIndex,
          onTap: _onNavTap,
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final String? userName;
  final String? userLocation;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> dermatologists;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _HomeContent({
    required this.userName,
    required this.userLocation,
    required this.products,
    required this.dermatologists,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _TopBar(userName: userName, userLocation: userLocation),
                const SizedBox(height: 15),
                const _SearchBar(),
                const SizedBox(height: 20),
                const _UVSenseRow(),
                _SectionHeader(
                  title: 'Products',
                  onViewAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProductGridScreen(),
                    ),
                  ),
                ),
                _ProductList(products: products, isLoading: isLoading),
                _SectionHeader(
                  title: 'Specialists',
                  onViewAll: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorGridScreen()),
                  ),
                ),
                _DoctorList(
                  dermatologists: dermatologists,
                  isLoading: isLoading,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String? userName;
  final String? userLocation;

  const _TopBar({this.userName, this.userLocation});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${userName ?? "User"} 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Protect your skin everyday',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: _AppColors.accent,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  userLocation ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
        height: 55,
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: _AppColors.white10),
        ),
        child: TextField(
          style: const TextStyle(color: Colors.white),
          cursorColor: _AppColors.accent,
          decoration: InputDecoration(
            hintText: 'Search products, doctors...',
            hintStyle: const TextStyle(color: Colors.white38),
            border: InputBorder.none,
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: _AppColors.accent,
            ),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tune_rounded, color: _AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }
}

class _UVSenseRow extends StatelessWidget {
  const _UVSenseRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: const Row(
        children: [
          Expanded(flex: 6, child: _TemperatureCard()),
          SizedBox(width: 14),
          Expanded(flex: 4, child: _UVRiskCard()),
        ],
      ),
    );
  }
}

class _TemperatureCard extends StatelessWidget {
  const _TemperatureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8E71FF), Color(0xFF6B4EE6)],
        ),
        boxShadow: [
          BoxShadow(
            color: _AppColors.accent.withOpacity(0.35),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Colors.yellow),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Today",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            "33°",
            style: TextStyle(
              color: Colors.white,
              fontSize: 58,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Feels like 36°C",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _UVRiskCard extends StatelessWidget {
  const _UVRiskCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "UV Exposure",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLevelLabel("EXTREME", isActive: true),
                      _buildLevelLabel("HIGH", isActive: false),
                      _buildLevelLabel("MODERATE", isActive: false),
                      _buildLevelLabel("LOW", isActive: false),
                    ],
                  ),
                ),
                Container(
                  width: 14,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        height: 140,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_AppColors.accent, _AppColors.accentDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _AppColors.accent.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.02)),
            ),
            child: const Center(
              child: Text(
                "EXTREME RISK",
                style: TextStyle(
                  color: _AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelLabel(String label, {required bool isActive}) {
    return Text(
      label,
      style: TextStyle(
        color: isActive ? Colors.white : Colors.white24,
        fontSize: 9,
        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;

  const _SectionHeader({required this.title, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: _AppTextStyles.sectionTitle),
          TextButton(
            onPressed: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(color: _AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isLoading;

  const _ProductList({required this.products, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: _AppColors.orange),
        ),
      );
    }

    if (products.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Text(
            'No products available',
            style: TextStyle(color: _AppColors.white54),
          ),
        ),
      );
    }

    final preview = products.take(5).toList();

    return SizedBox(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: preview.length,
        itemBuilder: (context, index) => _ProductCard(product: preview[index]),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final photo = product['product_photo'] as String?;
    final name = product['product_name'] ?? 'Product';
    final price = product['product_price'] ?? '0';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 7,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  color: Colors.white10,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: photo != null && photo.isNotEmpty
                      ? Image.network(photo, fit: BoxFit.cover)
                      : const Icon(
                          Icons.image_not_supported,
                          color: Colors.white24,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Text(
                    "₹$price",
                    style: const TextStyle(
                      color: _AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _AppColors.accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: _AppColors.accent,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _DoctorList extends StatelessWidget {
  final List<Map<String, dynamic>> dermatologists;
  final bool isLoading;

  const _DoctorList({required this.dermatologists, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: CircularProgressIndicator(color: _AppColors.accent),
        ),
      );
    }

    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: dermatologists.length,
        itemBuilder: (context, index) =>
            _DoctorCard(doctor: dermatologists[index]),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    final photo = doctor['dermatologist_photo'] as String?;
    final name = doctor['dermatologist_name'] ?? 'Doctor';
    final specialization = doctor['specialization'] ?? 'Dermatologist';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProfileDr(doctor: doctor)),
        );
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _AppColors.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              children: [
                Hero(
                  tag: name,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _AppColors.accent.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white10,
                      backgroundImage: photo != null ? NetworkImage(photo) : null,
                      child: photo == null
                          ? const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 35,
                            )
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: _AppColors.surface, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              specialization.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AppColors.accent.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white.withOpacity(0.15),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: _AppColors.white10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          items.length,
          (i) => _NavButton(
            item: items[i],
            isActive: selectedIndex == i,
            onTap: () => onTap(i),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.icon,
            color: isActive ? _AppColors.accent : _AppColors.white38,
            size: 26,
          ),
          const SizedBox(height: 5),
          isActive
              ? Container(
                  height: 4,
                  width: 4,
                  decoration: const BoxDecoration(
                    color: _AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                )
              : const SizedBox(height: 4),
        ],
      ),
    );
  }
}