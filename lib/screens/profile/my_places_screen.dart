// screens/profile/my_places_screen.dart
//  My Places Screen - User added places

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'add_place_screen.dart';

class MyPlacesScreen extends StatefulWidget {
  const MyPlacesScreen({super.key});

  @override
  State<MyPlacesScreen> createState() => _MyPlacesScreenState();
}

class _MyPlacesScreenState extends State<MyPlacesScreen> {
  final supabase = Supabase.instance.client;
  late Future<List<Map<String, dynamic>>> _userPlaces;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  void _loadPlaces() {
    _userPlaces = _fetchPlaces();
  }

  Future<List<Map<String, dynamic>>> _fetchPlaces() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final places = await supabase
          .from('user_added_places')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(places);
    } catch (e) {
      debugPrint('Error loading places: $e');
      rethrow;
    }
  }

  Future<void> _deletePlace(String placeId) async {
    try {
      await supabase.from('user_added_places').delete().eq('id', placeId);

      setState(() => _loadPlaces());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place deleted successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting place: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String placeName, String placeId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Place?'),
        content: Text('Are you sure you want to delete "$placeName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deletePlace(placeId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final accentColor = themeProvider.accentColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'My Places',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.add, color: accentColor, size: 20),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
                );
                if (result == true) setState(() => _loadPlaces());
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _userPlaces,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: accentColor),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error loading places',
                      style: TextStyle(color: textColor)),
                ],
              ),
            );
          }

          final places = snapshot.data ?? [];

          if (places.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 64,
                    color: accentColor.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No places yet',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add places to build your travel memory',
                    style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddPlaceScreen()),
                      );
                      if (result == true) setState(() => _loadPlaces());
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Place'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: places.length,
            itemBuilder: (context, index) => _buildPlaceCard(
              places[index],
              cardColor,
              isDark,
              textColor,
              accentColor,
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceCard(
    Map<String, dynamic> place,
    Color cardColor,
    bool isDark,
    Color textColor,
    Color accentColor,
  ) {
    final hasImage = (place['image_url'] as String?)?.isNotEmpty ?? false;
    final rating = place['rating'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip
          .antiAlias, // 👈 overflow প্রপার্টিটি কেটে এখানে clipBehavior যোগ করা হয়েছে
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Image.network(
                place['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: accentColor.withValues(alpha: 0.1),
                  child: Icon(Icons.image_not_supported, color: accentColor),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        place['name'] ?? 'Unknown',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showDeleteConfirmation(
                        place['name'] ?? 'Place',
                        place['id'],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                if (place['location'] != null &&
                    (place['location'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: accentColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place['location'],
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (place['category'] != null &&
                    (place['category'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        place['category'],
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (rating != null && rating > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < rating ? Icons.star : Icons.star_outline,
                            size: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
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
