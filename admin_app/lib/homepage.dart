import 'package:admin_app/booking.dart';
import 'package:admin_app/category.dart';
import 'package:admin_app/complaint.dart';
import 'package:admin_app/dermatologist_list.dart';
import 'package:admin_app/district.dart';
import 'package:admin_app/heatabsorption.dart';
import 'package:admin_app/level.dart';
import 'package:admin_app/login.dart';
import 'package:admin_app/myproducts.dart';
import 'package:admin_app/place.dart';
import 'package:admin_app/product_add.dart';
import 'package:admin_app/registration.dart';
import 'package:admin_app/subcategory.dart';
import 'package:admin_app/type.dart';
import 'package:admin_app/userlist.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _AppColors {
  static const bg = Color(0xFF0F0F0F);
  static const sidebar = Color(0xFF121212);
  static const card = Color(0xFF1A1A1A);
  static const cardElevated = Color(0xFF222222);
  static const surface = Color(0xFF2A2A2A);
  static const accent = Color(0xFFFF6B35); // deep orange accent
  static const accentMuted = Color(0x33FF6B35);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFBDBDBD);
  static const textMuted = Color(0xFF666666);
  static const divider = Color(0xFF2C2C2C);
  static const danger = Color(0xFFEF5350);
  static const success = Color(0xFF4CAF50);
  static const info = Color(0xFF42A5F5);
  static const warning = Color(0xFFFFA726);
}

