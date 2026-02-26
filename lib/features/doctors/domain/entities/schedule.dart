import 'package:equatable/equatable.dart';

class Schedule extends Equatable {
  final String day;
  final String startTime;
  final String endTime;
  final bool isOff;

  const Schedule({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isOff,
  });

  @override
  List<Object?> get props => [day, startTime, endTime, isOff];
}
