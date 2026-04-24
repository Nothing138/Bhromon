// screens/details/place_details_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlaceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> place;
  const PlaceDetailsPage({super.key, required this.place});

  @override
  State<PlaceDetailsPage> createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  bool _isSaved = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfSaved();
  }

  Future<void> _checkIfSaved() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || widget.place['id'] == null) {
      setState(() => _isLoading = false);
      return;
    }

    final response = await Supabase.instance.client
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
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() => _isSaved = !_isSaved);

    if (_isSaved) {
      await Supabase.instance.client.from('favorites').insert({
        'user_id': user.id,
        'place_id': widget.place['id'],
      });
    } else {
      await Supabase.instance.client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('place_id', widget.place['id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.place['image_url'] ?? '',
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xFF0F172A), Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  onPressed: _isLoading ? null : _toggleFavorite,
                  icon: Icon(
                    _isSaved ? Icons.favorite : Icons.favorite_border,
                    color: _isSaved ? Colors.red : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 15),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.place['name'],
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFFF4B400),
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.place['location'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoColumn("Rating", "4.8"),
                        _buildInfoColumn(
                          "Price",
                          "৳${widget.place['price_estimate']}",
                        ),
                        _buildInfoColumn("Reviews", "240"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    "About Destination",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.place['description'] ?? "No description available.",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
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
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xFFF4B400),
          onPressed: () {
            /* Add Booking Logic */
          },
          label: const Text(
            "BOOK THIS TRIP",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
