import '../../domain/entities/schedule.dart';

class ScheduleModel extends Schedule {
  const ScheduleModel({
    required super.day,
    required super.startTime,
    required super.endTime,
    required super.isOff,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isOff: json['isOff'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'startTime': startTime,
      'endTime': endTime,
      'isOff': isOff,
    };
  }

  factory ScheduleModel.fromEntity(Schedule entity) {
    return ScheduleModel(
      day: entity.day,
      startTime: entity.startTime,
      endTime: entity.endTime,
      isOff: entity.isOff,
    );
  }
}
