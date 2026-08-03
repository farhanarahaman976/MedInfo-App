// chatbot_page.dart
// CHANGES (this round — chat sessions / sidebar history):
//   1. Added a right-side Drawer (endDrawer) listing past chat sessions,
//      similar to Claude.ai's chat history sidebar, with a "New Chat"
//      entry at the top and a delete icon per session.
//   2. Chat sessions are created lazily — only once the user sends their
//      first message — so the sidebar doesn't fill up with empty entries.
//   3. Session titles are auto-generated from the first user message
//      (handled in ChatService.sendMessage).
//   4. App bar now has a history icon (opens the sidebar) and a trash
//      icon (clears the currently open chat's messages).
//
// Previous round (chat history persistence):
//   Added ChatService to load and save chat messages to Firestore.
//
// Previous round (brand restyle):
//   Gradient app bar, bot avatar, user bubble, medicine card, send
//   button, typing dots, and input bar all restyled to brand colors.

import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../services/gemini_service.dart';
import '../services/chat_service.dart';
import 'medicine_details_page.dart';

class ChatbotPage extends StatefulWidget {
  final List<Medicine> medicines;
  final Function(Medicine) onAddToCart;
  final Function(Medicine) isInCart;

  const ChatbotPage({
    super.key,
    required this.medicines,
    required this.onAddToCart,
    required this.isInCart,
  });

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  // Brand gradient — matches logo / MedAI FAB / home page accents
  static const Color _gradientStart = Color(0xFF3B82C4);
  static const Color _gradientEnd = Color(0xFF0F6E56);
  static const LinearGradient _brandGradient = LinearGradient(
    colors: [_gradientStart, _gradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final GeminiService _geminiService = GeminiService();
  final ChatService _chatService = ChatService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // Null until the user actually sends a message in this chat — the
  // Firestore session doc is only created at that point (see _sendMessage).
  String? _currentSessionId;

  @override
  void initState() {
    super.initState();
    _startNewChat();
  }

  // Resets local state to a fresh, unsaved chat (no Firestore write yet).
  // Does NOT touch navigation — callers opening this from the drawer
  // close the drawer themselves (see _buildHistoryDrawer's "New Chat" button).
  void _startNewChat() {
    setState(() {
      _currentSessionId = null;
      _messages
        ..clear()
        ..add(_greetingMessage());
      _isTyping = false;
    });
  }

  ChatMessage _greetingMessage() {
    return ChatMessage(
      text:
          'হ্যালো! 👋 আমি MedAI - তোমার health assistant।\n\nতোমার symptom বা সমস্যা বলো (যেমন: "মাথা ব্যথা করছে" বা "জ্বর হয়েছে"), আমি সেই অনুযায়ী advice ও medicine suggest করবো।\n\n⚠️ মনে রেখো, এটা ডাক্তারের পরামর্শের বিকল্প নয়।',
      sender: MessageSender.bot,
    );
  }

  // Opens a previously saved session and loads its messages.
  // Caller (the drawer's ListTile onTap) closes the drawer itself first.
  Future<void> _openSession(String sessionId) async {
    setState(() => _isTyping = false);

    final messages =
        await _chatService.getMessagesStream(sessionId, widget.medicines).first;

    setState(() {
      _currentSessionId = sessionId;
      _messages
        ..clear()
        ..addAll(messages.isEmpty ? [_greetingMessage()] : messages);
    });
    _scrollToBottom();
  }

  Future<void> _confirmDeleteSession(ChatSession session) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Will you delete the chat?'),
        content: Text('"${session.title}" Will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatService.deleteSession(session.id);
      if (_currentSessionId == session.id) {
        _startNewChat();
      }
    }
  }

  Future<void> _confirmClearCurrentChat() async {
    if (_currentSessionId == null) {
      // Nothing saved yet for this chat — just reset locally.
      _startNewChat();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Will you clear the chat?'),
        content: const Text('All messages in this chat will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatService.clearSessionMessages(_currentSessionId!);
      _startNewChat();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isTyping) return;

    // Lazily create the Firestore session on the very first message.
    _currentSessionId ??= await _chatService.createSession();
    final sessionId = _currentSessionId!;

    final userMessage = ChatMessage(text: text, sender: MessageSender.user);

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    _chatService.sendMessage(sessionId, userMessage).catchError((e) {
      debugPrint('Failed to save user message: $e');
    });

    final response = await _geminiService.getSuggestion(
      userInput: text,
      medicines: widget.medicines,
    );

    setState(() {
      _messages.add(response);
      _isTyping = false;
    });
    _scrollToBottom();

    _chatService.sendMessage(sessionId, response).catchError((e) {
      debugPrint('Failed to save bot message: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      endDrawer: _buildHistoryDrawer(isDark),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(gradient: _brandGradient),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🩺 MedAI',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Describe your symptoms. Get medicine information.',
                          style: TextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Clear chat',
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    onPressed: _confirmClearCurrentChat,
                  ),
                  IconButton(
                    tooltip: 'Chat history',
                    icon: const Icon(Icons.history_rounded, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF13151C) : const Color(0xFFF7F9FC),
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(14),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildTypingIndicator(isDark);
                  }
                  return _buildMessageBubble(_messages[index], isDark);
                },
              ),
            ),
          ),
          _buildInputBar(isDark),
        ],
      ),
    );
  }

  // ── History Sidebar ─────────────────────────────────────────────────────

  // Friendly relative label for a session's last-updated time.
  String _formatSessionTime(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');

    if (isToday) return 'Today, $hh:$mm';
    if (isYesterday) return 'Yesterday, $hh:$mm';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildHistoryDrawer(bool isDark) {
    final bgColor = isDark ? const Color(0xFF13151C) : const Color(0xFFF7F9FC);

    return Drawer(
      backgroundColor: bgColor,
      width: 300,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gradient header — matches the app bar's brand look
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              decoration: const BoxDecoration(gradient: _brandGradient),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.history_rounded,
                      size: 17,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Chat history',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    onPressed: () => _scaffoldKey.currentState?.closeEndDrawer(),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _startNewChat();
                    _scaffoldKey.currentState?.closeEndDrawer();
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('New Chat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? _gradientStart.withValues(alpha: 0.18)
                        : _gradientStart.withValues(alpha: 0.1),
                    foregroundColor: _gradientStart,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: _gradientStart.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
              child: Text(
                'Recent Chats',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
              ),
            ),

            Expanded(
              child: StreamBuilder<List<ChatSession>>(
                stream: _chatService.getSessionsStream(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final sessions = snapshot.data!;
                  if (sessions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: isDark ? Colors.white24 : Colors.grey[300],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No chats yet',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      final isActive = session.id == _currentSessionId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [
                                    _gradientStart.withValues(alpha: isDark ? 0.22 : 0.1),
                                    _gradientEnd.withValues(alpha: isDark ? 0.22 : 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isActive
                              ? null
                              : (isDark ? const Color(0xFF1C1E26) : Colors.white),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isActive
                                ? _gradientStart.withValues(alpha: 0.35)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.withValues(alpha: 0.12)),
                            width: isActive ? 1.2 : 0.8,
                          ),
                          boxShadow: isActive
                              ? []
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _scaffoldKey.currentState?.closeEndDrawer();
                              _openSession(session.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      gradient: isActive ? _brandGradient : null,
                                      color: isActive
                                          ? null
                                          : (isDark
                                              ? const Color(0xFF262836)
                                              : const Color(0xFFF2F6FB)),
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 16,
                                      color: isActive
                                          ? Colors.white
                                          : (isDark ? Colors.white54 : Colors.grey[500]),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          session.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight:
                                                isActive ? FontWeight.w600 : FontWeight.w500,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F1117),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _formatSessionTime(session.updatedAt),
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: isDark
                                                ? Colors.white38
                                                : Colors.grey[500],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () => _confirmDeleteSession(session),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 17,
                                        color: isDark ? Colors.white30 : Colors.grey[400],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Message Bubble ──────────────────────────────────────────────────────

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.sender == MessageSender.user;

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) _buildBotAvatar(),
            if (!isUser) const SizedBox(width: 8),
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: isUser ? _brandGradient : null,
                  color: isUser
                      ? null
                      : message.isError
                      ? Colors.red.shade50
                      : (isDark ? const Color(0xFF1C1E26) : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser
                      ? null
                      : Border.all(
                          color: message.isError
                              ? Colors.red.shade200
                              : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.withValues(alpha: 0.12)),
                          width: 0.8,
                        ),
                  boxShadow: isUser
                      ? [
                          BoxShadow(
                            color: _gradientStart.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.4,
                    color: isUser
                        ? Colors.white
                        : message.isError
                        ? Colors.red.shade700
                        : (isDark ? Colors.white : const Color(0xFF0F1117)),
                  ),
                ),
              ),
            ),
          ],
        ),

        if (message.suggestedMedicines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 38, bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: message.suggestedMedicines
                  .map((m) => _buildMedicineCard(m, isDark))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: _brandGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _gradientStart.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 15,
        color: Colors.white,
      ),
    );
  }

  // ── Suggested Medicine Card ─────────────────────────────────────────────

  Widget _buildMedicineCard(Medicine medicine, bool isDark) {
    final inCart = widget.isInCart(medicine) as bool;

    return GestureDetector(
      // Puro card-e tap korlei details page e jabe
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MedicineDetailsPage(medicine: medicine),
        ),
      ),
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1E26) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.12),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _gradientStart.withValues(alpha: 0.14),
                    _gradientEnd.withValues(alpha: 0.14),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.medication_rounded,
                color: _gradientStart,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F1117),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '৳${medicine.displayPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _gradientEnd,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Info icon ekhon just visual hint - tap handle kortese pura card
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF262836)
                    : const Color(0xFFF2F6FB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: isDark ? Colors.white70 : const Color(0xFF0F1117),
              ),
            ),
            const SizedBox(width: 6),
            // Add-to-cart button-er nijer tap handler thakbe, card-er tap-er
            // sathe conflict na hoy tai eta alada GestureDetector-e wrap kora
            GestureDetector(
              onTap: inCart ? null : () => widget.onAddToCart(medicine),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: inCart ? const Color(0xFFEAF3DE) : null,
                  gradient: inCart ? null : _brandGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  inCart ? Icons.check_rounded : Icons.add_rounded,
                  size: 16,
                  color: inCart ? const Color(0xFF3B6D11) : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Typing Indicator ────────────────────────────────────────────────────

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _buildBotAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1E26) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.withValues(alpha: 0.12),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const SizedBox(width: 24, height: 12, child: _TypingDots()),
          ),
        ],
      ),
    );
  }

  // ── Input Bar ────────────────────────────────────────────────────────────

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        10 + MediaQuery.of(context).viewPadding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1E26) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.1),
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: TextStyle(
                fontSize: 13.5,
                color: isDark ? Colors.white : const Color(0xFF0F1117),
              ),
              decoration: InputDecoration(
                hintText: 'তোমার symptom লেখো...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF262836)
                    : const Color(0xFFF2F6FB),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: _gradientStart, width: 1.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gradientStart.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isTyping
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Typing dots animation ───────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_controller.value - (i * 0.2)) % 1.0;
            final scale = 0.5 + (0.5 * (t < 0.5 ? t * 2 : (1 - t) * 2));
            return Opacity(
              opacity: 0.4 + (scale * 0.6),
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82C4),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}