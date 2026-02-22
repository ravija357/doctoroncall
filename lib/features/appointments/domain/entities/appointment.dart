import 'package:equatable/equatable.dart';

class Appointment extends Equatable {
  final String? id;
  final String doctorId;
  final String patientId;
  final DateTime dateTime;
  final String status;
  final String? notes;

  const Appointment({
    this.id,
    required this.doctorId,
    required this.patientId,
    required this.dateTime,
    required this.status,
    this.notes,
  });

  @override
  List<Object?> get props => [id, doctorId, patientId, dateTime, status, notes];
}
