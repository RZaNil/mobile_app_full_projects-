class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.intent,
    this.source,
    this.suggestions = const <String>[],
    this.responseTimeMs,
  });

  final String text;
  final bool isUser;
  final String? intent;
  final String? source;
  final List<String> suggestions;
  final double? responseTimeMs;

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    String? intent,
    String? source,
    List<String>? suggestions,
    double? responseTimeMs,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      intent: intent ?? this.intent,
      source: source ?? this.source,
      suggestions: suggestions ?? this.suggestions,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    );
  }
}
