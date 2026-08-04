import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/medicine.dart';
import '../models/chat_message.dart';


class GeminiService {
  static String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';


  static const String _model = 'llama-3.3-70b-versatile';

  
  static const int _maxContextMedicines = 15;

  static const Map<String, List<String>> _symptomKeywordMap = {
    'fever': ['jor', 'jwor', 'জ্বর', 'temperature', 'gaye jor'],
    'headache': ['matha betha', 'matha bytha', 'মাথা ব্যথা', 'migraine', 'matha dhorse'],
    'stomach pain': ['pet betha', 'abdominal pain', 'পেট ব্যথা', 'pet e betha'],
    'acidity': ['gastric', 'গ্যাস্ট্রিক', 'বদহজম', 'dyspepsia', 'buk jala', 'বুক জ্বালা', 'acid'],
    'allergy': ['অ্যালার্জি', 'itching', 'চুলকানি', 'allergic'],
    'cough': ['কাশি', 'kashi', 'শুকনো কাশি', 'dry cough'],
    'cold': ['ঠান্ডা', 'thanda', 'common cold', 'sardi', 'nak diye pani', 'সর্দি'],
    'diarrhea': ['পাতলা পায়খানা', 'loose motion', 'diarrhoea', 'dast'],
    'pain': ['betha', 'bytha', 'ব্যথা', 'bytha'],
    'vomiting': ['বমি', 'bomi', 'vomit', 'gulano', 'গুলানো', 'nausea', 'gaa gulano'],
    'sore throat': ['gola betha', 'গলা ব্যথা', 'gola jala', 'throat pain', 'গলা জ্বালা'],
    'body ache': ['gaa betha', 'গা ব্যথা', 'body pain', 'sara gaa betha', 'weakness', 'durbolota', 'দুর্বলতা'],
    'constipation': ['কোষ্ঠকাঠিন্য', 'kostho kathinno', 'পায়খানা clear hocche na'],
    'gas': ['গ্যাস', 'gas hocche', 'pet fapa', 'পেট ফাঁপা', 'bloating'],
    'insomnia': ['ghum hocche na', 'ঘুম হচ্ছে না', 'sleeplessness', 'ঘুম আসছে না'],
    'dizziness': ['matha ghorche', 'মাথা ঘুরছে', 'dizzy', 'chokkor'],
    'high blood pressure': ['blood pressure barti', 'উচ্চ রক্তচাপ', 'hypertension', 'pressure high'],
    'low blood pressure': ['blood pressure kom', 'নিম্ন রক্তচাপ', 'pressure low'],
    'eye irritation': ['চোখ জ্বালা', 'chokh jala', 'eye pain', 'চোখে চুলকানি'],
    'ear pain': ['কান ব্যথা', 'kan betha', 'earache'],
    'toothache': ['দাঁত ব্যথা', 'dat betha', 'tooth pain'],
    'back pain': ['কোমর ব্যথা', 'komor betha', 'pith betha', 'পিঠে ব্যথা'],
    'joint pain': ['জয়েন্ট ব্যথা', 'হাড়ের ব্যথা', 'har er betha', 'gathe betha', 'গাঁটে ব্যথা'],
    'menstrual pain': ['পিরিয়ডের ব্যথা', 'periods er betha', 'period pain'],
    'burning urination': ['prosraber somoy jala', 'প্রস্রাবে জ্বালা', 'urine infection'],
    'skin rash': ['চর্মরোগ', 'skin problem', 'র‍্যাশ', 'charme sомосhya'],
    'wound': ['কাটা ছেঁড়া', 'kata cheda', 'cut', 'ghaa', 'ঘা'],
    'burn': ['পোড়া', 'pora', 'jole gese', 'জ্বলে গেছে'],
    'insect bite': ['পোকার কামড়', 'pokar kamor', 'mosquito bite'],
    'sinus': ['সাইনাস', 'sinus problem', 'nak bondho', 'নাক বন্ধ'],
    'flu': ['ফ্লু', 'influenza', 'gaye betha shathe jor'],
    'motion sickness': ['gari te bomi bomi bhab', 'গাড়িতে বমি ভাব'],
    'food poisoning': ['food poisoning', 'kharap khabar khaoar por pet kharap', 'খাবারে বিষক্রিয়া'],
    'anxiety': ['দুশ্চিন্তা', 'dushchinta', 'অস্থিরতা', 'osthirota', 'stress'],
    'weight loss': ['ওজন কমছে', 'ojon komche'],
    'hair fall': ['চুল পড়া', 'chul pora'],
  };

  
  List<Medicine> _filterRelevantMedicines(
      String userInput, List<Medicine> medicines) {
    final input = userInput.toLowerCase();

    
    final extraKeywords = <String>[];
    _symptomKeywordMap.forEach((canonical, synonyms) {
      final allTerms = [canonical, ...synonyms].map((t) => t.toLowerCase());
      if (allTerms.any((t) => input.contains(t))) {
        extraKeywords.add(canonical.toLowerCase());
        extraKeywords.addAll(synonyms.map((v) => v.toLowerCase()));
      }
    });

    final scored = <Medicine, int>{};

    for (final m in medicines) {
      int score = 0;

      
      for (final use in m.uses) {
        final useLower = use.toLowerCase();
        if (input.contains(useLower) ||
            extraKeywords.any((k) => useLower.contains(k) || k.contains(useLower))) {
          score += 2;
        }
      }

  
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

    if (result.isEmpty) {
      result = medicines.take(_maxContextMedicines).toList();
    }

    return result;
  }

  
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
   - First, give 2-4 sentences of general, safe self-care advice relevant to that symptom (rest, hydration, sleep, diet tips, when to see a doctor, etc.).
   - THEN, if relevant, suggest 1-3 medicines ONLY from the list above that could help (based on "Uses"/"ব্যবহার"). If nothing in the list fits well, it's fine to suggest none — general advice alone is still useful.
   - If the medicine list above does not clearly relate to the user's actual symptom, do NOT force-suggest something irrelevant just because it's in the list — prefer suggesting no medicine over a wrong one.
3. Be careful with Bangla words that describe body sensations, not weather:
   - "ঠান্ডা লাগছে" / "thanda lagce" (feeling cold / chills) is usually a symptom (often linked to fever/cold) — advise keeping warm and drinking warm fluids, NOT cold water or cold food.
   - Do not confuse a symptom description with a literal temperature preference.
4. ALWAYS gently remind the user to consult a doctor or pharmacist before taking any medicine, especially for serious, persistent, or worsening symptoms.
5. If the user's message is just a greeting or general question (not a symptom), respond naturally and warmly, with "suggested_medicines" as an empty array.
6. Do NOT suggest medicines not present in the list above.

Language rules (VERY IMPORTANT):
- Respond primarily in standard Bangla, optionally mixing in simple English words naturally (Banglish), like a Bangladeshi person texting a friend.
- Use CORRECT, standard Bangla spelling and grammar (শুদ্ধ বানান ও বাক্যগঠন) — no phonetic or made-up spelling. Double-check every Bangla word before finalizing.
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