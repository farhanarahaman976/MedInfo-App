import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/medicine.dart';
import '../models/chat_message.dart';

// ─── GeminiService (now powered by Groq) ────────────────────────────────────
// Symptom লিখলে, app এর medicine list থেকে relevant medicine suggest করে
// এবং general health advice দেয়।
//
// API key .env file থেকে load হয় (GROQ_API_KEY=...)
// Key পাওয়ার জন্য: https://console.groq.com/keys

class GeminiService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.1-8b-instant';

  // কতগুলো medicine AI-কে context হিসেবে পাঠানো হবে (token বাঁচানোর জন্য)
  static const int _maxContextMedicines = 15;

  // ── Common Banglish/Bangla symptom keywords -> English "uses" keywords map
  // এটা দিয়ে Banglish input ("matha betha", "jor") এর সাথে English uses
  // ("Headache", "Fever") match করানো হয়
  static const Map<String, List<String>> _symptomKeywordMap = {
    'fever': ['matha betha', 'matha bytha', 'মাথা ব্যথা', 'headache'],
    'jor': ['fever', 'জ্বর', 'temperature'],
    'jwor': ['fever', 'জ্বর', 'temperature'],
    'headache': ['matha betha', 'মাথা ব্যথা', 'matha bytha'],
    'pet betha': ['stomach pain', 'abdominal pain', 'পেট ব্যথা'],
    'gastric': ['acidity', 'গ্যাস্ট্রিক', 'বদহজম', 'dyspepsia'],
    'allergy': ['অ্যালার্জি', 'itching', 'চুলকানি'],
    'cough': ['কাশি', 'kashi'],
    'kashi': ['cough', 'কাশি'],
    'cold': ['ঠান্ডা', 'thanda', 'common cold'],
    'thanda': ['cold', 'common cold', 'ঠান্ডা'],
    'diarrhea': ['পাতলা পায়খানা', 'loose motion'],
    'pain': ['betha', 'bytha', 'ব্যথা'],
  };

  /// User এর input থেকে relevant medicines খুঁজে বের করে (token বাঁচানোর জন্য)
  List<Medicine> _filterRelevantMedicines(
      String userInput, List<Medicine> medicines) {
    final input = userInput.toLowerCase();

    // input থেকে extra keywords বের করা (mapping table দিয়ে)
    final extraKeywords = <String>[];
    _symptomKeywordMap.forEach((key, values) {
      if (input.contains(key)) {
        extraKeywords.addAll(values.map((v) => v.toLowerCase()));
      }
    });

    final scored = <Medicine, int>{};

    for (final m in medicines) {
      int score = 0;

      // English uses check
      for (final use in m.uses) {
        final useLower = use.toLowerCase();
        if (input.contains(useLower) ||
            extraKeywords.any((k) => useLower.contains(k) || k.contains(useLower))) {
          score += 2;
        }
      }

      // Bangla uses check (direct substring, কারণ Bangla word boundary সমস্যা নাই)
      for (final use in m.usesBangla) {
        if (userInput.contains(use) ||
            extraKeywords.any((k) => use.contains(k) || k.contains(use))) {
          score += 2;
        }
      }

      // Category check (lower priority)
      if (input.contains(m.category.toLowerCase())) {
        score += 1;
      }

      if (score > 0) {
        scored[m] = score;
      }
    }

    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var result = sorted.take(_maxContextMedicines).map((e) => e.key).toList();

    // কোনো match না পেলে - common/general medicines এর একটা ছোট subset পাঠানো হচ্ছে
    // যাতে AI অন্তত general suggestion দিতে পারে
    if (result.isEmpty) {
      result = medicines.take(_maxContextMedicines).toList();
    }

    return result;
  }

  /// User এর symptom/query পাঠিয়ে general advice + medicine suggestion পায়
  Future<ChatMessage> getSuggestion({
    required String userInput,
    required List<Medicine> medicines,
  }) async {
    if (_apiKey.isEmpty) {
      return ChatMessage(
        text:
            'AI Chatbot এখনো setup হয়নি। .env ফাইলে GROQ_API_KEY বসাও।\n\nKey নেওয়ার লিংক: https://console.groq.com/keys',
        sender: MessageSender.bot,
        isError: true,
      );
    }

    try {
      // পুরো list না পাঠিয়ে, relevant medicines filter করে নেওয়া হচ্ছে
      final relevantMedicines = _filterRelevantMedicines(userInput, medicines);

      final medicineContext = relevantMedicines
          .map((m) =>
              '${m.name} (${m.nameBangla}) | Category: ${m.category} | '
              'Uses: ${m.uses.join(", ")} | '
              'ব্যবহার: ${m.usesBangla.join(", ")}')
          .join('\n');

      final prompt = '''
You are "MedInfo AI Assistant", a friendly and knowledgeable health assistant inside "MedInfo BD", a medicine information app for Bangladesh.

Here is a list of possibly relevant medicines available in the app (format: Name (Bangla name) | Category | Uses | ব্যবহার):
$medicineContext

User's message: "$userInput"

Your role:
1. Act like a helpful, caring health assistant (similar to a knowledgeable friend) — not just a medicine-name generator.
2. If the user describes a symptom or health issue:
   - First, give 2-4 sentences of general, safe self-care advice relevant to that symptom (rest, hydration, sleep, warm/cold compress, diet tips, when to see a doctor, etc.).
   - THEN, if relevant, suggest 1-3 medicines ONLY from the list above that could help (based on "Uses"/"ব্যবহার"). If nothing in the list fits well, it's fine to suggest none — general advice alone is still useful.
3. ALWAYS gently remind the user to consult a doctor or pharmacist before taking any medicine, especially for serious, persistent, or worsening symptoms.
4. If the user's message is just a greeting or general question (not a symptom), respond naturally and warmly, with "suggested_medicines" as an empty array.
5. Do NOT suggest medicines not present in the list above.

Language rules (VERY IMPORTANT):
- Respond primarily in Bangla, optionally mixing in simple English words naturally (Banglish), like a Bangladeshi person texting a friend.
- Write Bangla with CORRECT spelling and grammar (শুদ্ধ বানান ও বাক্যগঠন). Carefully proofread every Bangla word before finalizing — do not produce misspelled or broken Bangla.
- Keep sentences short, clear, and natural — avoid overly formal or robotic phrasing.

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
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
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
          data['choices']?[0]?['message']?['content'] as String?;

      if (rawText == null) {
        return ChatMessage(
          text: 'কোনো response পাওয়া যায়নি। আবার চেষ্টা করো।',
          sender: MessageSender.bot,
          isError: true,
        );
      }

      // Clean up in case model wraps in markdown fences
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