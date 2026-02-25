import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  final String? id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final String startTime;
  final String endTime;
  final String status;
  final String? reason;
  final String? notes;
  // Populated fields from backend
  final String? doctorName;
  final String? specialization;
  final String? hospital;
  final String? doctorImage;

  const Appointment({
    this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.reason,
    this.notes,
    this.doctorName,
    this.specialization,
    this.hospital,
    this.doctorImage,
  });

  @override
  List<Object?> get props => [id, doctorId, patientId, dateTime, startTime, endTime, status, reason, notes];
}
