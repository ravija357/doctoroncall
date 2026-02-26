import '../../domain/entities/schedule.dart';

class ScheduleModel extends Schedule {
  const ScheduleModel({
    required String day,
    required String startTime,
    required String endTime,
    required bool isOff,
  }) : super(
          day: day,
          startTime: startTime,
          endTime: endTime,
          isOff: isOff,
        );

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      day: json['day'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isOff: json['isOff'] ?? false,
    );
  }

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
