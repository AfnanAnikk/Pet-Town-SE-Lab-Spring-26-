class VetReview {
  final String authorName;
  final String authorInitial;
  final String date;
  final String text;

  VetReview({
    required this.authorName,
    required this.authorInitial,
    required this.date,
    required this.text,
  });
}

class VetModel {
  final String id;
  final String name;
  final String degree;
  final String location;
  final String? profilePictureUrl;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final List<String> tags;
  final List<String> availableSlots;
  final int price;
  final String profileDescription;
  final List<String> licences;
  final List<String> speciesTreated;
  final List<String> areasOfInterest;
  final List<VetReview> reviews;

  VetModel({
    required this.id,
    required this.name,
    required this.degree,
    required this.location,
    required this.profilePictureUrl,
    required this.isVerified,
    required this.rating,
    required this.reviewCount,
    required this.tags,
    required this.availableSlots,
    required this.price,
    required this.profileDescription,
    required this.licences,
    required this.speciesTreated,
    required this.areasOfInterest,
    required this.reviews,
  });

  factory VetModel.fromJson(Map<String, dynamic> json) {
    return VetModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      degree: json['degree'] ?? '',
      location: json['location'] ?? 'Unknown Location',
      profilePictureUrl: json['profile_picture_url'] ?? json['profilePictureUrl'],
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      price: json['price'] ?? 0,
      profileDescription: json['profile_description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      availableSlots: List<String>.from(json['availableSlots'] ?? []),
      licences: List<String>.from(json['licences'] ?? []),
      speciesTreated: List<String>.from(json['speciesTreated'] ?? []),
      areasOfInterest: List<String>.from(json['areasOfInterest'] ?? []),
      reviews: json['reviews'] != null
          ? (json['reviews'] as List).map((r) {
              final authorName = r['author_name'] ?? 'Unknown User';
              final dateObj = r['created_at'] != null ? DateTime.tryParse(r['created_at']) : null;
              final dateStr = dateObj != null ? '${dateObj.day}/${dateObj.month}/${dateObj.year}' : 'Unknown Date';
              return VetReview(
                authorName: authorName,
                authorInitial: authorName.isNotEmpty ? authorName[0].toUpperCase() : 'U',
                date: dateStr,
                text: r['review_text'] ?? '',
              );
            }).toList()
          : [],
    );
  }
}
