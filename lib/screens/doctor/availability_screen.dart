import 'package:flutter/material.dart';
import 'package:doctoroncall/features/doctors/domain/entities/schedule.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/doctors/presentation/providers/doctor_provider.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  List<Schedule> _schedules = [];
  bool _isInitialLoad = true;

  final List<String> _days = [
    "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _checkAndLoad());
  }

  void _checkAndLoad() {
    final state = ref.read(doctorNotifierProvider);
    print('[AVAILABILITY] Current state: $state');
    if (state is DoctorsLoaded) {
      _loadMySchedule(state);
    } else {
      print('[AVAILABILITY] Triggering loadDoctors');
      ref.read(doctorNotifierProvider.notifier).loadDoctors();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF4889A8);

    ref.listen<DoctorState>(doctorNotifierProvider, (previous, next) {
      if (next is DoctorsLoaded) {
        _loadMySchedule(next);
      } else if (next is DoctorScheduleUpdated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule updated successfully!')),
        );
        Navigator.pop(context);
      } else if (next is DoctorError) {
        final errorState = next as DoctorError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorState.message)),
        );
      }
    });

    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                ? [Theme.of(context).scaffoldBackgroundColor, Theme.of(context).scaffoldBackgroundColor]
                : [primaryColor, const Color(0xFFF8FAFC)],
              stops: const [0.0, 0.3],
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
                                color: isDark ? Theme.of(context).cardColor : Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.chevron_left, color: isDark ? Theme.of(context).iconTheme.color : Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Availability',
                            style: TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Theme.of(context).textTheme.titleLarge?.color : Colors.white
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(doctorNotifierProvider.notifier).updateSchedule(
                            _schedules.map((s) => s.toJson()).toList(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Theme.of(context).primaryColor : Colors.white,
                          foregroundColor: isDark ? Colors.white : primaryColor,
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
                    ? Center(child: CircularProgressIndicator(color: isDark ? Theme.of(context).primaryColor : Colors.white))
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: schedule.isOff 
          ? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50) 
          : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: schedule.isOff 
            ? (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200) 
            : Theme.of(context).dividerColor.withOpacity(0.1)
        ),
        boxShadow: [
          if (!schedule.isOff)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
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
                color: schedule.isOff ? Colors.grey : Theme.of(context).textTheme.bodyLarge?.color,
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
            activeColor: Theme.of(context).primaryColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}
