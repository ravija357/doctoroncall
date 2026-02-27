import 'package:hive/hive.dart';
import '../../domain/entities/doctor.dart';
import 'schedule_model.dart';

@HiveType(typeId: 2)
class DoctorModel extends Doctor {
  @HiveField(0)
  final String hiveId;

  @HiveField(1)
  final String hiveUserId;

  @HiveField(2)
  final String hiveFirstName;

  @HiveField(3)
  final String hiveLastName;

  @HiveField(4)
  final String? hiveImage;

  @HiveField(5)
  final String hiveSpecialization;

  @HiveField(6)
  final int hiveExperience;

  @HiveField(7)
  final String hiveBio;

  @HiveField(8)
  final double hiveFees;

  @HiveField(9)
  final String? hiveHospital;

  @HiveField(10)
  final double hiveAverageRating;

  @HiveField(11)
  final int hiveTotalReviews;

  DoctorModel({
    required String id,
    required String userId,
    required String firstName,
    required String lastName,
    String? image,
    required String specialization,
    required int experience,
    required String bio,
    required double fees,
    String? hospital,
    required double averageRating,
    required int totalReviews,
    List<ScheduleModel>? schedules,
  })  : hiveId = id,
        hiveUserId = userId,
        hiveFirstName = firstName,
        hiveLastName = lastName,
        hiveImage = image,
        hiveSpecialization = specialization,
        hiveExperience = experience,
        hiveBio = bio,
        hiveFees = fees,
        hiveHospital = hospital,
        hiveAverageRating = averageRating,
        hiveTotalReviews = totalReviews,
        super(
          id: id,
          userId: userId,
          firstName: firstName,
          lastName: lastName,
          image: image,
          specialization: specialization,
          experience: experience,
          bio: bio,
          fees: fees,
          hospital: hospital,
          averageRating: averageRating,
          totalReviews: totalReviews,
          schedules: schedules,
        );

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
      schedules: json['schedules'] != null
          ? (json['schedules'] as List)
              .map((s) => ScheduleModel.fromJson(s))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'image': image,
      'specialization': specialization,
      'experience': experience,
      'bio': bio,
      'fees': fees,
      'hospital': hospital,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'schedules': schedules?.map((e) => (e as ScheduleModel).toJson()).toList(),
    };
  }

  factory DoctorModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return DoctorModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      image: map['image'] as String?,
      specialization: map['specialization'] as String? ?? '',
      experience: map['experience'] as int? ?? 0,
      bio: map['bio'] as String? ?? '',
      fees: (map['fees'] as num?)?.toDouble() ?? 0,
      hospital: map['hospital'] as String?,
      averageRating: (map['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: map['totalReviews'] as int? ?? 0,
      schedules: map['schedules'] != null
          ? (map['schedules'] as List)
              .map((s) => ScheduleModel.fromJson(Map<String, dynamic>.from(s)))
              .toList()
          : null,
    );
  }
}
