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

  static List<VetModel> generateDummyVets() {
    return [
      VetModel(
        id: 'vet_1',
        name: 'Dr. Bahar Hossain',
        degree: 'Veterinarian, DMC',
        isVerified: true,
        rating: 5.0,
        reviewCount: 3,
        tags: ['Immunologist', 'Vaccinologist', 'Biosecurity Veterinarian'],
        availableSlots: [
          'Today at 9:00 AM', 
          'Today at 10:00 AM', 
          'Today at 11:30 AM', 
          'Today at 1:00 PM', 
          'Today at 2:00 PM', 
          'Today at 3:30 PM', 
          'Today at 4:00 PM', 
          'Today at 5:00 PM', 
          'Today at 6:00 PM'
        ],
        price: 9035,
        profileDescription: 'I\'m a licensed veterinarian with over a decade of clinical experience and a lifelong love for feline medicine. My journey began in 2010 as a volunteer in Dhaka clinics, and I graduated as a vet...',
        licences: ['DVM', 'MSc', 'PhD (Vet Science)', 'BVC Registration'],
        speciesTreated: ['Dog', 'Cat', 'Bird'],
        areasOfInterest: ['Emergency', 'Dermatology', 'Nutrition'],
        reviews: [
          VetReview(
            authorName: 'Afnan Mehmud',
            authorInitial: 'A',
            date: 'December, 2025',
            text: 'Very good but do not find any prescription online.',
          ),
          VetReview(
            authorName: 'Juboraz Afnan',
            authorInitial: 'J',
            date: 'October, 2025',
            text: 'Not bad.',
          ),
          VetReview(
            authorName: 'Not Afnan',
            authorInitial: 'N',
            date: 'September, 2025',
            text: 'I trust Dr. Bahar Hossain with my dog\'s life.',
          ),
        ],
      ),
      VetModel(
        id: 'vet_2',
        name: 'Dr. SR Begum',
        degree: 'Veterinarian, GAU',
        isVerified: true,
        rating: 4.9,
        reviewCount: 21,
        tags: ['Epidemiologist', 'Pathologist', 'Microbiologist'],
        availableSlots: [
          'Today at 10:00 AM', 
          'Today at 11:00 AM', 
          'Today at 1:00 PM', 
          'Today at 2:00 PM', 
          'Today at 3:00 PM', 
          'Today at 4:00 PM', 
          'Today at 5:00 PM'
        ],
        price: 9035,
        profileDescription: 'Passionate about animal pathology and disease prevention. Dedicated to providing the best care for your beloved companions.',
        licences: ['DVM', 'PhD (Pathology)'],
        speciesTreated: ['Dog', 'Cat'],
        areasOfInterest: ['Pathology', 'Infectious Diseases', 'Surgery'],
        reviews: [
          VetReview(
            authorName: 'Sarah K.',
            authorInitial: 'S',
            date: 'January, 2026',
            text: 'She is incredibly thorough and kind.',
          ),
        ],
      ),
    ];
  }
}
