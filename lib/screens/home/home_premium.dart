// screens/home/home_premium.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../home/all_places_page.dart';
import '../details/place_details_page.dart';
import '../shop/gear_shop_page.dart';
import '../plan/AI_help_plan_trip_page.dart';
import '../notifications/notifications_page.dart';
import '../map/map_page.dart';

class HomePremium extends StatefulWidget {
  const HomePremium({super.key});

  @override
  State<HomePremium> createState() => _HomePremiumState();
}

class _HomePremiumState extends State<HomePremium>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late AnimationController _fabAnimController;
  late Animation<double> _fabScaleAnim;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fabScaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning,';
    if (hour >= 12 && hour < 17) return 'Good afternoon,';
    if (hour >= 17 && hour < 21) return 'Good evening,';
    return 'Good night,';
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = (user?.userMetadata?['full_name'] as String? ?? 'Traveler')
        .split(' ')
        .first;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    final bg = isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withValues(alpha: 0.8)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary =
        isDark ? const Color(0xFFE2E8F4) : const Color(0xFF0D1117);
    final textSecondary =
        isDark ? const Color(0xFF4A5478) : const Color(0xFF8892A4);

    return Scaffold(
      backgroundColor: bg,
      floatingActionButton: _buildAIFab(
        accentColor,
        isDark,
        surface,
        surfaceBorder,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Custom top bar (greeting hard-left) ──
              _buildTopBar(
                userName,
                accentColor,
                isDark,
                surface,
                surfaceBorder,
                textPrimary,
                textSecondary,
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(
                      accentColor,
                      isDark,
                      surface,
                      surfaceBorder,
                      textSecondary,
                    ),
                    const SizedBox(height: 24),
                    _buildHeroBanner(accentColor, isDark),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'Trending places',
                      'See all',
                      textPrimary,
                      textSecondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AllPlacesPage(title: 'All Places'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTrendingPlaces(
                      accentColor,
                      isDark,
                      surface,
                      surfaceBorder,
                    ),
                    const SizedBox(height: 28),
                    _buildSectionHeader(
                      'Categories',
                      null,
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 14),
                    _buildCategories(
                      accentColor,
                      isDark,
                      surface,
                      surfaceBorder,
                      textSecondary,
                    ),
                    const SizedBox(height: 28),
                    _buildShopCard(
                      accentColor,
                      isDark,
                      surface,
                      surfaceBorder,
                      textPrimary,
                      textSecondary,
                    ),
                    const SizedBox(height: 140),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  TOP BAR  —  greeting pinned to left corner, map + notification to right
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopBar(
    String userName,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left — greeting + name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wb_sunny_outlined, color: accentColor, size: 12),
                    const SizedBox(width: 5),
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          // Right — map + notification buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Map button
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BDMapPage(),
                  ),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: surfaceBorder, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.map_outlined,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Notification bell
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsPage()),
                ),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: surfaceBorder, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        color: accentColor,
                        size: 20,
                      ),
                      Positioned(
                        top: 9,
                        right: 9,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF080C18)
                                  : Colors.white,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  SEARCH BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: surfaceBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AllPlacesPage(title: 'Search: $value'),
              ),
            );
          }
        },
        style: TextStyle(
          color: isDark ? const Color(0xFFE2E8F4) : const Color(0xFF0D1117),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Search destinations...',
          hintStyle: TextStyle(
            color: isDark ? const Color(0xFF2E3A56) : const Color(0xFFBBC3D4),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.search_rounded, color: textSecondary, size: 20),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.all(8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Icon(Icons.tune_rounded, color: accentColor, size: 16),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  HERO BANNER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeroBanner(Color accentColor, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.15), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(accentColor)),
          ),
          // top-right radial glow
          Positioned(
            right: -40,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.12),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          // bottom-left subtle glow
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.07),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // pill label
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.25),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: accentColor,
                              size: 11,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Explore Bangladesh',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Discover hidden\ngems & wonders',
                        style: TextStyle(
                          color: Color(0xFFE2E8F4),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AllPlacesPage(title: 'All Places'),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Start exploring',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 5),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // right-side decorative icons
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.2),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.travel_explore_rounded,
                        color: accentColor,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 38,
                      height: 38,
                      margin: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.landscape_outlined,
                        color: Color(0xFF4A6A8A),
                        size: 18,
                      ),
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

  // ───────────────────────────────────────────────────────────────────────────
  //  SECTION HEADER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
    String title,
    String? action,
    Color textPrimary,
    Color textSecondary, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                action,
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  TRENDING PLACES
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTrendingPlaces(
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
  ) {
    return SizedBox(
      height: 220,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('places').select(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load places',
                style: TextStyle(
                  color: isDark ? const Color(0xFF4A5478) : Colors.black38,
                  fontSize: 13,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (_, __) =>
                  _buildSkeletonCard(isDark, surface, surfaceBorder),
            );
          }
          final places = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: places.length,
            itemBuilder: (_, index) => _buildPlaceCard(
              places[index],
              accentColor,
              isDark,
              surface,
              surfaceBorder,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonCard(bool isDark, Color surface, Color surfaceBorder) {
    final shimmer = isDark ? const Color(0xFF1A2240) : const Color(0xFFEEF0F5);
    return Container(
      width: 165,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: shimmer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: surfaceBorder, width: 0.5),
      ),
    );
  }

  Widget _buildPlaceCard(
    Map<String, dynamic> place,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlaceDetailsPage(place: place)),
      ),
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: surfaceBorder, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Image.network(
              place['image_url'] ?? '',
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color:
                    isDark ? const Color(0xFF111827) : const Color(0xFFEEF0F5),
                child: Center(
                  child: Icon(
                    Icons.image_not_supported_outlined,
                    color: isDark ? const Color(0xFF2E3A56) : Colors.black12,
                    size: 32,
                  ),
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xF2030710), Colors.transparent],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 0.5,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      color: Colors.orangeAccent,
                      size: 10,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Trending',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 14,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place['name'] ?? 'Unknown',
                    style: const TextStyle(
                      color: Color(0xFFE2E8F4),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF6A7A9A),
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          place['location'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFF6A7A9A),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  CATEGORIES
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategories(
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textSecondary,
  ) {
    final categories = [
      {'icon': Icons.landscape_outlined, 'label': 'Nature'},
      {'icon': Icons.hiking_outlined, 'label': 'Adventure'},
      {'icon': Icons.beach_access_outlined, 'label': 'Beach'},
      {'icon': Icons.hotel_outlined, 'label': 'Resorts'},
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories
          .map(
            (c) => _buildCategoryItem(
              c['icon'] as IconData,
              c['label'] as String,
              accentColor,
              isDark,
              surface,
              surfaceBorder,
              textSecondary,
            ),
          )
          .toList(),
    );
  }

  Widget _buildCategoryItem(
    IconData icon,
    String label,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textSecondary,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AllPlacesPage(title: '$label Places', category: label),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: surfaceBorder, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  SHOP CARD
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildShopCard(
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: surfaceBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.15),
                width: 0.5,
              ),
            ),
            child: Icon(Icons.backpack_outlined, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Travel Gear Shop',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        '20% OFF',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'on first purchase',
                      style: TextStyle(color: textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GearShopPage()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Shop',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  //  AI FAB
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildAIFab(
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
  ) {
    return AnimatedBuilder(
      animation: _fabAnimController,
      builder: (_, __) => Transform.scale(
        scale: _fabScaleAnim.value,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1628),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.28),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AITripPage()),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.22),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'AI Trip Planner',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Get a smart itinerary with Bhromon',
                            style: TextStyle(
                              color: Color(0xFF3D4A6A),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: accentColor.withValues(alpha: 0.7),
                        size: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── GRID PAINTER ──────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color color;
  _GridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.045)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.color != color;
}
