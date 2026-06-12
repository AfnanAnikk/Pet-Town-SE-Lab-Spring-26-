import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet_health_model.dart';

/// Server-driven AI service communicating with the Random Forest server.
class PetHealthAIService {
  static const String _serverUrl =
      'https://pet-town-se-lab-spring-26-pet-vet-ai.onrender.com';
  static const Duration _timeout = Duration(seconds: 15);

  // ── Main prediction entry point ───────────────────────────────────────────
  /// Posts telemetry data profiles to the cloud interface.
  static Future<List<ClassifierResult>> predict(PetProfile profile) async {
    try {
      final res = await http
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

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List<dynamic>;
        return data
            .map((j) => ClassifierResult.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Server returned error status: ${res.statusCode}');
      }
    } on TimeoutException {
      throw Exception(
        'Connection timed out. The server may be waking up from a cold-start. Please try again.',
      );
    } catch (e) {
      throw Exception(
        'Unable to reach the AI engine. Please verify your internet connection and try again.',
      );
    }
  }

  // ── NLP Freestyle Symptom Extraction ──────────────────────────────────────
  /// Sends unstructured freestyle text to the Python TF-IDF backend matcher.
  static Future<List<String>> extractSymptoms(String text) async {
    try {
      final res = await http
          .post(
            Uri.parse(
              '$_serverUrl/extract-symptoms',
            ), // Calls your backend symptom parser matching endpoint
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
      // Fallback gracefully to let users keep using manual chips if network drops
      return [];
    }
  }
}
