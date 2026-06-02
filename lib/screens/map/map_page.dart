// screens/map/map_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../details/place_details_page.dart';

class BDMapPage extends StatefulWidget {
  const BDMapPage({super.key});

  @override
  State<BDMapPage> createState() => _BDMapPageState();
}

class _BDMapPageState extends State<BDMapPage> with TickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final MapController _mapController = MapController();

  List<Map<String, dynamic>> _places = [];
  Map<String, dynamic>? _selectedPlace;
  bool _isLoading = true;

  late AnimationController _cardAnimController;
  late Animation<Offset> _cardSlideAnim;
  late Animation<double> _cardFadeAnim;

  // Bangladesh center
  static const LatLng _bdCenter = LatLng(23.6850, 90.3563);

  // Fallback coordinates for known BD tourist places
  static const Map<String, LatLng> _locationFallbacks = {
    "Cox's Bazar": LatLng(21.4272, 92.0058),
    "Sundarbans": LatLng(21.9497, 89.1833),
    "Sajek Valley": LatLng(23.3810, 92.2936),
    "Saint Martin's Island": LatLng(20.6270, 92.3215),
    "Bandarban": LatLng(22.1953, 92.2184),
    "Sreemangal": LatLng(24.3083, 91.7267),
    "Rangamati": LatLng(22.6430, 92.1800),
    "Kuakata": LatLng(21.8269, 90.1168),
    "Ratargul": LatLng(25.0128, 91.8577),
    "Mahasthangarh": LatLng(24.9742, 89.3719),
    "Paharpur": LatLng(25.0314, 88.9739),
    "Lalbagh Fort": LatLng(23.7169, 90.3869),
    "Ahsan Manzil": LatLng(23.7106, 90.4060),
    "Srimangal": LatLng(24.3083, 91.7267),
  };

  @override
  void initState() {
    super.initState();
    _cardAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _cardSlideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _cardAnimController,
            curve: Curves.easeOutCubic,
          ),
        );
    _cardFadeAnim = CurvedAnimation(
      parent: _cardAnimController,
      curve: Curves.easeOut,
    );
    _loadPlaces();
  }

  @override
  void dispose() {
    _cardAnimController.dispose();
    super.dispose();
  }

  LatLng? _getCoords(Map<String, dynamic> place) {
    final lat = place['latitude'];
    final lng = place['longitude'];
    if (lat != null && lng != null) {
      return LatLng((lat as num).toDouble(), (lng as num).toDouble());
    }
    // Try fallback by name or location field
    final name = place['name'] as String? ?? '';
    final loc = place['location'] as String? ?? '';
    for (final entry in _locationFallbacks.entries) {
      if (name.contains(entry.key) || loc.contains(entry.key)) {
        return entry.value;
      }
    }
    // Try direct key match
    return _locationFallbacks[name] ?? _locationFallbacks[loc];
  }

  Future<void> _loadPlaces() async {
    try {
      final data = await supabase.from('places').select();
      setState(() {
        _places = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onMarkerTap(Map<String, dynamic> place) {
    setState(() => _selectedPlace = place);
    _cardAnimController.forward(from: 0);
    final coords = _getCoords(place);
    if (coords != null) {
      _mapController.move(
        LatLng(coords.latitude - 0.8, coords.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  void _dismissCard() {
    _cardAnimController.reverse().then((_) {
      if (mounted) setState(() => _selectedPlace = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = themeProvider.accentColor;
    final isDark = themeProvider.isDarkMode;

    final bg = isDark ? const Color(0xFF080C18) : const Color(0xFFF5F7FF);
    final surface = isDark ? const Color(0xFF111827) : Colors.white;
    final surfaceBorder = isDark
        ? const Color(0xFF1E2A42).withOpacity(0.8)
        : Colors.black.withOpacity(0.06);
    final textPrimary = isDark
        ? const Color(0xFFE2E8F4)
        : const Color(0xFF0D1117);
    final textSecondary = isDark
        ? const Color(0xFF4A5478)
        : const Color(0xFF8892A4);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bg,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: surfaceBorder, width: 0.5),
            ),
            child: Icon(Icons.arrow_back_rounded, color: accentColor, size: 20),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            children: [
              Icon(Icons.map_outlined, color: accentColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Bangladesh Map',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: accentColor.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.place_outlined, color: accentColor, size: 13),
                const SizedBox(width: 4),
                Text(
                  '${_places.length} Places',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: accentColor,
                      strokeWidth: 2,
                    ),
                  )
                : FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _bdCenter,
                      initialZoom: 7.0,
                      minZoom: 5.0,
                      maxZoom: 16.0,
                      onTap: (_, __) {
                        if (_selectedPlace != null) _dismissCard();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: isDark
                            ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                            : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: const ['a', 'b', 'c', 'd'],
                        userAgentPackageName: 'com.bhromon.app',
                      ),
                      MarkerLayer(markers: _buildMarkers(accentColor)),
                    ],
                  ),
          ),

          // Bottom detail card
          if (_selectedPlace != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _cardSlideAnim,
                child: FadeTransition(
                  opacity: _cardFadeAnim,
                  child: _buildPlaceCard(
                    _selectedPlace!,
                    accentColor,
                    isDark,
                    surface,
                    surfaceBorder,
                    textPrimary,
                    textSecondary,
                  ),
                ),
              ),
            ),

          // Legend
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: surface.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: surfaceBorder, width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Tourist Spot',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers(Color accentColor) {
    final markers = <Marker>[];
    for (final place in _places) {
      final coords = _getCoords(place);
      if (coords == null) continue;
      markers.add(
        Marker(
          point: coords,
          width: 44,
          height: 52,
          child: GestureDetector(
            onTap: () => _onMarkerTap(place),
            child: _buildPinWidget(place, accentColor),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildPinWidget(Map<String, dynamic> place, Color accentColor) {
    final isSelected = _selectedPlace?['id'] == place['id'];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isSelected ? 44 : 36,
            height: isSelected ? 44 : 36,
            decoration: BoxDecoration(
              color: isSelected ? accentColor : const Color(0xFF0D1829),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? accentColor.withOpacity(0.5)
                    : accentColor.withOpacity(0.3),
                width: isSelected ? 2.5 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(isSelected ? 0.5 : 0.25),
                  blurRadius: isSelected ? 14 : 8,
                  spreadRadius: isSelected ? 2 : 0,
                ),
              ],
            ),
            child: Icon(
              Icons.place_rounded,
              color: isSelected ? Colors.white : accentColor,
              size: isSelected ? 22 : 18,
            ),
          ),
          // Pin tail
          Container(
            width: 2,
            height: 8,
            decoration: BoxDecoration(
              color: isSelected ? accentColor : accentColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(
    Map<String, dynamic> place,
    Color accentColor,
    bool isDark,
    Color surface,
    Color surfaceBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    final imageUrl = place['image_url'] as String?;
    final name = place['name'] as String? ?? 'Unknown';
    final location = place['location'] as String? ?? '';
    final category = place['category'] as String? ?? '';
    final price = place['price_estimate'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: surfaceBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                // Image thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: (imageUrl != null && imageUrl.isNotEmpty)
                      ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imagePlaceholder(isDark, accentColor),
                        )
                      : _imagePlaceholder(isDark, accentColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (location.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (category.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: accentColor.withOpacity(0.2),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                category,
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          if (price != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              '৳${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: Colors.greenAccent.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _dismissCard,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E2A42)
                            : const Color(0xFFF0F2F8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Close',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      _dismissCard();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaceDetailsPage(place: place),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.explore_outlined,
                            color: Colors.white,
                            size: 15,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark, Color accentColor) {
    return Container(
      width: 80,
      height: 80,
      color: isDark ? const Color(0xFF1E2A42) : const Color(0xFFEEF0F5),
      child: Icon(
        Icons.image_not_supported_outlined,
        color: accentColor.withOpacity(0.4),
        size: 28,
      ),
    );
  }
}
