import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';

class DoctorModel extends Doctor {
  const DoctorModel({
    super.id,
    required super.name,
    required super.specialization,
    super.bio,
    super.rating,
    super.profileImage,
    super.isAvailable,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['_id'],
      name: json['name'],
      specialization: json['specialization'],
      bio: json['bio'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      profileImage: json['profileImage'],
      isAvailable: json['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'specialization': specialization,
      'bio': bio,
      'rating': rating,
      'profileImage': profileImage,
      'isAvailable': isAvailable,
    };
  }
}
