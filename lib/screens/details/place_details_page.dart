// screens/details/place_details_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/nearby_places_service.dart';

class PlaceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> place;
  const PlaceDetailsPage({super.key, required this.place});

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  bool _isSaved = false;
  bool _isLoading = true;
  bool _isBooking = false;
  bool _isLoadingNearby = false;

  List<NearbyPlace> _hotels = [];
  List<NearbyPlace> _restaurants = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
    _loadNearbyPlaces();
  }

  // --- Favorites Logic ---
  Future<void> _checkIfSaved() async {
    final user = supabase.auth.currentUser;
    if (user == null || widget.place['id'] == null) {
      setState(() => _isLoading = false);
      return;
    }

    final response = await supabase
        .from('favorites')
        .select()
        .eq('user_id', user.id)
        .eq('place_id', widget.place['id']);

    if (mounted) {
      setState(() {
        _isSaved = response.isNotEmpty;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaved = !_isSaved);

    try {
      if (_isSaved) {
        await supabase.from('favorites').insert({
          'user_id': user.id,
          'place_id': widget.place['id'],
        });
      } else {
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('place_id', widget.place['id']);
      }
    } catch (e) {
      debugPrint("Favorite error: $e");
    }
  }

  // --- Nearby Places Logic ---
  Future<void> _loadNearbyPlaces() async {
    setState(() => _isLoadingNearby = true);

    final result = await NearbyPlacesService.fetchNearbyPlaces(
      placeName: widget.place['name'] ?? 'this place',
      location: widget.place['location'] ?? 'Bangladesh',
    );

    if (mounted) {
      setState(() {
        _hotels = result['hotels'] ?? [];
        _restaurants = result['restaurants'] ?? [];
        _isLoadingNearby = false;
      });
    }
  }

  // --- Booking Logic ---
  Future<void> _confirmBooking() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isBooking = true);

    try {
      await supabase.from('bookings').insert({
        'user_id': user.id,
        'place_id': widget.place['id'],
        'status': 'confirmed',
      });

      if (mounted) {
        Navigator.pop(context);
        _showSuccessMessage();
      }
    } catch (e) {
      debugPrint("Booking Database Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _handleBooking() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Icon(Icons.verified_user,
                  color: themeProvider.accentColor, size: 50),
              const SizedBox(height: 15),
              const Text(
                "Confirm Trip",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Booking ${widget.place['name']} will cost approx. ৳${widget.place['price_estimate']}. This will be saved to your past trips.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          _isBooking ? null : () => Navigator.pop(context),
                      child: Text(
                        "CANCEL",
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isBooking
                          ? null
                          : () async {
                              setModalState(() => _isBooking = true);
                              await _confirmBooking();
                            },
                      child: _isBooking
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "CONFIRM",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text("Booking Successful! Saved in your history.")),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ──────────────────────────────────────────
  //  BUILD
  // ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(themeProvider),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(themeProvider),
                  const SizedBox(height: 25),
                  _buildInfoCard(isDark, themeProvider),
                  const SizedBox(height: 30),

                  // About Destination
                  const Text(
                    "About Destination",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.place['description'] ?? "No description available.",
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.black87,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Nearby Hotels Section
                  _buildSectionHeader(
                    icon: Icons.hotel,
                    title: "Nearby Hotels & Resorts",
                    subtitle: "Places to stay near this spot",
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 16),
                  _isLoadingNearby
                      ? _buildShimmerLoader(isDark)
                      : _hotels.isEmpty
                          ? _buildEmptyState("No hotels found nearby", isDark)
                          : _buildHorizontalList(
                              _hotels, isDark, themeProvider),

                  const SizedBox(height: 35),

                  // Nearby Restaurants Section
                  _buildSectionHeader(
                    icon: Icons.restaurant,
                    title: "Nearby Restaurants",
                    subtitle: "Where to eat around here",
                    themeProvider: themeProvider,
                  ),
                  const SizedBox(height: 16),
                  _isLoadingNearby
                      ? _buildShimmerLoader(isDark)
                      : _restaurants.isEmpty
                          ? _buildEmptyState(
                              "No restaurants found nearby", isDark)
                          : _buildHorizontalList(
                              _restaurants, isDark, themeProvider),

                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildBookingButton(themeProvider),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ──────────────────────────────────────────
  //  NEARBY WIDGETS
  // ──────────────────────────────────────────

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeProvider themeProvider,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeProvider.accentColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: themeProvider.accentColor, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHorizontalList(
    List<NearbyPlace> places,
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: places.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) =>
            _buildNearbyCard(places[index], isDark, themeProvider),
      ),
    );
  }

  Widget _buildNearbyCard(
    NearbyPlace place,
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    return GestureDetector(
      onTap: () => _showNearbyDetails(place, isDark, themeProvider),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top color banner with icon
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: place.type == 'hotel'
                      ? [
                          themeProvider.accentColor.withOpacity(0.8),
                          themeProvider.accentColor,
                        ]
                      : [
                          Colors.orange.withOpacity(0.8),
                          Colors.deepOrange,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      place.type == 'hotel' ? Icons.hotel : Icons.restaurant,
                      color: Colors.white.withOpacity(0.3),
                      size: 50,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            place.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.specialty,
                    style: TextStyle(
                      color: place.type == 'hotel'
                          ? themeProvider.accentColor
                          : Colors.deepOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Distance badge
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600]),
                      const SizedBox(width: 3),
                      Text(
                        place.distanceText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Travel time chips
                  _buildTravelTimeRow(place, isDark),

                  const SizedBox(height: 8),
                  Text(
                    place.priceRange,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
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

  Widget _buildTravelTimeRow(NearbyPlace place, bool isDark) {
    return Row(
      children: [
        _buildTinyChip(
          Icons.directions_walk,
          place.walkingTime.split(' ').first,
          Colors.green,
          isDark,
        ),
        const SizedBox(width: 4),
        _buildTinyChip(
          Icons.directions_car,
          place.drivingTime.split(' ').first,
          Colors.blue,
          isDark,
        ),
        const SizedBox(width: 4),
        _buildTinyChip(
          Icons.electric_rickshaw,
          place.rickshawTime.split(' ').first,
          Colors.orange,
          isDark,
        ),
      ],
    );
  }

  Widget _buildTinyChip(
    IconData icon,
    String time,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            time,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader(bool isDark) {
    return SizedBox(
      height: 260,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => Container(
          width: 200,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Loading...",
                  style: TextStyle(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, bool isDark) {
    return Container(
      height: 100,
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
      ),
    );
  }

  // Bottom sheet for full details of a nearby place
  void _showNearbyDetails(
    NearbyPlace place,
    bool isDark,
    ThemeProvider themeProvider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Name + rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Specialty tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (place.type == 'hotel'
                        ? themeProvider.accentColor
                        : Colors.deepOrange)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                place.specialty,
                style: TextStyle(
                  color: place.type == 'hotel'
                      ? themeProvider.accentColor
                      : Colors.deepOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              place.description,
              style: TextStyle(
                color: isDark ? Colors.grey[300] : Colors.black87,
                fontSize: 14,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),

            // Address
            Row(
              children: [
                Icon(Icons.location_on,
                    color: themeProvider.accentColor, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    place.address,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Travel time section
            Text(
              "How to get there from ${widget.place['name']}",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTravelCard(
                    Icons.directions_walk,
                    "Walk",
                    place.walkingTime,
                    Colors.green,
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTravelCard(
                    Icons.directions_car,
                    "Drive",
                    place.drivingTime,
                    Colors.blue,
                    isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildTravelCard(
                    Icons.electric_rickshaw,
                    "CNG/Rickshaw",
                    place.rickshawTime,
                    Colors.orange,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Price
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  place.type == 'hotel'
                      ? "Price per night:"
                      : "Price per person:",
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  place.priceRange,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTravelCard(
    IconData icon,
    String mode,
    String time,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            mode,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────
  //  ORIGINAL WIDGETS (unchanged)
  // ──────────────────────────────────────────

  Widget _buildAppBar(ThemeProvider themeProvider) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(widget.place['image_url'] ?? '', fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              onPressed: _isLoading ? null : _toggleFavorite,
              icon: Icon(
                _isSaved ? Icons.favorite : Icons.favorite_border,
                color: _isSaved ? Colors.red : Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.place['name'] ?? 'Awesome Place',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, color: themeProvider.accentColor, size: 18),
            const SizedBox(width: 5),
            Text(
              widget.place['location'] ?? 'Unknown',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(bool isDark, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoColumn("Rating", "★ 4.8", themeProvider),
          _buildInfoColumn(
              "Price", "৳${widget.place['price_estimate']}", themeProvider),
          _buildInfoColumn("Reviews", "240+", themeProvider),
        ],
      ),
    );
  }

  Widget _buildInfoColumn(
    String label,
    String value,
    ThemeProvider themeProvider,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildBookingButton(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      width: double.infinity,
      child: FloatingActionButton.extended(
        backgroundColor: themeProvider.accentColor,
        onPressed: _handleBooking,
        label: const Text(
          "BOOK THIS TRIP",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
