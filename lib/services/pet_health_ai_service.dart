import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/pet_health_model.dart';

/// Hybrid AI service.
/// 1. Tries the FastAPI server on Render (15-second timeout).
/// 2. Falls back automatically to the local Naive Bayes model bundled as JSON.
class PetHealthAIService {
  // ── Replace with your actual Render URL after deploy ──────────────────────
  static const String _serverUrl =
      'https://pet-town-se-lab-spring-26-pet-vet-ai.onrender.com';
  static const Duration _timeout = Duration(seconds: 15);

  static Map<String, dynamic>? _localModel;
  static Map<String, dynamic>? _diseaseInfo;

  // ── Pre-load local assets at app start ────────────────────────────────────
  static Future<void> initialize() async {
    try {
      final m = await rootBundle.loadString(
        'assets/data/pet_health_model.json',
      );
      final d = await rootBundle.loadString('assets/data/disease_info.json');
      _localModel = jsonDecode(m) as Map<String, dynamic>;
      _diseaseInfo = jsonDecode(d) as Map<String, dynamic>;
    } catch (_) {
      // Silent catch for safe bootstrap environment
    }
  }

  // ── NLP Vector Symptom Extraction Layer ───────────────────────────────────
  /// Maps a natural text case observation string directly to checkbox targets via the server matrix.
  static Future<List<String>> extractSymptoms(String text) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_serverUrl/extract-symptoms'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List<dynamic> matched = data['matched_symptoms'] ?? [];
        return matched.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // Server sleeping or offline -> fail gracefully back to manual picker workflow
    }
    return [];
  }

  // ── Main prediction entry point ───────────────────────────────────────────
  /// Returns up to 3 results and a flag indicating whether offline mode was used.
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
      }
    } catch (_) {
      // Server sleeping (cold start > 15 s) or user is offline → fall through
    }

    return (results: _runLocalModel(profile), isOffline: true);
  }

  // ── Local Naive Bayes classifier ──────────────────────────────────────────
  static List<ClassifierResult> _runLocalModel(PetProfile profile) {
    if (_localModel == null) return [];

    final priors = _localModel!['prior_probabilities'] as Map<String, dynamic>;
    final symProbs =
        _localModel!['symptom_probabilities'] as Map<String, dynamic>;
    final aniProbs =
        _localModel!['animal_type_probabilities'] as Map<String, dynamic>;
    final tempStats = _localModel!['temperature_stats'] as Map<String, dynamic>;
    final hrStats = _localModel!['heart_rate_stats'] as Map<String, dynamic>;
    final vocab = List<String>.from(_localModel!['symptom_vocabulary'] as List);

    final Map<String, double> scores = {};

    // Prevent false-positive pregnancy predictions locally if no pregnancy indicators are present
    const pregnancyIndicators = {
      'Nesting Behavior',
      'Clear Vaginal Discharge',
      'Bloody Vaginal Discharge',
      'Fetal Heart Sound Detected',
      'Increased Appetite',
    };
    final hasPregnancyIndicator = profile.symptoms.any(
      (s) => pregnancyIndicators.contains(s),
    );

    for (final disease in priors.keys) {
      if (disease == 'Pregnancy' && !hasPregnancyIndicator) {
        continue;
      }
      double s = math.log((priors[disease] as num).toDouble());

      // P(species | disease)
      final aniMap = aniProbs[disease] as Map<String, dynamic>;
      final pt = (aniMap[profile.animalType] as num?)?.toDouble() ?? 1e-5;
      s += math.log(pt);

      // P(symptoms | disease) — Bernoulli Naive Bayes
      final dsym = symProbs[disease] as Map<String, dynamic>;
      for (final sym in vocab) {
        final py = (dsym[sym] as num?)?.toDouble() ?? 0.01;
        s += profile.symptoms.contains(sym) ? math.log(py) : math.log(1.0 - py);
      }

      // Gaussian P(temp | disease)
      if (profile.temperature != null) {
        final ts = tempStats[disease] as Map<String, dynamic>;
        s += _logGauss(
          profile.temperature!,
          (ts['mean'] as num).toDouble(),
          (ts['std'] as num).toDouble(),
        );
      }

      // Gaussian P(heartRate | disease)
      if (profile.heartRate != null) {
        final hs = hrStats[disease] as Map<String, dynamic>;
        s += _logGauss(
          profile.heartRate!,
          (hs['mean'] as num).toDouble(),
          (hs['std'] as num).toDouble(),
        );
      }

      scores[disease] = s;
    }

    // Softmax over top-5 to get calibrated probabilities
    final sorted = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    if (sorted.isEmpty) return [];

    final maxS = scores[sorted.first]!;
    double sumExp = 0;
    final relP = <String, double>{};
    for (final d in sorted.take(5)) {
      relP[d] = math.exp(scores[d]! - maxS);
      sumExp += relP[d]!;
    }

    return sorted
        .take(3)
        .map((d) {
          final conf = (sumExp > 0) ? (relP[d]! / sumExp * 100) : 0.0;
          final info = (_diseaseInfo?[d] as Map<String, dynamic>?) ?? {};
          return ClassifierResult(
            disease: d,
            confidence: double.parse(conf.toStringAsFixed(1)),
            urgency: _urgency(d),
            description:
                info['description']?.toString() ??
                'Clinical status tracking condition.',
            treatment:
                info['treatment']?.toString() ??
                'Consult a veterinarian for evaluation.',
            prevention:
                info['prevention']?.toString() ??
                'Maintain standard diagnostic protocols.',
            isOffline: true,
          );
        })
        .where((r) => r.confidence >= 5.0)
        .toList();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static double _logGauss(double x, double mean, double std) {
    if (std <= 0) std = 0.5;
    return -0.5 * math.log(2 * math.pi) -
        math.log(std) -
        (math.pow(x - mean, 2) / (2 * math.pow(std, 2)));
  }

  static String _urgency(String disease) {
    final n = disease.toLowerCase();
    const emergency = [
      'parvovirus',
      'distemper',
      'bloat',
      'tuberculosis',
      'rabies',
      'pneumonia',
      'hemorrhagic',
      'septicemia',
    ];
    if (emergency.any((k) => n.contains(k))) return 'Emergency';
    if (n.contains('healthy') || n.contains('pregnancy')) return 'Monitor';
    return 'Schedule Vet Visit';
  }
}
