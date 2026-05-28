import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'gemini_service.dart';

class FoodScanResult {
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String serving;

  const FoodScanResult({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.serving,
  });
}

class FoodScanService {
  final _gemini = GeminiService();

  // API keys are injected at build time via --dart-define (see .env file)
  static const _groqApiKey = String.fromEnvironment('GROQ_API_KEY');
  static const _groqBaseUrl = 'https://api.groq.com/openai';
  static const _groqModel = 'llama-3.3-70b-versatile';
  static const _groqVisionModel = 'llama-3.2-90b-vision-preview';

  static const _beeknoeeApiKey = String.fromEnvironment('BEEKNOEE_API_KEY');
  static const _beeknoeeBaseUrl = 'https://platform.beeknoee.com';
  static const _beeknoeeModel = 'qwen-3-235b-a22b-instruct-2507';

  static const _goLlmApiKey = String.fromEnvironment('GOLLM_API_KEY');
  static const _goLlmBaseUrl = 'https://api.gollm.cloud';
  static const _goLlmModel = 'gpt-4.1';

  bool get isAvailable =>
      _groqApiKey.isNotEmpty ||
      _beeknoeeApiKey.isNotEmpty ||
      _goLlmApiKey.isNotEmpty ||
      _gemini.isAvailable;

  Future<String> _callTextCompletions({
    required String system,
    required String prompt,
    required int maxTokens,
  }) async {
    // 1. Groq
    if (_groqApiKey.isNotEmpty) {
      try {
        final messages = [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ];
        final text = await _invokeOpenAiCompatible(
          baseUrl: _groqBaseUrl,
          apiKey: _groqApiKey,
          model: _groqModel,
          messages: messages,
          maxTokens: maxTokens,
          useSlashCompletions: true,
        );
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint('[FoodScan AI] Groq failed: $e. Trying Beeknoee...');
      }
    }

    // 2. Beeknoee
    if (_beeknoeeApiKey.isNotEmpty) {
      try {
        final messages = [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ];
        final text = await _invokeOpenAiCompatible(
          baseUrl: _beeknoeeBaseUrl,
          apiKey: _beeknoeeApiKey,
          model: _beeknoeeModel,
          messages: messages,
          maxTokens: maxTokens,
          useSlashCompletions: true,
        );
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint('[FoodScan AI] Beeknoee failed: $e. Trying GoLLM...');
      }
    }

    // 3. GoLLM
    if (_goLlmApiKey.isNotEmpty) {
      try {
        final messages = [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ];
        final text = await _invokeOpenAiCompatible(
          baseUrl: _goLlmBaseUrl,
          apiKey: _goLlmApiKey,
          model: _goLlmModel,
          messages: messages,
          maxTokens: maxTokens,
          useSlashCompletions: false,
        );
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint('[FoodScan AI] GoLLM failed: $e.');
      }
    }

    // 4. Gemini
    if (_gemini.isAvailable) {
      try {
        final messages = [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': prompt},
        ];
        final text = await _gemini.chatCompletions(
          messages: messages,
          maxTokens: maxTokens,
        );
        if (text.isNotEmpty) return text;
      } catch (e) {
        debugPrint('[FoodScan AI] Gemini failed: $e.');
      }
    }

    throw Exception('Tất cả các nhà cung cấp dịch vụ AI đều thất bại.');
  }

  Future<String> _invokeOpenAiCompatible({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<dynamic> messages,
    required int maxTokens,
    required bool useSlashCompletions,
  }) async {
    final path = useSlashCompletions ? '/v1/chat/completions' : '/chat/completions';
    final url = Uri.parse('$baseUrl$path');

    final body = {
      'model': model,
      'messages': messages,
      'max_tokens': maxTokens,
    };

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'User-Agent': 'CoreHealth/1.0',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      return '';
    }
    final message = choices.first['message'] as Map<String, dynamic>?;
    if (message == null) {
      return '';
    }
    final text = message['content'] as String? ?? '';
    return text.trim();
  }

  Future<FoodScanResult> analyzeByImage(Uint8List bytes) async {
    if (!isAvailable) throw Exception('API key not configured');

    final base64Image = base64Encode(bytes);

    if (_groqApiKey.isNotEmpty) {
      try {
        final messages = [
          {
            'role': 'system',
            'content': 'You are a nutrition database. Always respond with ONLY a JSON object, no explanation, no markdown.'
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                },
              },
              {
                'type': 'text',
                'text': 'Identify the food in this image and provide nutrition info.\n'
                    'Reply ONLY with this JSON (no other text):\n'
                    '{"name":"<vietnamese name>","calories":<int>,"protein":<float>,"carbs":<float>,"fat":<float>,"serving":"<portion>"}',
              },
            ],
          }
        ];

        final text = await _invokeOpenAiCompatible(
          baseUrl: _groqBaseUrl,
          apiKey: _groqApiKey,
          model: _groqVisionModel,
          messages: messages,
          maxTokens: 500,
          useSlashCompletions: true,
        );

        if (text.isNotEmpty) {
          return _parse('Món ăn', text);
        }
      } catch (e) {
        debugPrint('[FoodScan AI] Vision failed: $e. Falling back to text name estimation.');
      }
    }

    throw Exception('Không phân tích được ảnh. Thử nhập tên món ăn.');
  }

  Future<FoodScanResult> analyzeByName(String foodName) async {
    if (!isAvailable) throw Exception('API key not configured');

    final prompt = 'Nutrition for: $foodName\n'
        'Reply ONLY with this JSON (no other text):\n'
        '{"name":"<vietnamese name>","calories":<int>,"protein":<float>,"carbs":<float>,"fat":<float>,"serving":"<portion>"}';

    try {
      final text = await _callTextCompletions(
        system: 'You are a nutrition database. Always respond with ONLY a JSON object, no explanation, no markdown.',
        prompt: prompt,
        maxTokens: 200,
      );
      return _parse(foodName, text);
    } catch (e) {
      debugPrint('FoodScan analyzeByName error: $e');
      return _fallback(foodName);
    }
  }

  FoodScanResult _parse(String fallbackName, String raw) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start == -1 || end == -1) return _fallback(fallbackName);
      final map = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      return FoodScanResult(
        name: map['name'] as String? ?? fallbackName,
        calories: (map['calories'] as num?)?.toInt() ?? 0,
        protein: (map['protein'] as num?)?.toDouble() ?? 0,
        carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
        fat: (map['fat'] as num?)?.toDouble() ?? 0,
        serving: map['serving'] as String? ?? '',
      );
    } catch (e) {
      debugPrint('FoodScan parse error: $e');
      return _fallback(fallbackName);
    }
  }

  FoodScanResult _fallback(String name) => FoodScanResult(
        name: name,
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        serving: '',
      );
}
