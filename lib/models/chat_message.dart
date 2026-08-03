import 'package:cloud_firestore/cloud_firestore.dart';

import 'medicine.dart';

enum MessageSender { user, bot }

class ChatMessage {
  final String? id; // Firestore document id (null until saved)
  final String text;
  final MessageSender sender;
  final List<Medicine> suggestedMedicines;
  final bool isError;
  final DateTime timestamp;

  ChatMessage({
    this.id,
    required this.text,
    required this.sender,
    this.suggestedMedicines = const [],
    this.isError = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to a Firestore-compatible map.
  /// suggestedMedicines are stored as a list of exact medicine names,
  /// since only the AI's suggestion (name) needs to persist, not the
  /// full Medicine object.
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'sender': sender.name, // 'user' or 'bot'
      'suggestedMedicineNames': suggestedMedicines.map((m) => m.name).toList(),
      'isError': isError,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  /// Rebuild a ChatMessage from a Firestore document.
  /// [allMedicines] is the full in-app medicine list, used to re-match
  /// suggestedMedicineNames back into actual Medicine objects.
  factory ChatMessage.fromFirestore(
    DocumentSnapshot doc,
    List<Medicine> allMedicines,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    final names = (data['suggestedMedicineNames'] as List?)?.cast<String>() ?? [];
    final matched = <Medicine>[];
    for (final name in names) {
      final found = allMedicines.where(
        (m) => m.name.toLowerCase().trim() == name.toLowerCase().trim(),
      );
      if (found.isNotEmpty) matched.add(found.first);
    }

    return ChatMessage(
      id: doc.id,
      text: data['text'] ?? '',
      sender: (data['sender'] == 'bot') ? MessageSender.bot : MessageSender.user,
      suggestedMedicines: matched,
      isError: data['isError'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}