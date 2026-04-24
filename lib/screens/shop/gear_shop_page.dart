// screens/shop/gear_shop_page.dart
import 'package:flutter/material.dart';

class GearShopPage extends StatelessWidget {
  const GearShopPage({super.key});

  // Database-e data na thakle eita dummy list
  final List<Map<String, dynamic>> dummyGears = const [
    {
      "name": "Hiking Backpack",
      "price": "2500",
      "image": "https://images.unsplash.com/photo-1553062407-98eeb64c6a62",
    },
    {
      "name": "Trekking Boots",
      "price": "4200",
      "image": "https://images.unsplash.com/photo-1520639889456-1136bc752efc",
    },
    {
      "name": "Camping Tent",
      "price": "5500",
      "image": "https://images.unsplash.com/photo-1504280390367-361c6d9f38f4",
    },
    {
      "name": "Water Bottle",
      "price": "850",
      "image": "https://images.unsplash.com/photo-1602143393494-138379326461",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Travel Gear Shop",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemCount: dummyGears.length,
        itemBuilder: (context, index) {
          final gear = dummyGears[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
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
                      gear['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gear['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "৳${gear['price']}",
                        style: const TextStyle(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Add to Cart"),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
