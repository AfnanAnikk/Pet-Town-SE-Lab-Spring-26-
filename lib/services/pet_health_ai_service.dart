import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet_health_model.dart';

/// Cloud-driven AI service communicating with the Random Forest server execution block.
class PetHealthAIService {
  static const String _serverUrl =
      'https://pet-town-se-lab-spring-26-pet-vet-ai.onrender.com';
  static const Duration _timeout = Duration(seconds: 15);

  // ── Main prediction entry point ───────────────────────────────────────────
  /// Posts telemetry profiles directly to the cloud interface.
  /// Throws descriptive exceptions on connection loss, server timeouts, or bad responses.
  static Future<({List<ClassifierResult> results, bool isOffline})> predict(
    PetProfile profile,
  ) async {
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
        return (
          results: data
              .map((j) => ClassifierResult.fromJson(j as Map<String, dynamic>))
              .toList(),
          isOffline: false,
        );
      } else {
        throw Exception(
          'Server returned error status: ${res.statusCode}. Please try again.',
        );
      }
    } on TimeoutException {
      throw Exception(
        'Connection timed out. The server may be warming up. Please try again.',
      );
    } catch (e) {
      throw Exception(
        'Unable to reach the AI engine. Please verify your internet connection.',
      );
    }
  }
}
