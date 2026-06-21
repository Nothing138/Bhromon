// services/nearby_places_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class NearbyPlace {
  final String name;
  final String type;
  final String description;
  final String priceRange;
  final double rating;
  final String distanceText;
  final String walkingTime;
  final String drivingTime;
  final String rickshawTime;
  final String address;
  final String specialty;

  NearbyPlace({
    required this.name,
    required this.type,
    required this.description,
    required this.priceRange,
    required this.rating,
    required this.distanceText,
    required this.walkingTime,
    required this.drivingTime,
    required this.rickshawTime,
    required this.address,
    required this.specialty,
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    return NearbyPlace(
      name: json['name'] ?? 'Unknown',
      type: json['type'] ?? 'hotel',
      description: json['description'] ?? '',
      priceRange: json['price_range'] ?? '৳500-1000',
      rating: (json['rating'] ?? 4.0).toDouble(),
      distanceText: json['distance_text'] ?? '1 km',
      walkingTime: json['walking_time'] ?? '12 min walk',
      drivingTime: json['driving_time'] ?? '3 min drive',
      rickshawTime: json['rickshaw_time'] ?? '5 min by rickshaw',
      address: json['address'] ?? '',
      specialty: json['specialty'] ?? '',
    );
  }
}

class NearbyPlacesService {
  static const String _apiKey =
      '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';
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  static Future<Map<String, List<NearbyPlace>>> fetchNearbyPlaces({
    required String placeName,
    required String location,
  }) async {
    // FIX: Build prompt using string concatenation to avoid interpolation issues
    // inside the JSON template block.
    final prompt = 'You are a local travel expert for Bangladesh. '
        'I need real and well-known nearby hotels/resorts and restaurants '
        'near a tourist spot.\n\n'
        'Tourist Spot: "$placeName"\n'
        'Location/Area: "$location"\n\n'
        'Please provide:\n'
        '- 4 nearby hotels or resorts (real or highly realistic for this area)\n'
        '- 4 nearby restaurants (real or highly realistic for this area)\n\n'
        'For each place, estimate the distance and travel time FROM "$placeName".\n\n'
        'Respond ONLY with a valid JSON object. '
        'No explanation, no markdown, no extra text. No ```json fences.\n\n'
        'Required JSON structure:\n'
        '{\n'
        '  "hotels": [\n'
        '    {\n'
        '      "name": "Hotel Name",\n'
        '      "type": "hotel",\n'
        '      "description": "2-sentence description of the hotel.",\n'
        '      "price_range": "৳2500-5000 per night",\n'
        '      "rating": 4.2,\n'
        '      "distance_text": "2.5 km",\n'
        '      "walking_time": "30 min walk",\n'
        '      "driving_time": "6 min drive",\n'
        '      "rickshaw_time": "10 min by CNG",\n'
        '      "address": "Short address near $location",\n'
        '      "specialty": "e.g. River view, Pool, Garden"\n'
        '    }\n'
        '  ],\n'
        '  "restaurants": [\n'
        '    {\n'
        '      "name": "Restaurant Name",\n'
        '      "type": "restaurant",\n'
        '      "description": "2-sentence description of the restaurant.",\n'
        '      "price_range": "৳200-500 per person",\n'
        '      "rating": 4.5,\n'
        '      "distance_text": "0.8 km",\n'
        '      "walking_time": "10 min walk",\n'
        '      "driving_time": "2 min drive",\n'
        '      "rickshaw_time": "4 min by rickshaw",\n'
        '      "address": "Short address near $location",\n'
        '      "specialty": "e.g. Fresh fish, BBQ, Traditional Bangladeshi"\n'
        '    }\n'
        '  ]\n'
        '}';

    try {
      debugPrint(
          '🔄 NearbyPlaces: Calling Groq API for "$placeName" in "$location"');

      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {'role': 'user', 'content': prompt}
              ],
              'temperature': 0.7,
              'max_tokens': 2000,
            }),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 NearbyPlaces: HTTP status = ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String content = data['choices'][0]['message']['content'] as String;

        debugPrint(
            '✅ NearbyPlaces: Raw response received (${content.length} chars)');

        // Strip any markdown fences the model might add despite instructions
        content =
            content.replaceAll('```json', '').replaceAll('```', '').trim();

        // Find the JSON object boundaries in case there is any leading/trailing text
        final startIndex = content.indexOf('{');
        final endIndex = content.lastIndexOf('}');
        if (startIndex == -1 || endIndex == -1) {
          debugPrint('❌ NearbyPlaces: Could not find JSON braces in response');
          return {'hotels': [], 'restaurants': []};
        }
        content = content.substring(startIndex, endIndex + 1);

        final parsed = jsonDecode(content) as Map<String, dynamic>;

        final hotels = ((parsed['hotels'] ?? []) as List)
            .map((h) => NearbyPlace.fromJson(h as Map<String, dynamic>))
            .toList();

        final restaurants = ((parsed['restaurants'] ?? []) as List)
            .map((r) => NearbyPlace.fromJson(r as Map<String, dynamic>))
            .toList();

        debugPrint('🏨 NearbyPlaces: ${hotels.length} hotels, '
            '🍽 ${restaurants.length} restaurants loaded');

        return {'hotels': hotels, 'restaurants': restaurants};
      } else {
        // Log full error body so you can see what went wrong
        debugPrint(
            '❌ NearbyPlaces: API error ${response.statusCode}: ${response.body}');
        return {'hotels': [], 'restaurants': []};
      }
    } catch (e, stack) {
      debugPrint('❌ NearbyPlaces: Exception: $e');
      debugPrint('$stack');
      return {'hotels': [], 'restaurants': []};
    }
  }
}
