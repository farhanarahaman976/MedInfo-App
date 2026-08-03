import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents one chat conversation ("thread") shown in the sidebar,
/// similar to a chat history entry in Claude.ai.
class ChatSession {
  final String id;
  final String title;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.updatedAt,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatSession(
      id: doc.id,
      title: data['title'] ?? 'New Chat',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}