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
  final String? patientName;  // available when doctor fetches appointments
  final String? doctorName;
  final String? specialization;
  final String? hospital;
  final String? doctorImage;
  final String? prescriptionUrl;

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
    this.patientName,
    this.doctorName,
    this.specialization,
    this.hospital,
    this.doctorImage,
    this.prescriptionUrl,
  });

  @override
  List<Object?> get props => [id, doctorId, patientId, dateTime, startTime, endTime, status, reason, notes, patientName, prescriptionUrl];
}
