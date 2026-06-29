// services/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AIService {
  static const String _apiKey =
      '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';
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> generateItinerary({
    required String destination,
    required int budget,
    required int days,
    required String style,
  }) async {
    try {
      final prompt = """
You are a Bangladesh Travel Expert. Create a detailed day-wise travel itinerary for $destination, Bangladesh.
Duration: $days days.
Budget: $budget BDT.
Travel Style: $style.

Please provide:
- Day-by-day schedule (morning, afternoon, evening)
- Famous local food spots and must-try dishes
- Transport options (bus, train, launch, CNG)
- Budget breakdown estimate
- Top attractions and hidden gems

Keep everything practical and within Bangladesh only.
""";

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'max_tokens': 1500,
          'temperature': 0.7,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful Bangladesh travel expert who gives detailed, practical travel advice.',
            },
            {'role': 'user', 'content': prompt},
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['choices'][0]['message']['content'] as String;
        return text;
      } else if (response.statusCode == 401) {
        return " Invalid API Key! Get a new key from console.groq.com.";
      } else if (response.statusCode == 429) {
        return "⏳There have been a few too many requests. Please try again after a while.";
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['error']['message'] ?? 'Unknown error';
          debugPrint("Groq Error Detail: $errorMsg");
          return " Error: $errorMsg";
        } catch (_) {
          debugPrint("Groq Error: ${response.statusCode} - ${response.body}");
          return " Error ${response.statusCode}: The itinerary could not be created. Please try again.";
        }
      }
    } catch (e) {
      debugPrint("Connection Error: $e");
      return " Check your internet connection and try again.";
    }
  }
}