class _AppText {
  static const h1 = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: _AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  static const h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: _AppColors.textPrimary,
    letterSpacing: -0.3,
  );
  static const h3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: _AppColors.textPrimary,
  );
  static const body = TextStyle(
    fontSize: 14,
    color: _AppColors.textSecondary,
    height: 1.5,
  );
  static const caption = TextStyle(
    fontSize: 12,
    color: _AppColors.textMuted,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: _AppColors.textSecondary,
  );
  static const navItem = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _AppColors.textSecondary,
  );
  static const navItemActive = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: _AppColors.textPrimary,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// A stat card shown in the top metrics row.
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String period;
  final String delta;
  final bool isPositive;
  final Widget icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.period,
    required this.delta,
    this.isPositive = true,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final deltaColor = isPositive ? _AppColors.success : _AppColors.danger;
    final deltaIcon = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.divider, width: 1),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: _AppText.label),
                const SizedBox(height: 4),
                Text(value, style: _AppText.h2.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(deltaIcon, size: 12, color: deltaColor),
                    const SizedBox(width: 3),
                    Text(
                      delta,
                      style: _AppText.caption.copyWith(color: deltaColor, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 6),
                    Text(period, style: _AppText.caption),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A sidebar navigation item (pushes a page on tap).
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget page;

  const _NavItem({required this.icon, required this.title, required this.page});

  @override
  Widget build(BuildContext context) {
    return _SidebarButton(
      icon: icon,
      title: title,
      onTap: () => Navigator.push(context, _fadeRoute(page)),
    );
  }
}

/// A sidebar button with selected-state support.
class _SidebarButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;

  const _SidebarButton({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? _AppColors.accent
        : _hovered
            ? _AppColors.surface
            : Colors.transparent;
    final iconColor = widget.isSelected ? Colors.white : _AppColors.textSecondary;
    final textStyle = widget.isSelected ? _AppText.navItemActive : _AppText.navItem;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Text(widget.title, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section header divider for sidebar groupings.
class _SidebarSection extends StatelessWidget {
  final String label;

  const _SidebarSection(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 12, 6),
      child: Text(
        label.toUpperCase(),
        style: _AppText.caption.copyWith(
          fontSize: 10,
          letterSpacing: 1.2,
          color: _AppColors.textMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Pill badge for stat highlights.
class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// Card wrapper used across the dashboard.
class _DashCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const _DashCard({required this.child, this.height, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: _AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _AppColors.divider, width: 1),
      ),
      padding: padding ?? const EdgeInsets.all(20),
      child: child,
    );
  }
}

/// Card header row with optional trailing widget.
class _CardHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _CardHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: _AppText.h3),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Legend dot row for charts.
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: _AppText.caption.copyWith(color: _AppColors.textSecondary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _authExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(child: _buildMainContent()),
          ],
        ),
      ),
    );
  }

  // ── SIDEBAR ──────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      width: 230,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _AppColors.sidebar,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _AppColors.divider, width: 1),
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _AppColors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'JosKart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: _AppColors.divider, height: 1),

          // Nav items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SidebarSection('Overview'),
                  _SidebarButton(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    isSelected: true,
                    onTap: () {},
                  ),

                  const _SidebarSection('Geography'),
                  _NavItem(icon: Icons.location_city_rounded, title: 'District', page: District()),
                  _NavItem(icon: Icons.place_rounded, title: 'Place', page: Place()),

                  const _SidebarSection('Catalogue'),
                  _NavItem(icon: Icons.category_rounded, title: 'Category', page: Category()),
                  _NavItem(icon: Icons.grid_view_rounded, title: 'Sub Category', page: SubCategory()),
                  _NavItem(icon: Icons.face_rounded, title: 'Skin Type', page: SkinType()),
                  _NavItem(icon: Icons.add_box_rounded, title: 'Add Product', page: AddProduct()),
                  _NavItem(icon: Icons.inventory_2_rounded, title: 'My Products', page: MyProducts()),

                  const _SidebarSection('Analytics'),
                  _NavItem(icon: Icons.device_thermostat_rounded, title: 'Heat Absorption', page: HeatAbsorption()),
                  _NavItem(icon: Icons.thermostat_rounded, title: 'Level', page: HeatLevel()),

                  const _SidebarSection('Management'),
                  _NavItem(icon: Icons.group_rounded, title: 'Users', page: Userlist()),
                  _NavItem(icon: Icons.medical_services_rounded, title: 'Dermatologist', page: DermaList()),
                  _NavItem(icon: Icons.event_available_rounded, title: 'Booking', page: OrderStatusPage()),
                  _NavItem(icon: Icons.report_problem_rounded, title: 'Complaints', page: ViewComplaints()),

                  const _SidebarSection('Auth'),
                  _buildAuthTile(),
                ],
              ),
            ),
          ),

          const Divider(color: _AppColors.divider, height: 1),

          // Logout
          Padding(
            padding: const EdgeInsets.all(12),
            child: _SidebarButton(
              icon: Icons.logout_rounded,
              title: 'Logout',
              onTap: () => debugPrint('Logout pressed'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthTile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _authExpanded = !_authExpanded),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.security_rounded, size: 18, color: _AppColors.textSecondary),
                const SizedBox(width: 10),
                const Text('Authentication', style: _AppText.navItem),
                const Spacer(),
                AnimatedRotation(
                  turns: _authExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _authExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: [
              _buildSubNavItem('Sign In', Login()),
              _buildSubNavItem('Sign Up', Registration()),
              _buildSubNavItem('Forgot Password', Login()),
              _buildSubNavItem('Reset Password', Login()),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSubNavItem(String title, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, _fadeRoute(page)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(44, 6, 12, 6),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 10),
              decoration: const BoxDecoration(
                color: _AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            Text(title, style: _AppText.caption.copyWith(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // ── MAIN CONTENT ─────────────────────────────────────────────────────────

  Widget _buildMainContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildStatCards(),
                  const SizedBox(height: 12),
                  _buildMiddleRow(),
                  const SizedBox(height: 12),
                  _buildBottomRow(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TOP BAR ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: _AppText.h1),
            Text(
              'Welcome back, Admin',
              style: _AppText.caption.copyWith(color: _AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(width: 24),
        // Search
        Container(
          height: 38,
          width: 260,
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.divider),
          ),
          child: TextField(
            style: const TextStyle(color: _AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search anything...',
              hintStyle: const TextStyle(color: _AppColors.textMuted, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, color: _AppColors.textMuted, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const Spacer(),
        // Notification bell
        _TopBarIcon(
          icon: Icons.notifications_none_rounded,
          badge: '3',
          onTap: () {},
        ),
        const SizedBox(width: 8),
        _TopBarIcon(icon: Icons.settings_outlined, onTap: () {}),
        const SizedBox(width: 12),
        // Avatar with flag image
        CircleAvatar(
          radius: 18,
          backgroundImage: const NetworkImage(
            'https://upload.wikimedia.org/wikipedia/en/thumb/9/9e/Flag_of_Japan.svg/330px-Flag_of_Japan.svg.png',
          ),
          backgroundColor: _AppColors.surface,
        ),
        const SizedBox(width: 8),
        // Profile
        CircleAvatar(
          radius: 18,
          backgroundImage: const NetworkImage(
            'https://i.scdn.co/image/ab67616d0000b273c4402918a34fa63cadaa19cd',
          ),
          backgroundColor: _AppColors.surface,
        ),
      ],
    );
  }

  // ── STAT CARDS ────────────────────────────────────────────────────────────

  Widget _buildStatCards() {
    final stats = [
      _StatCardData(
        title: 'Total Sales',
        value: '\$230,220',
        period: 'May 2026',
        delta: '+55%',
        isPositive: true,
        icon: const Icon(Icons.shopping_cart_rounded, color: _AppColors.accent, size: 22),
      ),
      _StatCardData(
        title: 'Revenue',
        value: '\$3,200',
        period: 'May 2026',
        delta: '+12%',
        isPositive: true,
        icon: const Icon(Icons.bar_chart_rounded, color: _AppColors.info, size: 22),
      ),
      _StatCardData(
        title: 'Avg Revenue',
        value: '\$2,300',
        period: 'May 2026',
        delta: '+210%',
        isPositive: true,
        icon: const Icon(Icons.trending_up_rounded, color: _AppColors.success, size: 22),
      ),
      _StatCardData(
        title: 'Customers',
        value: '14,230',
        period: 'May 2026',
        delta: '+8%',
        isPositive: true,
        icon: const Icon(Icons.group_rounded, color: _AppColors.warning, size: 22),
      ),
    ];

    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _StatCard(
                    title: s.title,
                    value: s.value,
                    period: s.period,
                    delta: s.delta,
                    isPositive: s.isPositive,
                    icon: s.icon,
                  ),
                ),
              ))
          .toList(),
    );
  }

  // ── MIDDLE ROW: Revenue chart + Website Visitors ──────────────────────────

  Widget _buildMiddleRow() {
    return SizedBox(
      height: 380,
      child: Row(
        children: [
          // Revenue chart card
          Expanded(
            flex: 2,
            child: _DashCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    title: 'Revenue Overview',
                    trailing: Row(
                      children: const [
                        _LegendItem(color: Colors.blue, label: 'Facebook Ads'),
                        SizedBox(width: 14),
                        _LegendItem(color: Colors.green, label: 'Google Ads'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: _AppColors.divider),
                  Expanded(
                    child: Center(
                      child: Image.asset('assets/graph3.png', fit: BoxFit.contain),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Website visitors
          Expanded(
            flex: 1,
            child: _DashCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardHeader(title: 'Website Visitors'),
                  const SizedBox(height: 12),
                  Center(
                    child: CircleAvatar(
                      radius: 80,
                      backgroundColor: _AppColors.surface,
                      backgroundImage: const AssetImage('assets/piechart1.png'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: _AppColors.divider),
                  ..._buildVisitorItems(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVisitorItems() {
    final items = [
      ('Direct', '38%', Colors.orange),
      ('Organic', '22%', Colors.green),
      ('Paid', '38%', Colors.lightBlue),
      ('Social', '28%', Colors.red),
    ];
    return items
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: item.$3, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Text(item.$1, style: _AppText.label),
                  const Spacer(),
                  Text(item.$2, style: _AppText.label.copyWith(color: _AppColors.textPrimary)),
                ],
              ),
            ))
        .toList();
  }

  // ── BOTTOM ROW: Top Selling Products + New Customers + Buyers Profile ─────

  Widget _buildBottomRow() {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: _buildProductTableSection(),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 1,
        child: Column(
          children: [
            _buildRecentUsersSection(),
            const SizedBox(height: 10),
            _DashCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardHeader(
                    title: 'Buyers Profile',
                    trailing: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_horiz_rounded, color: _AppColors.textMuted, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: _AppColors.surface,
                        backgroundImage: const AssetImage('assets/pie2.png'),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProfileLegendRow(Colors.orange, 'Male', '50%'),
                            const SizedBox(height: 10),
                            _buildProfileLegendRow(Colors.green, 'Female', '35%'),
                            const SizedBox(height: 10),
                            _buildProfileLegendRow(Colors.pink, 'Others', '15%'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  Widget _buildProfileLegendRow(Color color, String label, String percent) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: _AppText.label),
        const Spacer(),
        Text(percent, style: _AppText.label.copyWith(color: _AppColors.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  int _userCurrentPage = 0;
final int _usersPerPage = 3;

Widget _buildRecentUsersSection() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: Supabase.instance.client
        .from('tbl_user')
        .select()
        .order('user_id', ascending: true),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator(color: _AppColors.accent)),
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return const SizedBox(
          height: 200,
          child: Center(child: Text('Failed to load users', style: _AppText.body)),
        );
      }

      final allUsers = snapshot.data!;
      final totalUsers = allUsers.length;
      final totalPages = (totalUsers / _usersPerPage).ceil();

      if (_userCurrentPage >= totalPages && totalPages > 0) {
        _userCurrentPage = totalPages - 1;
      }

      final startIndex = _userCurrentPage * _usersPerPage;
      final endIndex = (startIndex + _usersPerPage) > totalUsers 
          ? totalUsers 
          : (startIndex + _usersPerPage);

      final displayedUsers = totalUsers > 0 
          ? allUsers.sublist(startIndex, endIndex) 
          : [];

      return _DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('New Customers', style: _AppText.h3),
                const Spacer(),
                if (totalPages > 1)
                  Row(
                    children: List.generate(totalPages, (index) {
                      final isSelected = index == _userCurrentPage;
                      return GestureDetector(
                        onTap: () => setState(() => _userCurrentPage = index),
                        child: Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSelected ? _AppColors.accent : _AppColors.surface,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _AppColors.divider),
                          ),
                          child: Text(
                            'P${index + 1}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : _AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (totalUsers == 0)
              const SizedBox(
                height: 120,
                child: Center(child: Text('No new users', style: _AppText.body)),
              )
            else
              Column(
                children: displayedUsers.map((user) {
                  final name = user['user_name']?.toString() ?? 'No Name';
                  final email = user['user_email']?.toString() ?? '';
                  final photoUrl = user['user_photo']?.toString() ?? '';
                  final status = user['user_status']?.toString() ?? 'pending';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: _AppColors.surface,
                          backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                          child: photoUrl.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                  style: const TextStyle(color: _AppColors.textSecondary, fontWeight: FontWeight.w600),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: _AppText.label.copyWith(color: _AppColors.textPrimary)),
                              if (email.isNotEmpty)
                                Text(email, style: _AppText.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: status == 'approved' ? _AppColors.success : _AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      );
    },
  );
}

  int _productCurrentPage = 0;
final int _productsPerPage = 5;

Widget _buildProductTableSection() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: Supabase.instance.client
        .from('tbl_product')
        .select()
        .order('product_id', ascending: true),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const SizedBox(
          height: 300,
          child: Center(child: CircularProgressIndicator(color: _AppColors.accent)),
        );
      }
      if (snapshot.hasError || !snapshot.hasData) {
        return const SizedBox(
          height: 300,
          child: Center(child: Text('Failed to load products', style: _AppText.body)),
        );
      }

      final allProducts = snapshot.data!;
      final totalProducts = allProducts.length;
      final totalPages = (totalProducts / _productsPerPage).ceil();
      
      if (_productCurrentPage >= totalPages && totalPages > 0) {
        _productCurrentPage = totalPages - 1;
      }

      final startIndex = _productCurrentPage * _productsPerPage;
      final endIndex = (startIndex + _productsPerPage) > totalProducts 
          ? totalProducts 
          : (startIndex + _productsPerPage);
      
      final displayedProducts = totalProducts > 0 
          ? allProducts.sublist(startIndex, endIndex) 
          : [];

      return _DashCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Top Selling Products', style: _AppText.h3),
                const Spacer(),
                if (totalPages > 1)
                  Row(
                    children: List.generate(totalPages, (index) {
                      final isSelected = index == _productCurrentPage;
                      return GestureDetector(
                        onTap: () => setState(() => _productCurrentPage = index),
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? _AppColors.accent : _AppColors.surface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _AppColors.divider),
                          ),
                          child: Text(
                            'Tab ${index + 1}',
                            style: TextStyle(
                              color: isSelected ? Colors.white : _AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: _AppColors.divider),
            if (totalProducts == 0)
              const SizedBox(
                height: 200,
                child: Center(child: Text('No products available', style: _AppText.body)),
              )
            else
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  columnSpacing: 24,
                  headingRowHeight: 40,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 60,
                  horizontalMargin: 0,
                  dividerThickness: 1,
                  headingRowColor: WidgetStateProperty.all(Colors.transparent),
                  dataRowColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      return _AppColors.surface;
                    }
                    return Colors.transparent;
                  }),
                  columns: const [
                    DataColumn(label: Text('Product', style: TextStyle(color: _AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12))),
                    DataColumn(label: Text('Orders', style: TextStyle(color: _AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12))),
                    DataColumn(label: Text('Price', style: TextStyle(color: _AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12))),
                    DataColumn(label: Text('Level/Heat', style: TextStyle(color: _AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12))),
                    DataColumn(label: Text('Details', style: TextStyle(color: _AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12))),
                  ],
                  rows: displayedProducts.map((product) {
                    final pName = product['product_name']?.toString() ?? 'Unknown';
                    final pDesc = product['product_description']?.toString() ?? '';
                    final pPrice = product['product_price']?.toString() ?? '0';
                    final pPhoto = product['product_photo']?.toString() ?? '';
                    final levelId = product['level_id']?.toString() ?? '-';
                    final heatAbs = product['heatabsorption_id']?.toString() ?? '-';

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  image: pPhoto.isNotEmpty
                                      ? DecorationImage(image: NetworkImage(pPhoto), fit: BoxFit.cover)
                                      : null,
                                ),
                                child: pPhoto.isEmpty 
                                    ? const Icon(Icons.image, size: 16, color: _AppColors.textMuted) 
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(pName, style: const TextStyle(fontWeight: FontWeight.w600, color: _AppColors.textPrimary, fontSize: 13)),
                                  Text(pDesc, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: _AppColors.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const DataCell(Text('0', style: TextStyle(color: _AppColors.textSecondary, fontSize: 13))),
                        DataCell(Text('\$$pPrice', style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13))),
                        DataCell(Text('L: $levelId / H: $heatAbs', style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: _AppColors.surface, borderRadius: BorderRadius.circular(6)),
                            child: const Text('View', style: TextStyle(color: _AppColors.textSecondary, fontSize: 12)),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      );
    },
  );
}
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR ICON BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _TopBarIcon extends StatelessWidget {
  final IconData icon;
  final String? badge;
  final VoidCallback onTap;

  const _TopBarIcon({required this.icon, required this.onTap, this.badge});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _AppColors.divider),
          ),
          child: IconButton(
            onPressed: onTap,
            icon: Icon(icon, size: 18, color: _AppColors.textSecondary),
            padding: EdgeInsets.zero,
          ),
        ),
        if (badge != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(color: _AppColors.accent, shape: BoxShape.circle),
              child: Center(
                child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEARCH BOX (for Top Selling Products)
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 200,
      decoration: BoxDecoration(
        color: _AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _AppColors.divider),
      ),
      child: const TextField(
        style: TextStyle(color: _AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search products...',
          hintStyle: TextStyle(color: _AppColors.textMuted, fontSize: 13),
          prefixIcon: Icon(Icons.search_rounded, color: _AppColors.textMuted, size: 16),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DATA TABLE ROW BUILDER (top-level, preserved from original)
// ─────────────────────────────────────────────────────────────────────────────
DataRow buildDataRow(
  String title,
  String subTitle,
  IconData icon,
  String orders,
  String price,
  String ads,
  String refunds,
  Color accentColor,
) {
  return DataRow(
    cells: [
      DataCell(
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subTitle,
                  style: const TextStyle(fontSize: 11, color: _AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      DataCell(Text(orders, style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13))),
      DataCell(Text(price, style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13))),
      DataCell(Text(ads, style: const TextStyle(color: _AppColors.textSecondary, fontSize: 13))),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _AppColors.surface,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(refunds, style: const TextStyle(color: _AppColors.textSecondary, fontSize: 12)),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SIDEBAR NORMAL MENU (top-level, preserved as public API for other files)
// ─────────────────────────────────────────────────────────────────────────────
Widget buildNormalMenu(BuildContext context, IconData icon, String title, Widget page) {
  return _NavItem(icon: icon, title: title, page: page);
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// A fade page route for smoother navigation.
PageRoute _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 200),
  );
}

/// Simple data holder for stat cards.
class _StatCardData {
  final String title, value, period, delta;
  final bool isPositive;
  final Widget icon;

  const _StatCardData({
    required this.title,
    required this.value,
    required this.period,
    required this.delta,
    required this.isPositive,
    required this.icon,
  });
}