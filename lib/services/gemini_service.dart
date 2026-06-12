import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/medicine.dart';
import '../models/chat_message.dart';

// ─── GeminiService ───────────────────────────────────────────────────────────
// Symptom লিখলে, app এর medicine list থেকে relevant medicine suggest করে।
//
// API key .env file থেকে load হয় (GEMINI_API_KEY=...)
// Key পাওয়ার জন্য: https://aistudio.google.com/app/apikey

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  /// User এর symptom/query পাঠিয়ে medicine suggestion পায়
  Future<ChatMessage> getSuggestion({
    required String userInput,
    required List<Medicine> medicines,
  }) async {
    if (_apiKey.isEmpty) {
      return ChatMessage(
        text:
            'AI Chatbot এখনো setup হয়নি। .env ফাইলে GEMINI_API_KEY বসাও।\n\nKey নেওয়ার লিংক: https://aistudio.google.com/app/apikey',
        sender: MessageSender.bot,
        isError: true,
      );
    }

    try {
      // Medicine list কে compact text এ convert করা হচ্ছে (token বাঁচানোর জন্য)
      final medicineContext = medicines
          .map((m) =>
              '${m.name} | Category: ${m.category} | Uses: ${m.uses.join(", ")}')
          .join('\n');

      final prompt = '''
You are a helpful medical assistant inside "MedInfo BD", a medicine information app for Bangladesh.

Here is the list of medicines available in the app (format: Name | Category | Uses):
$medicineContext

User's message: "$userInput"

Instructions:
1. If the user describes a symptom or health issue, suggest 1-3 relevant medicines ONLY from the list above that could help with that symptom (based on the "Uses" field).
2. Write a short, friendly, helpful reply (2-4 sentences). You can mix Bangla and English (Banglish) naturally.
3. ALWAYS remind the user to consult a doctor or pharmacist before taking any medicine, especially for serious or persistent symptoms.
4. If no medicine in the list matches, set "suggested_medicines" to an empty array and politely say so, recommending a doctor visit.
5. If the user's message is just a greeting or general question (not a symptom), respond naturally and set "suggested_medicines" to an empty array.
6. Do NOT suggest medicines not present in the list above.

Respond ONLY with valid JSON in this exact format, no markdown, no extra text:
{
  "reply": "your friendly response here",
  "suggested_medicines": ["Exact Medicine Name 1", "Exact Medicine Name 2"]
}
''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': _apiKey,
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': prompt}]
            }
          ],
          'generationConfig': {
            'temperature': 0.4,
            'responseMimeType': 'application/json',
          },
        }),
      );

      if (response.statusCode != 200) {
        return ChatMessage(
          text:
              'Server error হয়েছে (${response.statusCode})। আবার চেষ্টা করো।\n${response.body}',
          sender: MessageSender.bot,
          isError: true,
        );
      }

      final data = jsonDecode(response.body);
      final rawText =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;

      if (rawText == null) {
        return ChatMessage(
          text: 'কোনো response পাওয়া যায়নি। আবার চেষ্টা করো।',
          sender: MessageSender.bot,
          isError: true,
        );
      }

      // Clean up in case Gemini wraps in markdown fences
      final cleaned =
          rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      final parsed = jsonDecode(cleaned);
      final reply = parsed['reply'] as String? ?? 'Sorry, something went wrong.';
      final suggestedNames =
          (parsed['suggested_medicines'] as List?)?.cast<String>() ?? [];

      // AI suggested নাম গুলোকে actual Medicine object এর সাথে match করা
      final matched = <Medicine>[];
      for (final name in suggestedNames) {
        final found = medicines.where(
          (m) => m.name.toLowerCase().trim() == name.toLowerCase().trim(),
        );
        if (found.isNotEmpty) {
          matched.add(found.first);
        } else {
          // exact match না পেলে partial match try করা হচ্ছে
          final partial = medicines.where(
            (m) =>
                m.name.toLowerCase().contains(name.toLowerCase()) ||
                name.toLowerCase().contains(m.name.toLowerCase()),
          );
          if (partial.isNotEmpty) matched.add(partial.first);
        }
      }

      return ChatMessage(
        text: reply,
        sender: MessageSender.bot,
        suggestedMedicines: matched,
      );
    } catch (e) {
      return ChatMessage(
        text: 'কিছু সমস্যা হয়েছে। Internet connection check করো।\n\nError: $e',
        sender: MessageSender.bot,
        isError: true,
      );
    }
  }
}