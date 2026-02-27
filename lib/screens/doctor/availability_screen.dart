import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/doctors/domain/entities/schedule.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_bloc.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_event.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  List<Schedule> _schedules = [];
  bool _isInitialLoad = true;

  final List<String> _days = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];

  @override
  void initState() {
    super.initState();
    _checkAndLoad();
  }

  void _checkAndLoad() {
    final state = context.read<DoctorBloc>().state;
    print('[AVAILABILITY] Current state: $state');
    if (state is DoctorsLoaded) {
      _loadMySchedule(state);
    } else {
      print('[AVAILABILITY] Triggering LoadDoctorsRequested');
      context.read<DoctorBloc>().add(const LoadDoctorsRequested());
    }
  }

  void _loadMySchedule(DoctorsLoaded state) {
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    final String? myUserId = userData is Map ? userData['id'] : box.get('userId');
    
    print('[AVAILABILITY] My User ID: $myUserId');
    print('[AVAILABILITY] Total doctors in state: ${state.doctors.length}');

    try {
      final me = state.doctors.firstWhere((d) {
        print('[AVAILABILITY] Checking doctor with userId: ${d.userId}');
        return d.userId == myUserId;
      });
      print('[AVAILABILITY] Found me! Schedules count: ${me.schedules?.length ?? 0}');
      setState(() {
        _schedules = List.from(me.schedules ?? 
          _days.map((day) => Schedule(day: day, startTime: "09:00", endTime: "17:00", isOff: false)).toList()
        );
        _isInitialLoad = false;
      });
    } catch (e) {
      print('[AVAILABILITY] Error finding me in doctors list: $e');
      // If we are initialized but haven't found me, maybe show an error or blank
      setState(() {
        _isInitialLoad = false;
      });
    }
  }

  Future<void> _selectTime(int index, bool isStart) async {
    final currentStr = isStart ? _schedules[index].startTime : _schedules[index].endTime;
    final parts = currentStr.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4889A8),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        final timeStr = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
        _schedules[index] = Schedule(
          day: _schedules[index].day,
          startTime: isStart ? timeStr : _schedules[index].startTime,
          endTime: isStart ? _schedules[index].endTime : timeStr,
          isOff: _schedules[index].isOff,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DoctorBloc, DoctorState>(
      listener: (context, state) {
        if (state is DoctorsLoaded) {
          _loadMySchedule(state);
        }
        if (state is DoctorScheduleUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule updated successfully!')),
          );
          Navigator.pop(context);
        }
        if (state is DoctorError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4889A8), Color(0xFFF8FAFC)],
              stops: [0.0, 0.3],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chevron_left, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Availability',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<DoctorBloc>().add(UpdateDoctorScheduleRequested(schedules: _schedules));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4889A8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _schedules.isEmpty 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _schedules.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final s = _schedules[index];
                          return _ScheduleItem(
                            schedule: s,
                            onTimeTap: (isStart) => _selectTime(index, isStart),
                            onToggleOff: (val) {
                              setState(() {
                                _schedules[index] = Schedule(
                                  day: s.day,
                                  startTime: s.startTime,
                                  endTime: s.endTime,
                                  isOff: val,
                                );
                              });
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleItem extends StatelessWidget {
  final Schedule schedule;
  final Function(bool) onTimeTap;
  final Function(bool) onToggleOff;

  const _ScheduleItem({
    required this.schedule,
    required this.onTimeTap,
    required this.onToggleOff,
  });

  String _formatTime(String time) {
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    final m = parts[1];
    final ampm = h >= 12 ? 'PM' : 'AM';
    final hr = h % 12 == 0 ? 12 : h % 12;
    return "$hr:$m $ampm";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: schedule.isOff ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: schedule.isOff ? Colors.grey.shade200 : Colors.transparent),
        boxShadow: [
          if (!schedule.isOff)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              schedule.day,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: schedule.isOff ? Colors.grey : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Opacity(
              opacity: schedule.isOff ? 0.3 : 1.0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TimeButton(
                      label: _formatTime(schedule.startTime),
                      onTap: schedule.isOff ? null : () => onTimeTap(true),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('–', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    _TimeButton(
                      label: _formatTime(schedule.endTime),
                      onTap: schedule.isOff ? null : () => onTimeTap(false),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Switch(
            value: !schedule.isOff,
            onChanged: (val) => onToggleOff(!val),
            activeColor: const Color(0xFF4889A8),
          ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _TimeButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4889A8)),
        ),
      ),
    );
  }
}
