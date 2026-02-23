import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_state.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/screens/shared/notification_screen.dart';
import 'package:doctoroncall/screens/shared/profile_screen.dart';
import 'package:intl/intl.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AppointmentBloc>().add(const LoadDoctorAppointmentsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ValueListenableBuilder(
                    valueListenable: Hive.box(HiveBoxes.users).listenable(keys: ['firstName', 'lastName']),
                    builder: (context, Box box, _) {
                      final firstName = box.get('firstName', defaultValue: 'Doctor');
                      final lastName = box.get('lastName', defaultValue: '');
                      return Text(
                        'Welcome, Dr. $firstName $lastName',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      );
                    },
                  ),
                ],
              ),
              Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: Hive.box(HiveBoxes.users).listenable(keys: ['profileImage']),
                    builder: (context, Box box, _) {
                      final imageUrl = box.get('profileImage');
                      return GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProfileScreen())),
                        child: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: ImageUtils.getImageProvider(imageUrl),
                          child: imageUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  BlocBuilder<NotificationBloc, NotificationState>(
                    builder: (context, state) {
                      final unread = state is NotificationsLoaded ? state.unreadCount : 0;
                      return GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const NotificationScreen())),
                        child: Stack(children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                            ),
                            child: const Icon(Icons.notifications_none, color: Color(0xFF6AA9D8)),
                          ),
                          if (unread > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Color(0xFF6AA9D8), shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  unread > 9 ? '9+' : unread.toString(),
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ]),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Live stat cards
          BlocBuilder<AppointmentBloc, AppointmentState>(
            builder: (context, state) {
              final appointments = state is DoctorAppointmentsLoaded ? state.appointments : <dynamic>[];
              final today = appointments.where((a) {
                final d = DateTime.tryParse(a.dateTime.toString()) ?? a.dateTime;
                return d.year == DateTime.now().year &&
                    d.month == DateTime.now().month &&
                    d.day == DateTime.now().day;
              }).toList();

              return Column(
                children: [
                  Row(
                    children: [
                      _StatCard(
                        title: 'Total Appointments',
                        value: state is AppointmentLoading ? '…' : '${appointments.length}',
                        icon: Icons.calendar_today,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _StatCard(
                        title: 'Today\'s Patients',
                        value: state is AppointmentLoading ? '…' : '${today.length}',
                        icon: Icons.person,
                        color: Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Today\'s Schedule',
                      style: TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (state is AppointmentLoading)
                    const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8)))
                  else if (state is AppointmentError)
                    Center(child: Text(state.message, style: const TextStyle(color: Colors.red)))
                  else if (today.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Center(
                        child: Text('No appointments for today.', style: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 16)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: today.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final ap = today[i];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6AA9D8).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.person_outline, color: Color(0xFF6AA9D8)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Patient Appointment',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      DateFormat('h:mm a').format(ap.dateTime),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              _StatusChip(status: ap.status),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'confirmed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: _color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
