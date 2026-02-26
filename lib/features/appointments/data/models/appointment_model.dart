import 'package:hive/hive.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';

@HiveType(typeId: 1)
class AppointmentModel extends Appointment {
  @HiveField(0)
  final String? hiveId;

  @HiveField(1)
  final String hiveDoctorId;

  @HiveField(2)
  final String hivePatientId;

  @HiveField(3)
  final String hiveDateTimeStr;

  @HiveField(4)
  final String hiveStatus;

  @HiveField(5)
  final String? hiveNotes;

  @HiveField(6)
  final String hiveStartTime;

  @HiveField(7)
  final String hiveEndTime;

  @HiveField(8)
  final String? hiveReason;

  @HiveField(9)
  final String? hiveDoctorName;

  @HiveField(10)
  final String? hiveSpecialization;

  @HiveField(11)
  final String? hiveHospital;

  @HiveField(12)
  final String? hiveDoctorImage;

  @HiveField(13)
  final String? hivePatientName;

  @HiveField(14)
  final String? hivePrescriptionUrl;

  AppointmentModel({
    String? id,
    required String doctorId,
    required String patientId,
    required DateTime dateTime,
    required String startTime,
    required String endTime,
    required String status,
    String? reason,
    String? notes,
    String? doctorName,
    String? specialization,
    String? hospital,
    String? doctorImage,
    String? patientName,
    String? prescriptionUrl,
  })  : hiveId = id,
        hiveDoctorId = doctorId,
        hivePatientId = patientId,
        hiveDateTimeStr = dateTime.toIso8601String(),
        hiveStatus = status,
        hiveNotes = notes,
        hiveStartTime = startTime,
        hiveEndTime = endTime,
        hiveReason = reason,
        hiveDoctorName = doctorName,
        hiveSpecialization = specialization,
        hiveHospital = hospital,
        hiveDoctorImage = doctorImage,
        hivePatientName = patientName,
        hivePrescriptionUrl = prescriptionUrl,
        super(
          id: id,
          doctorId: doctorId,
          patientId: patientId,
          dateTime: dateTime,
          startTime: startTime,
          endTime: endTime,
          status: status,
          reason: reason,
          notes: notes,
          doctorName: doctorName,
          specialization: specialization,
          hospital: hospital,
          doctorImage: doctorImage,
          patientName: patientName,
          prescriptionUrl: prescriptionUrl,
        );

  /// Parse from backend JSON (populated doctor)
  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    // Doctor may be populated or just an ID string
    final doctor = json['doctor'];
    String doctorId = '';
    String? doctorName;
    String? specialization;
    String? hospital;
    String? doctorImage;

    if (doctor is Map<String, dynamic>) {
      doctorId = doctor['_id'] ?? '';
      final user = doctor['user'];
      if (user is Map<String, dynamic>) {
        final firstName = user['firstName'] ?? '';
        final lastName = user['lastName'] ?? '';
        doctorName = 'Dr. $firstName $lastName'.trim();
        doctorImage = user['image'];
      }
      specialization = doctor['specialization'];
      hospital = doctor['hospital'];
    } else if (doctor is String) {
      doctorId = doctor;
    }

    // Patient may be populated or just an ID string
    final patient = json['patient'];
    String patientId = '';
    String? patientName;
    if (patient is Map<String, dynamic>) {
      patientId = patient['_id'] ?? '';
      final firstName = patient['firstName'] ?? '';
      final lastName = patient['lastName'] ?? '';
      if (firstName.isNotEmpty || lastName.isNotEmpty) {
        patientName = '$firstName $lastName'.trim();
      }
    } else if (patient is String) {
      patientId = patient;
    }

    return AppointmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      doctorId: doctorId,
      patientId: patientId,
      dateTime: json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      status: json['status'] ?? 'pending',
      reason: json['reason'],
      notes: json['notes'],
      doctorName: doctorName,
      specialization: specialization,
      hospital: hospital,
      doctorImage: doctorImage,
      patientName: patientName,
      prescriptionUrl: json['prescriptionUrl'],
    );
  }

  /// Serialize for creating appointment via POST /appointments
  Map<String, dynamic> toJson() {
    return {
      'doctorId': doctorId,
      'date': "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}",
      'startTime': startTime,
      'endTime': endTime,
      'reason': reason,
    };
  }

  Map<String, dynamic> toHiveMap() {
    return {
      'id': id,
      'doctorId': doctorId,
      'patientId': patientId,
      'dateTime': dateTime.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'status': status,
      'reason': reason,
      'notes': notes,
      'doctorName': doctorName,
      'specialization': specialization,
      'hospital': hospital,
      'doctorImage': doctorImage,
      'patientName': patientName,
      'prescriptionUrl': prescriptionUrl,
    };
  }

  factory AppointmentModel.fromHiveMap(Map<dynamic, dynamic> map) {
    return AppointmentModel(
      id: map['id'] as String?,
      doctorId: map['doctorId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      dateTime: DateTime.tryParse(map['dateTime']?.toString() ?? '') ?? DateTime.now(),
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      reason: map['reason'] as String?,
      notes: map['notes'] as String?,
      doctorName: map['doctorName'] as String?,
      specialization: map['specialization'] as String?,
      hospital: map['hospital'] as String?,
      doctorImage: map['doctorImage'] as String?,
      patientName: map['patientName'] as String?,
      prescriptionUrl: map['prescriptionUrl'] as String?,
    );
  }
}
