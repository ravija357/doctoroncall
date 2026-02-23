import '../../domain/entities/doctor.dart';

class DoctorModel extends Doctor {
  const DoctorModel({
    required super.id,
    required super.userId,
    required super.firstName,
    required super.lastName,
    super.image,
    required super.specialization,
    required super.experience,
    required super.bio,
    required double fees,
    super.hospital,
    required double averageRating,
    required int totalReviews,
  }) : super(fees: fees, averageRating: averageRating, totalReviews: totalReviews);

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    return DoctorModel(
      id: json['_id'] ?? '',
      userId: user['_id'] ?? '',
      firstName: user['firstName'] ?? '',
      lastName: user['lastName'] ?? '',
      image: user['image'],
      specialization: json['specialization'] ?? '',
      experience: json['experience'] ?? 0,
      bio: json['bio'] ?? '',
      fees: (json['fees'] ?? 0).toDouble(),
      hospital: json['hospital'],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }
}
