import 'package:equatable/equatable.dart';

class Doctor extends Equatable {
  final String? id;
  final String name;
  final String specialization;
  final String? bio;
  final double rating;
  final String? profileImage;
  final bool isAvailable;

  const Doctor({
    this.id,
    required this.name,
    required this.specialization,
    this.bio,
    this.rating = 0.0,
    this.profileImage,
    this.isAvailable = true,
  });

  @override
  List<Object?> get props => [id, name, specialization, bio, rating, profileImage, isAvailable];
}
