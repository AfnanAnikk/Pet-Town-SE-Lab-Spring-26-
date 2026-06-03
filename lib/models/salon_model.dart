class SalonReview {
  final String authorName;
  final String authorInitial;
  final String date;
  final String text;

  SalonReview({
    required this.authorName,
    required this.authorInitial,
    required this.date,
    required this.text,
  });
}

class SalonModel {
  final String id;
  final String name;
  final String ownerName;
  final String location;
  final String? profilePictureUrl;
  final bool isVerified;
  final double rating;
  final int reviewCount;
  final int totalBookings;
  final List<String> tags;
  final List<String> availableSlots;
  final int price;
  final String profileDescription;
  final List<SalonReview> reviews;

  SalonModel({
    required this.id,
    required this.name,
    required this.ownerName,
    required this.location,
    required this.profilePictureUrl,
    required this.isVerified,
    required this.rating,
    required this.reviewCount,
    required this.totalBookings,
    required this.tags,
    required this.availableSlots,
    required this.price,
    required this.profileDescription,
    required this.reviews,
  });

  factory SalonModel.fromJson(Map<String, dynamic> json) {
    return SalonModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      ownerName: json['owner_name'] ?? 'Unknown Owner',
      location: json['location'] ?? 'Unknown Location',
      profilePictureUrl: json['profile_picture_url'] ?? json['owner_picture'] ?? json['profilePictureUrl'],
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      totalBookings: json['total_bookings'] ?? 0,
      price: json['price'] ?? 0,
      profileDescription: json['profile_description'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      availableSlots: List<String>.from(json['availableSlots'] ?? []),
      reviews: [], // Would map json reviews if provided
    );
  }
}
