import 'package:equatable/equatable.dart';

class Doctor extends Equatable {
  final String id;
  final String userId;
  final String firstName;
  final String lastName;
  final String? image;
  final String specialization;
  final int experience;
  final String bio;
  final double fees;
  final String? hospital;
  final double averageRating;
  final int totalReviews;

  const Doctor({
    required this.id,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.image,
    required this.specialization,
    required this.experience,
    required this.bio,
    required this.fees,
    this.hospital,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        firstName,
        lastName,
        image,
        specialization,
        experience,
        bio,
        fees,
        hospital,
        averageRating,
        totalReviews,
      ];
}
