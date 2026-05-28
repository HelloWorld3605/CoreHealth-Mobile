import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// YMove exercise video API service.
///
/// Fetches exercise demonstration videos from the YMove platform.
/// Build with: --dart-define=YMOVE_API_KEY=xxx
class YMoveService {
  YMoveService._();
  static final YMoveService instance = YMoveService._();

  static const _apiKey = String.fromEnvironment('YMOVE_API_KEY');
  static const _baseUrl = 'https://exercise-api.ymove.app/api/v2';

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Fetch exercise video URLs by exercise slug.
  ///
  /// Returns a map with keys: videoUrl, thumbnailUrl, videoHlsUrl.
  /// Returns null values if the exercise is not found or API fails.
  Future<ExerciseVideoResult> getExerciseVideo(String slug) async {
    if (!isConfigured) {
      return const ExerciseVideoResult();
    }

    try {
      final uri = Uri.parse('$_baseUrl/exercises/$slug?includeVideos=true');
      final res = await http.get(
        uri,
        headers: {
          'X-API-Key': _apiKey,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) {
        debugPrint('[YMove] getExerciseVideo($slug) failed: ${res.statusCode}');
        return const ExerciseVideoResult();
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return ExerciseVideoResult(
        videoUrl: data['videoUrl'] as String?,
        thumbnailUrl: data['thumbnailUrl'] as String?,
        videoHlsUrl: data['videoHlsUrl'] as String?,
      );
    } catch (e) {
      debugPrint('[YMove] getExerciseVideo($slug) error: $e');
      return const ExerciseVideoResult();
    }
  }

  /// Search exercises by name/keyword.
  /// Returns a list of exercise slugs matching the query.
  Future<List<String>> searchExercises(String query) async {
    if (!isConfigured || query.trim().isEmpty) return [];

    try {
      final uri = Uri.parse(
        '$_baseUrl/exercises?q=${Uri.encodeComponent(query)}&limit=10',
      );
      final res = await http.get(
        uri,
        headers: {
          'X-API-Key': _apiKey,
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return [];

      final data = jsonDecode(res.body);
      if (data is List) {
        return data
            .map((e) => (e as Map<String, dynamic>)['slug'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[YMove] searchExercises error: $e');
      return [];
    }
  }
}

/// Result from YMove exercise video API.
class ExerciseVideoResult {
  final String? videoUrl;
  final String? thumbnailUrl;
  final String? videoHlsUrl;

  const ExerciseVideoResult({
    this.videoUrl,
    this.thumbnailUrl,
    this.videoHlsUrl,
  });

  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;
}
