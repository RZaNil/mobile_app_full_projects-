import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiResponse {
  const ApiResponse({
    required this.answer,
    this.source,
    this.suggestions = const <String>[],
    this.intent,
    this.entities = const <String, dynamic>{},
    this.sessionId,
    this.needsClarification = false,
    this.responseTimeMs,
    this.cached = false,
  });

  final String answer;
  final String? source;
  final List<String> suggestions;
  final String? intent;
  final Map<String, dynamic> entities;
  final String? sessionId;
  final bool needsClarification;
  final double? responseTimeMs;
  final bool cached;

  ApiResponse copyWith({
    String? answer,
    String? source,
    List<String>? suggestions,
    String? intent,
    Map<String, dynamic>? entities,
    String? sessionId,
    bool? needsClarification,
    double? responseTimeMs,
    bool? cached,
  }) {
    return ApiResponse(
      answer: answer ?? this.answer,
      source: source ?? this.source,
      suggestions: suggestions ?? this.suggestions,
      intent: intent ?? this.intent,
      entities: entities ?? this.entities,
      sessionId: sessionId ?? this.sessionId,
      needsClarification: needsClarification ?? this.needsClarification,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      cached: cached ?? this.cached,
    );
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    final Object? rawSources = json['sources'];
    final List<String> sources = rawSources is List
        ? rawSources.map((Object? item) => item.toString()).toList()
        : rawSources is String && rawSources.isNotEmpty
        ? <String>[rawSources]
        : const <String>[];
    final Object? rawSuggestions = json['suggestions'];
    final List<String> suggestions = rawSuggestions is List
        ? rawSuggestions.map((Object? item) => item.toString()).toList()
        : rawSuggestions is String && rawSuggestions.isNotEmpty
        ? <String>[rawSuggestions]
        : const <String>[];

    return ApiResponse(
      answer:
          json['response']?.toString() ??
          json['answer']?.toString() ??
          'I could not generate a response right now.',
      source:
          json['source']?.toString() ??
          (sources.isNotEmpty ? sources.first : null),
      suggestions: suggestions,
      intent: json['intent']?.toString(),
      entities: json['entities'] is Map
          ? Map<String, dynamic>.from(json['entities'] as Map)
          : const <String, dynamic>{},
      sessionId:
          json['sessionId']?.toString() ?? json['session_id']?.toString(),
      needsClarification:
          json['needsClarification'] == true ||
          json['needs_clarification'] == true ||
          json['intent']?.toString() == 'clarify',
      responseTimeMs:
          (json['responseTimeMs'] as num?)?.toDouble() ??
          (json['response_time_ms'] as num?)?.toDouble(),
      cached: json['cached'] == true,
    );
  }
}

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = 'https://niloy21-mobile-app.hf.space';

  final http.Client _client;
  String _sessionId = _buildSessionId();

  Future<ApiResponse> askQuestion(String question) async {
    final String trimmedQuestion = question.trim();
    if (trimmedQuestion.isEmpty) {
      return const ApiResponse(
        answer: 'Please type or say a question first.',
        source: 'local_validation',
        intent: 'validation',
      );
    }

    final Stopwatch stopwatch = Stopwatch()..start();

    try {
      final http.Response response = await _client
          .post(
            Uri.parse('$baseUrl/api/ask'),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'query': trimmedQuestion,
              'session_id': _sessionId,
            }),
          )
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Object? decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final ApiResponse apiResponse = ApiResponse.fromJson(decoded);
          return apiResponse.copyWith(
            responseTimeMs:
                apiResponse.responseTimeMs ??
                stopwatch.elapsedMilliseconds.toDouble(),
            sessionId: apiResponse.sessionId ?? _sessionId,
          );
        }
      }

      return _fallbackResponse(
        'The server returned an unexpected response. Please try again in a moment.',
        responseTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    } on TimeoutException {
      stopwatch.stop();
      return _fallbackResponse(
        'The EWU Assistant server took too long to respond. Please try again shortly.',
        responseTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    } catch (_) {
      stopwatch.stop();
      return _fallbackResponse(
        'I could not reach the EWU Assistant server right now. Check your internet connection or try again later.',
        responseTimeMs: stopwatch.elapsedMilliseconds.toDouble(),
      );
    }
  }

  Future<bool> checkHealth() async {
    try {
      final http.Response response = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 10));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void resetSession() {
    _sessionId = _buildSessionId();
  }

  void dispose() {
    _client.close();
  }

  ApiResponse _fallbackResponse(String message, {double? responseTimeMs}) {
    return ApiResponse(
      answer: message,
      source: 'offline_fallback',
      suggestions: const <String>[
        'Admission requirements',
        'Tuition fees',
        'Student clubs',
      ],
      intent: 'error',
      sessionId: _sessionId,
      responseTimeMs: responseTimeMs,
      cached: false,
    );
  }

  static String _buildSessionId() {
    return 'flutter_user_${DateTime.now().millisecondsSinceEpoch}';
  }
}
