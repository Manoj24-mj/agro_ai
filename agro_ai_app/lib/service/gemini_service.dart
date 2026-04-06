import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // TODO: Replace with your actual Gemini API Key from https://aistudio.google.com/
  static const String _apiKey = "AIzaSyB_DIdaVU_jJnuafxqS89Pn73WZp-9gCUY";
  
  static const String _systemPrompt = '''
    You are "Agro AI Doctor", a highly professional, intelligent, and friendly AI assistant designed to help farmers and agricultural users.

    Your personality:
    - Clear, confident, and supportive
    - Simple language (easy for farmers to understand)
    - Avoid technical jargon unless needed
    - Helpful, practical, and action-oriented
    - Friendly but not casual or childish

    🎯 PRIMARY GOAL:
    Help users diagnose plant diseases, give farming advice, and guide them with actionable solutions.

    🧠 RESPONSE STYLE:
    Always follow this structure:
    1. Acknowledge the user
    2. Understand the problem clearly
    3. Ask smart follow-up questions (if needed)
    4. Provide possible diagnosis
    5. Give practical solutions
    6. Offer next steps
    
    📌 EXAMPLE RESPONSE FORMAT:
    "Thanks for sharing this. Based on what you described, it looks like your plant may be experiencing [possible issue].

    This usually happens due to:
    - Reason 1
    - Reason 2

    Here’s what you can do:
    1. Action step
    2. Action step
    3. Action step

    To be more accurate, could you please tell me:
    - Your location
    - When the problem started
    - (Optional) Upload an image

    I’m here to help you step-by-step."

    🌱 FEATURES TO SUPPORT:
    1. Image-based diagnosis: If user uploads image → analyze and respond clearly
    2. Context awareness: Remember Crop type, Location, Previous issues
    3. Smart suggestions: Recommend fertilizers/pesticides, Suggest prevention tips, Seasonal advice
    4. Multi-language support: Respond in user's preferred language
    5. Voice-friendly responses: Keep sentences short and clear

    ⚠️ IMPORTANT RULES:
    - Never give unsafe or harmful advice
    - If unsure → say "It could be..." instead of guessing
    - Always suggest consulting local expert if needed
    - Avoid overconfidence
  ''';

// No SDK model needed, strictly using manual REST API to bypass restrictions.

  Future<String> askGemini(String message, {Uint8List? imageBytes, String? languageCode}) async {
    try {
      return await _askGeminiRest(message, imageBytes: imageBytes, languageCode: languageCode);
    } catch (e) {
      print("REST API Error: $e");
      return "❌ **Connection Error**: I'm having trouble connecting to the AI brain right now. details: ${e.toString()}";
    }
  }

  String _getLanguageName(String? code) {
    switch (code) {
      case 'kn': return 'Kannada';
      case 'hi': return 'Hindi';
      case 'en': return 'English';
      default: return 'English';
    }
  }

  /// Direct REST API call
  Future<String> _askGeminiRest(String message, {Uint8List? imageBytes, String? languageCode}) async {
    final langName = _getLanguageName(languageCode);
    final languageInstruction = languageCode != null ? "\n\nIMPORTANT: You MUST respond in $langName language." : "";
    
    final payload = {
      "contents": [
        {
          "parts": [
            {"text": "[$_systemPrompt$languageInstruction]\n\nUser Question: $message"},
            if (imageBytes != null)
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Encode(imageBytes)
                }
              }
          ]
        }
      ]
    };

    return await _makeRequest('v1beta', payload);
  }

  Future<String> _makeRequest(String version, Map<String, dynamic> payload) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/$version/models/gemini-2.5-flash:generateContent?key=$_apiKey');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? "No response text.";
      } else {
        return "❌ **Connection Error (${response.statusCode})**: ${response.body}";
      }
    } catch (e) {
      return "❌ **Critical Connection Error ($version)**: ${e.toString()}";
    }
  }
}
