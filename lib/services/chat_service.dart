import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/medicine.dart';

/// Handles all Firestore operations for MedAI chat sessions and messages.
/// Each chat "thread" is a session document; messages live in a
/// sub-collection under that session (like Claude.ai's chat history).
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Maximum number of recent messages sent to Groq as context,
  // to keep token usage under control.
  static const int contextMessageLimit = 15;

  // Max characters used from the first user message when auto-titling
  // a new session.
  static const int _titleMaxLength = 40;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference get _sessionsCollection {
    final uid = _uid;
    if (uid == null) {
      throw Exception('User not logged in');
    }
    return _firestore.collection('users').doc(uid).collection('chatSessions');
  }

  CollectionReference _messagesCollection(String sessionId) {
    return _sessionsCollection.doc(sessionId).collection('messages');
  }

  /// Creates a new, empty chat session and returns its id.
  /// Called lazily — only once the user actually sends their first
  /// message — so the sidebar doesn't fill up with empty "New Chat" entries.
  Future<String> createSession() async {
    final doc = await _sessionsCollection.add({
      'title': 'New Chat',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Real-time stream of all chat sessions for the sidebar,
  /// most recently updated first.
  Stream<List<ChatSession>> getSessionsStream() {
    return _sessionsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatSession.fromFirestore(doc)).toList());
  }

  /// Real-time stream of messages within one session, oldest to newest.
  Stream<List<ChatMessage>> getMessagesStream(
      String sessionId, List<Medicine> allMedicines) {
    return _messagesCollection(sessionId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromFirestore(doc, allMedicines))
            .toList());
  }

  /// Fetch only the most recent N messages from a session, used when
  /// building the context sent to the Groq API.
  Future<List<ChatMessage>> getRecentMessagesForContext(
      String sessionId, List<Medicine> allMedicines) async {
    final snapshot = await _messagesCollection(sessionId)
        .orderBy('timestamp', descending: true)
        .limit(contextMessageLimit)
        .get();

    final messages = snapshot.docs
        .map((doc) => ChatMessage.fromFirestore(doc, allMedicines))
        .toList();

    return messages.reversed.toList();
  }

  /// Save a message into a session, bump the session's updatedAt, and
  /// auto-title the session from the first user message if it's still
  /// using the default "New Chat" title.
  Future<void> sendMessage(String sessionId, ChatMessage message) async {
    await _messagesCollection(sessionId).add(message.toMap());

    final sessionRef = _sessionsCollection.doc(sessionId);
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};

    if (message.sender == MessageSender.user) {
      final sessionSnap = await sessionRef.get();
      final data = sessionSnap.data() as Map<String, dynamic>?;
      final currentTitle = data?['title'];
      if (currentTitle == null || currentTitle == 'New Chat') {
        updates['title'] = message.text.length > _titleMaxLength
            ? '${message.text.substring(0, _titleMaxLength)}...'
            : message.text;
      }
    }

    await sessionRef.update(updates);
  }

  /// Deletes a session and all of its messages entirely
  /// (used when the user removes a session from the sidebar).
  Future<void> deleteSession(String sessionId) async {
    final messages = await _messagesCollection(sessionId).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_sessionsCollection.doc(sessionId));
    await batch.commit();
  }

  /// Clears all messages in a session but keeps the session document
  /// itself (used by the trash icon on the currently open chat).
  Future<void> clearSessionMessages(String sessionId) async {
    final messages = await _messagesCollection(sessionId).get();
    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}