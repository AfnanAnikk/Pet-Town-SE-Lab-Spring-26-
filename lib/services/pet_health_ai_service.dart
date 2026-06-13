import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet_health_model.dart';

/// Custom exception for invalid vitals input (HTTP 422 from server).
class VitalsValidationException implements Exception {
  final String message;
  const VitalsValidationException(this.message);
  @override
  String toString() => message;
}

/// Server-driven AI service communicating with the Random Forest server.
class PetHealthAIService {
  static const String _serverUrl =
      'https://pet-town-se-lab-spring-26-pet-vet-ai.onrender.com';
  static const Duration _timeout = Duration(seconds: 20);

  // ── Main prediction entry point ───────────────────────────────────────────
  /// Posts telemetry data profiles to the cloud interface.
  static Future<List<ClassifierResult>> predict(PetProfile profile) async {
    late http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$_serverUrl/predict'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'animal_type': profile.animalType,
              'symptoms': profile.symptoms,
              'temperature': profile.temperature,
              'heart_rate': profile.heartRate,
            }),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw Exception(
        'Connection timed out. The AI server may be waking up — please try again in a moment.',
      );
    } catch (_) {
      throw Exception(
        'Unable to reach the AI engine. Please check your internet connection and try again.',
      );
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as List<dynamic>;
      return data
          .map((j) => ClassifierResult.fromJson(j as Map<String, dynamic>))
          .toList();
    }

    // ── Parse error body from the server ──────────────────────────────────
    String serverDetail = '';
    try {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      serverDetail = body['detail']?.toString() ?? '';
    } catch (_) {
      serverDetail = res.body;
    }

    // 422 = invalid / unrealistic vitals
    if (res.statusCode == 422) {
      throw VitalsValidationException(serverDetail.isNotEmpty
          ? serverDetail
          : 'The vitals you entered appear unrealistic. Please re-check and try again.');
    }

    throw Exception(
      serverDetail.isNotEmpty
          ? serverDetail
          : 'Server error (${res.statusCode}). Please try again.',
    );
  }

  // ── NLP Freestyle Symptom Extraction ──────────────────────────────────────
  /// Sends unstructured freestyle text to the Python TF-IDF backend matcher.
  static Future<List<String>> extractSymptoms(String text) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_serverUrl/extract-symptoms'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(_timeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final matched = data['matched_symptoms'] as List<dynamic>;
        return matched.map((e) => e.toString()).toList();
      }
      return [];
    } catch (_) {
      // Graceful fallback — user can still select symptoms manually.
      return [];
    }
  }
}
