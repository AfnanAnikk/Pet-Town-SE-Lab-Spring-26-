class PetProfile {
  final String animalType;
  final List<String> symptoms;
  final double? temperature;
  final double? heartRate;

  const PetProfile({
    required this.animalType,
    required this.symptoms,
    this.temperature,
    this.heartRate,
  });
}

class ClassifierResult {
  final String disease;
  final double confidence;
  final String urgency;
  final String description;
  final String treatment;
  final String prevention;
  final bool isOffline;

  const ClassifierResult({
    required this.disease,
    required this.confidence,
    required this.urgency,
    required this.description,
    required this.treatment,
    required this.prevention,
    required this.isOffline,
  });

  factory ClassifierResult.fromJson(
      Map<String, dynamic> json, {
      bool isOffline = false,
    }) {
    return ClassifierResult(
      disease: json['disease'] ?? 'Unknown',
      confidence: (json['confidence'] as num).toDouble(),
      urgency: json['urgency'] ?? 'Schedule Vet Visit',
      description: json['description'] ?? '',
      treatment: json['treatment'] ?? '',
      prevention: json['prevention'] ?? '',
      isOffline: isOffline,
    );
  }
}
