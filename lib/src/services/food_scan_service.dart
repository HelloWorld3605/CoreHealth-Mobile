import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'environment_config.dart';

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

/// Food analysis is served by the shared backend at POST /api/ai/analyze-food
/// (Gemini vision + content guard + token charge live server-side). No AI keys
/// exist in the client.
class FoodScanService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'corehealth_jwt';

  bool get isAvailable => true;

  Future<Map<String, dynamic>> _analyze(Map<String, Object?> body) async {
    final token = await _storage.read(key: _tokenKey);
    final res = await http
        .post(
          Uri.parse('${EnvironmentConfig.apiBaseUrl}/ai/analyze-food'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('HTTP ${res.statusCode}: ${res.body}');
    }
    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<FoodScanResult> analyzeByImage(Uint8List bytes) async {
    final map = await _analyze({'imageBase64': base64Encode(bytes)});
    if (map['error'] != null) {
      throw Exception(map['error'].toString());
    }
    return _fromBe('Món ăn', map);
  }

  Future<FoodScanResult> analyzeByName(String foodName) async {
    try {
      final map = await _analyze({'text': foodName});
      if (map['error'] != null) return _fallback(foodName);
      return _fromBe(foodName, map);
    } catch (e) {
      debugPrint('FoodScan analyzeByName error: $e');
      return _fallback(foodName);
    }
  }

  // BE analyze-food shape: {name, kcal, protein, carbs, fat, details, slot}
  FoodScanResult _fromBe(String fallbackName, Map<String, dynamic> map) {
    return FoodScanResult(
      name: map['name'] as String? ?? fallbackName,
      calories: (map['kcal'] as num?)?.toInt() ??
          (map['calories'] as num?)?.toInt() ??
          0,
      protein: (map['protein'] as num?)?.toDouble() ?? 0,
      carbs: (map['carbs'] as num?)?.toDouble() ?? 0,
      fat: (map['fat'] as num?)?.toDouble() ?? 0,
      serving: map['details'] as String? ?? map['serving'] as String? ?? '',
    );
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
