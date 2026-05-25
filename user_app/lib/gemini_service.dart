import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  // NOTE: In a real app, use environment variables or a secure vault
  static const String _apiKey = 'AIzaSyCBEbGkDrTVCQMUXcTVdllDE3tW6UiL47w';

  static Future<String> getSkinCareAdvice(
      double uvIndex, String? skinType) async {
    try {
      if (_apiKey == 'YOUR_GEMINI_API_KEY') {
        return "Please configure Gemini API Key for personalized skin care logs.";
      }

      final model =
          GenerativeModel(model: 'gemini-2.5-flash-lite', apiKey: _apiKey);

      final prompt =
          "The current UV index is $uvIndex. The user's skin type is ${skinType ?? 'Normal'}. "
          "Provide 3 brief, elite skin care tips and suggest types of sunscreens or products for this situation. "
          "Format it as a concise bulleted list for a luxury app log.";

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      return response.text ??
          "Stay protected and hydrated for optimal skin health.";
    } catch (e) {
      return "Ensure high SPF protection and stay hydrated under current UV levels.";
    }
  }
}