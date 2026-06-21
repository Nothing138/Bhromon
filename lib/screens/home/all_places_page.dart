// screens/home/all_places_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; // প্রোভাইডার যুক্ত করা হয়েছে
import '../../providers/theme_provider.dart'; // আপনার পাথ অনুযায়ী চেক করে নিন
import '../details/place_details_page.dart';

class AllPlacesPage extends StatelessWidget {
  final String title;
  final String? category;

  const AllPlacesPage({super.key, required this.title, this.category});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    // থিম প্রোভাইডার কল করা হয়েছে
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    Future<List<Map<String, dynamic>>> fetchPlaces() async {
      var query = supabase.from('places').select();

      if (category != null && category != "All") {
        query = query.eq('category', category!);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    }

    return Scaffold(
      // ব্যাকগ্রাউন্ড এখন থিম থেকে অটোমেটিক নিবে
      appBar: AppBar(
        title: Text(
          category != null ? "$category Places" : title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // আইকন কালার থিম অনুযায়ী সাদা বা কালো হবে
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPlaces(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: themeProvider.accentColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final places = snapshot.data ?? [];

          if (places.isEmpty) {
            return const Center(
              child: Text(
                "No places found in this category!",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
            ),
            itemCount: places.length,
            itemBuilder: (context, index) {
              final place = places[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaceDetailsPage(place: place),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    // কার্ডের ব্যাকগ্রাউন্ড ডার্ক মোডে একটু উজ্জ্বল রাখা হয়েছে
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            place['image_url'] ?? '',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              place['name'] ?? 'Unknown Place',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    place['location'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Est. ৳${place['price_estimate'] ?? '0'}",
                              style: TextStyle(
                                color:
                                    themeProvider.accentColor, // ডাইনামিক কালার
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
