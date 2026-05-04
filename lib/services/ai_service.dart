// services/ai_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AIService {
  // আপনার Gemini API Key এখানে বসান
  static const String _apiKey = 'AIzaSyCqBLBZB5Rpf98LQUYYbmZFTTDBTGAe6v4';

  static Future<String> generateItinerary({
    required String destination,
    required int budget,
    required int days,
    required String style,
  }) async {
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _apiKey);

      // AI-এর জন্য একটি ক্লিয়ার প্রম্পট তৈরি করা
      final prompt =
          """
        You are a Bangladesh Travel Expert. Create a detailed day-wise travel itinerary for ${destination}.
        Strict Rules:
        1. Only suggest tourist spots, hotels, and food located within Bangladesh.
        2. If the user mentions a location outside Bangladesh, politely suggest a similar destination inside Bangladesh (e.g., if they say "Darjeeling", suggest "Sajek Valley").
        3. Duration: ${days} days.
        4. Budget: ${budget} BDT total.
        5. Travel Style: ${style}.
        6. Include estimated costs for transport and local Bangladeshi food.
        """;

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ??
          "Sorry, I couldn't generate a plan. Please try again.";
    } catch (e) {
      debugPrint("AI Generation Error: $e");
      return "Error: Failed to connect to AI service.";
    }
  }
}
