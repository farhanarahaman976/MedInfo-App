import '../models/medicine.dart';

enum MessageSender { user, bot }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final List<Medicine> suggestedMedicines;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.sender,
    this.suggestedMedicines = const [],
    this.isError = false,
  });
}