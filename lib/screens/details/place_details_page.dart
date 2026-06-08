// screens/details/place_details_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // প্রোভাইডার যুক্ত করা হয়েছে
import '../../providers/theme_provider.dart'; // আপনার পাথ চেক করে নিবেন

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
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
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

  // --- Real Database Booking Logic ---
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
      // বটম শিট এখন থিম অনুযায়ী কালার নিবে
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
              Icon(
                Icons.verified_user,
                color: themeProvider.accentColor, // ডাইনামিক কালার
                size: 50,
              ),
              const SizedBox(height: 15),
              const Text(
                "Confirm Trip",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  // টেক্সট কালার অটো থিম অনুযায়ী হবে
                ),
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
                        backgroundColor:
                            themeProvider.accentColor, // ডাইনামিক বাটন
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
            Expanded(
              child: Text("Booking Successful! Saved in your history."),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      // ব্যাকগ্রাউন্ড থিম অনুযায়ী অটো চেঞ্জ হবে
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

  Widget _buildAppBar(ThemeProvider themeProvider) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      // ব্যাকগ্রাউন্ড থিম থেকে নিবে
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
            "Price",
            "৳${widget.place['price_estimate']}",
            themeProvider,
          ),
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
        backgroundColor: themeProvider.accentColor, // আপনার সিলেক্ট করা কালার
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
