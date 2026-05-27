import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

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
  static const _apiKey = String.fromEnvironment('BEEKNOEE_API_KEY', defaultValue: '');
  static const _baseUrl = 'https://platform.beeknoee.com';
  static const _model = 'gpt-5.4';

  bool get isAvailable => _apiKey.isNotEmpty;

  Future<FoodScanResult> analyzeByImage(Uint8List bytes) async {
    if (!isAvailable) throw Exception('API key not configured');

    final base64Image = base64Encode(bytes);
    final response = await http.post(
      Uri.parse('$_baseUrl/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'User-Agent': 'CoreHealth/1.0',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 200,
        'system': 'You are a nutrition database. Always respond with ONLY a JSON object, no explanation, no markdown.',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': 'image/jpeg',
                  'data': base64Image,
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
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (json['content'] as List).first['text'] as String;
    return _parse('Món ăn', text);
  }

  Future<FoodScanResult> analyzeByName(String foodName) async {
    if (!isAvailable) throw Exception('API key not configured');

    final response = await http.post(
      Uri.parse('$_baseUrl/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'User-Agent': 'CoreHealth/1.0',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 150,
        'system': 'You are a nutrition database. Always respond with ONLY a JSON object, no explanation, no markdown.',
        'messages': [
          {
            'role': 'user',
            'content':
                'Nutrition for: $foodName\n'
                'Reply ONLY with this JSON (no other text):\n'
                '{"name":"<vietnamese name>","calories":<int>,"protein":<float>,"carbs":<float>,"fat":<float>,"serving":"<portion>"}',
          }
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (json['content'] as List).first['text'] as String;
    return _parse(foodName, text);
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
