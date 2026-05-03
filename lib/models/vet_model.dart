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
      reviews: [], // Skipping reviews parsing for brevity unless needed
    );
  }

  static List<VetModel> generateDummyVets() {
    final slots = [
      'Today at 10:00 AM', 
      'Today at 1:00 PM', 
      'Today at 4:00 PM'
    ];
    
    return [
      VetModel(
        id: 'vet_1',
        name: 'Dr. Bahar Hossain',
        degree: 'Veterinarian, DMC',
        location: 'Dhaka',
        isVerified: true,
        rating: 5.0,
        reviewCount: 3,
        tags: ['Vaccinologist', 'Immunologist'],
        availableSlots: slots,
        price: 9035,
        profileDescription: 'Expert in vaccines and preventive care.',
        licences: ['DVM'],
        speciesTreated: ['Dog', 'Cat'],
        areasOfInterest: ['Preventive Care', 'Immunology'],
        reviews: [
          VetReview(authorName: 'Afnan Mehmud', authorInitial: 'A', date: 'Dec 2025', text: 'Excellent vet.')
        ],
      ),
      VetModel(
        id: 'vet_2',
        name: 'Dr. SR Begum',
        degree: 'Veterinarian, GAU',
        location: 'Chittagong',
        isVerified: true,
        rating: 4.9,
        reviewCount: 21,
        tags: ['Surgeon'],
        availableSlots: slots,
        price: 12000,
        profileDescription: 'Specialist in treating injuries and infections with surgical expertise.',
        licences: ['DVM', 'PhD (Surgery)'],
        speciesTreated: ['Dog', 'Cat', 'Bird'],
        areasOfInterest: ['Surgery', 'Orthopedics'],
        reviews: [],
      ),
      VetModel(
        id: 'vet_3',
        name: 'Dr. Anisur Rahman',
        degree: 'DVM, PhD',
        location: 'Dhaka',
        isVerified: true,
        rating: 4.8,
        reviewCount: 15,
        tags: ['Oncologist'],
        availableSlots: slots,
        price: 15000,
        profileDescription: 'Dedicated to cancer and chronic care management for pets.',
        licences: ['DVM', 'Board Certified Oncologist'],
        speciesTreated: ['Dog', 'Cat'],
        areasOfInterest: ['Oncology', 'Chronic Care'],
        reviews: [],
      ),
      VetModel(
        id: 'vet_4',
        name: 'Dr. Laila Khan',
        degree: 'DVM',
        location: 'Sylhet',
        isVerified: false,
        rating: 4.7,
        reviewCount: 8,
        tags: ['General Practitioner'],
        availableSlots: slots,
        price: 5000,
        profileDescription: 'Providing comprehensive wellness exams and checkups.',
        licences: ['DVM'],
        speciesTreated: ['Cat', 'Rabbit'],
        areasOfInterest: ['Wellness', 'Internal Medicine'],
        reviews: [],
      ),
      VetModel(
        id: 'vet_5',
        name: 'Dr. Kamrul Hasan',
        degree: 'Veterinarian',
        location: 'Dhaka',
        isVerified: true,
        rating: 4.9,
        reviewCount: 42,
        tags: ['Dermatologist'],
        availableSlots: slots,
        price: 8500,
        profileDescription: 'Specializing in skin conditions and complex allergies.',
        licences: ['DVM', 'MSc Dermatology'],
        speciesTreated: ['Dog', 'Cat'],
        areasOfInterest: ['Dermatology', 'Allergies'],
        reviews: [],
      ),
      VetModel(
        id: 'vet_6',
        name: 'Dr. Nusrat Jahan',
        degree: 'DVM, Dental',
        location: 'Rajshahi',
        isVerified: true,
        rating: 5.0,
        reviewCount: 11,
        tags: ['Dentist'],
        availableSlots: slots,
        price: 7000,
        profileDescription: 'Focused on dental care, cleanings, and oral surgeries.',
        licences: ['DVM'],
        speciesTreated: ['Dog'],
        areasOfInterest: ['Dentistry'],
        reviews: [],
      ),
      VetModel(
        id: 'vet_7',
        name: 'Dr. Rafiqul Islam',
        degree: 'Veterinarian',
        location: 'Khulna',
        isVerified: false,
        rating: 4.5,
        reviewCount: 4,
        tags: ['Epidemiologist', 'Nutritionist'],
        availableSlots: slots,
        price: 4500,
        profileDescription: 'Passionate about animal diets and herd health management.',
        licences: ['DVM'],
        speciesTreated: ['Cow', 'Goat', 'Dog'],
        areasOfInterest: ['Nutrition', 'Public Health'],
        reviews: [],
      ),
      VetModel(
        id: 'vet_8',
        name: 'Dr. Sabrina Amin',
        degree: 'Veterinarian, CVASU',
        location: 'Chittagong',
        isVerified: true,
        rating: 4.8,
        reviewCount: 19,
        tags: ['Behaviorist', 'General Practitioner'],
        availableSlots: slots,
        price: 6000,
        profileDescription: 'Expert in correcting pet behavior and general wellness.',
        licences: ['DVM', 'MSc'],
        speciesTreated: ['Dog', 'Cat', 'Rabbit'],
        areasOfInterest: ['Behavior', 'Wellness'],
        reviews: [],
      ),
      VetModel(
        id: 'vet_9',
        name: 'Dr. Mahfuzur Rahman',
        degree: 'DVM',
        location: 'Dhaka',
        isVerified: true,
        rating: 4.6,
        reviewCount: 27,
        tags: ['Neurologist', 'Surgeon'],
        availableSlots: slots,
        price: 14000,
        profileDescription: 'Specialist in spinal and neurological conditions.',
        licences: ['DVM', 'PhD (Neurology)'],
        speciesTreated: ['Dog', 'Cat'],
        areasOfInterest: ['Neurology', 'Surgery'],
        reviews: [],
      ),
      VetModel(
        id: 'vet_10',
        name: 'Dr. Tariqul Hasan',
        degree: 'DVM, Medicine',
        location: 'Sylhet',
        isVerified: false,
        rating: 4.4,
        reviewCount: 2,
        tags: ['Ophthalmologist'],
        availableSlots: slots,
        price: 8000,
        profileDescription: 'Dedicated to animal eye care and vision correction.',
        licences: ['DVM'],
        speciesTreated: ['Dog', 'Cat', 'Bird'],
        areasOfInterest: ['Ophthalmology'],
        reviews: [],
      ),
    ];
  }
}
