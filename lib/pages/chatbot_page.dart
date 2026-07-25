// chatbot_page.dart
// CHANGES (this round — brand restyle):
//   1. App bar → now uses the app's blue-to-teal brand gradient (matching
//      the logo/FAB) instead of a flat unrelated blue, with a sparkle icon
//      badge instead of the generic chat-bubble icon.
//   2. Bot avatar (in message bubbles + typing indicator) → gradient circle
//      with a soft glow, matching the MedAI FAB on the home page.
//   3. User message bubble → brand gradient fill instead of flat blue.
//   4. Suggested medicine card → icon badge, price, and "add to cart"
//      button all recolored to the brand gradient; card gets a subtle
//      shadow and rounded corners consistent with home page cards.
//   5. Send button → gradient circle with glow shadow, matching FAB style.
//   6. Typing dots → recolored to brand gradient-family color.
//   7. Input bar → refined border/shadow, focus-friendly fill color.

import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/chat_message.dart';
import '../services/gemini_service.dart';
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
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        text:
            'হ্যালো! 👋 আমি MedAI - তোমার health assistant।\n\nতোমার symptom বা সমস্যা বলো (যেমন: "মাথা ব্যথা করছে" বা "জ্বর হয়েছে"), আমি সেই অনুযায়ী advice ও medicine suggest করবো।\n\n⚠️ মনে রেখো, এটা ডাক্তারের পরামর্শের বিকল্প নয়।',
        sender: MessageSender.bot,
      ),
    );
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

    setState(() {
      _messages.add(ChatMessage(text: text, sender: MessageSender.user));
      _isTyping = true;
    });
    _inputController.clear();
    _scrollToBottom();

    final response = await _geminiService.getSuggestion(
      userInput: text,
      medicines: widget.medicines,
    );

    setState(() {
      _messages.add(response);
      _isTyping = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MedAI',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Symptom বলো, medicine জানো',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
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