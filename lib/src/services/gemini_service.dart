import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Gemini AI service with round-robin key rotation across 8 API keys.
/// Provides OpenAI-compatible chat completions via Google's Gemini API.
class GeminiService {
  static const _keys = [
    String.fromEnvironment('GEMINI_API_KEY'),
    String.fromEnvironment('GEMINI_API_KEY_2'),
    String.fromEnvironment('GEMINI_API_KEY_3'),
    String.fromEnvironment('GEMINI_API_KEY_4'),
    String.fromEnvironment('GEMINI_API_KEY_5'),
    String.fromEnvironment('GEMINI_API_KEY_6'),
    String.fromEnvironment('GEMINI_API_KEY_7'),
    String.fromEnvironment('GEMINI_API_KEY_8'),
  ];

  static const _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/openai';
  static const _model = 'gemini-2.0-flash';

  // Filter to only non-empty keys
  late final List<String> _activeKeys;
  int _keyIndex = 0;

  GeminiService() {
    _activeKeys = _keys.where((k) => k.isNotEmpty).toList();
  }

  bool get isAvailable => _activeKeys.isNotEmpty;

  String get _currentKey => _activeKeys[_keyIndex % _activeKeys.length];

  void _rotateKey() {
    if (_activeKeys.length > 1) {
      _keyIndex = (_keyIndex + 1) % _activeKeys.length;
    }
  }

  /// Chat completions with automatic key rotation on failure.
  /// Tries all available keys before throwing.
  Future<String> chatCompletions({
    required List<Map<String, String>> messages,
    required int maxTokens,
  }) async {
    if (!isAvailable) throw Exception('Gemini API keys not configured');

    Exception? lastError;
    for (var attempt = 0; attempt < _activeKeys.length; attempt++) {
      final key = _currentKey;
      try {
        final url = Uri.parse('$_baseUrl/chat/completions');
        final body = {
          'model': _model,
          'messages': messages,
          'max_tokens': maxTokens,
        };

        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $key',
          },
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 429 || response.statusCode >= 500) {
          debugPrint('[Gemini] Key ${attempt + 1} got ${response.statusCode}, rotating...');
          _rotateKey();
          lastError = Exception('HTTP ${response.statusCode}');
          continue;
        }

        if (response.statusCode != 200) {
          throw Exception('HTTP ${response.statusCode}: ${response.body}');
        }

        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final choices = data['choices'] as List?;
        if (choices == null || choices.isEmpty) return '';
        final message = choices.first['message'] as Map<String, dynamic>?;
        return (message?['content'] as String? ?? '').trim();
      } catch (e) {
        debugPrint('[Gemini] Key ${attempt + 1} failed: $e');
        lastError = e is Exception ? e : Exception(e.toString());
        _rotateKey();
      }
    }
    throw lastError ?? Exception('All Gemini keys exhausted');
  }
}
