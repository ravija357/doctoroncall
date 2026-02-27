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
import 'package:doctoroncall/screens/doctor/availability_screen.dart';
import 'package:doctoroncall/screens/doctor/my_patients_screen.dart';
import 'package:doctoroncall/screens/doctor/revenue_screen.dart';
import 'package:doctoroncall/screens/doctor/reviews_screen.dart';
import 'package:doctoroncall/screens/doctor/pending_requests_screen.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_bloc.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_event.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/screens/patient/appointment_list_screen.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  List<dynamic> _cachedAppointments = [];
  @override
  void initState() {
    super.initState();
    context.read<AppointmentBloc>().add(const LoadDoctorAppointmentsRequested());
    context.read<DoctorBloc>().add(const LoadDoctorsRequested());
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AppointmentBloc>().add(const LoadDoctorAppointmentsRequested());
        context.read<DoctorBloc>().add(const LoadDoctorsRequested());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
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
                    valueListenable: Hive.box(HiveBoxes.users).listenable(),
                    builder: (context, Box box, _) {
                      final userData = box.get('currentUser');
                      final String firstName;
                      final String lastName;
                      if (userData is Map) {
                        firstName = userData['firstName'] ?? 'Doctor';
                        lastName = userData['lastName'] ?? '';
                      } else {
                        firstName = box.get('firstName', defaultValue: 'Doctor');
                        lastName = box.get('lastName', defaultValue: '');
                      }
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
                    valueListenable: Hive.box(HiveBoxes.users).listenable(),
                    builder: (context, Box box, _) {
                      final userData = box.get('currentUser');
                      final String? imageUrl;
                      if (userData is Map) {
                        imageUrl = userData['profileImage'];
                      } else {
                        imageUrl = box.get('profileImage');
                      }
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
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                              ),
                              child: Icon(Icons.notifications_rounded, color: Colors.grey.shade800, size: 26),
                            ),
                            if (unread > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF3B30),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                  child: Center(
                                    child: Text(
                                      unread > 9 ? '9+' : unread.toString(),
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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
              if (state is DoctorAppointmentsLoaded) {
                _cachedAppointments = state.appointments;
              }
              
              if (state is AppointmentLoading && _cachedAppointments.isEmpty) {
                return const SizedBox(
                  height: 400,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8))),
                );
              }
              
              final appointments = _cachedAppointments;
              final bool isRefreshing = state is AppointmentLoading;
              
              // Only confirmed/completed/scheduled for today
              final today = appointments.where((a) {
                final d = DateTime.tryParse(a.dateTime.toString()) ?? a.dateTime;
                final isToday = d.year == DateTime.now().year &&
                    d.month == DateTime.now().month &&
                    d.day == DateTime.now().day;
                return isToday && a.status.toLowerCase() != 'pending';
              }).toList();

              // All pending appointments regardless of date, sorted by date (newest first)
              final pending = appointments.where((a) => a.status.toLowerCase() == 'pending').toList()
                ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

              print('[DASHBOARD] Total appointments: ${appointments.length}, Pending: ${pending.length}');

                  // Read current doctor to get rating and fee
                  double rating = 0.0;
                  double fees = 1000.0;
                  
                  return BlocBuilder<DoctorBloc, DoctorState>(
                    builder: (context, doctorState) {
                      if (doctorState is DoctorsLoaded) {
                        final currentUserData = Hive.box(HiveBoxes.users).get('currentUser');
                        if (currentUserData is Map) {
                          final currentUserId = currentUserData['_id'] ?? currentUserData['id'];
                          try {
                            final myDoc = (doctorState as DoctorsLoaded).doctors.firstWhere((d) => d.userId == currentUserId);
                            rating = myDoc.averageRating;
                            fees = myDoc.fees;
                          } catch (_) {
                            rating = (currentUserData['averageRating'] as num?)?.toDouble() ?? 0.0;
                            fees = (currentUserData['fees'] as num?)?.toDouble() ?? 1000.0;
                          }
                        }
                      }
                      
                      final completed = appointments.where((a) {
                        final s = a.status.toLowerCase();
                        return s == 'completed' || s == 'confirmed';
                      }).toList();
                      final revenue = completed.length * fees;

                      return Column(
                        children: [
                          if (isRefreshing)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: LinearProgressIndicator(
                                backgroundColor: Colors.transparent,
                                color: Color(0xFF6AA9D8),
                                minHeight: 2,
                              ),
                            ),
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
                                title: 'Pending Requests',
                                value: state is AppointmentLoading ? '…' : '${pending.length}',
                                icon: Icons.hourglass_empty,
                                color: Colors.orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _StatCard(
                                title: 'Total Revenue',
                                value: state is AppointmentLoading ? '…' : 'Rs. ${revenue.toStringAsFixed(0)}',
                                icon: Icons.account_balance_wallet_rounded,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 16),
                              _StatCard(
                                title: 'Average Rating',
                                value: doctorState is DoctorLoading 
                                    ? '…' 
                                    : (rating > 0 ? rating.toStringAsFixed(1) : 'N/A'),
                                icon: Icons.star_rounded,
                                color: Colors.amber,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                  // --- SECTION: MANAGEMENT SERVICES ---
                  const Text(
                    'Management Services',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: _QuickActionCard(
                            icon: Icons.calendar_month_rounded,
                            label: 'Schedules',
                            color: Colors.blue.shade50,
                            iconColor: Colors.blue.shade600,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailabilityScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: _QuickActionCard(
                            icon: Icons.people_rounded,
                            label: 'Patients',
                            color: Colors.teal.shade50,
                            iconColor: Colors.teal.shade600,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPatientsScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: _QuickActionCard(
                            icon: Icons.payments_rounded,
                            label: 'Revenue',
                            color: Colors.green.shade50,
                            iconColor: Colors.green.shade600,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: _QuickActionCard(
                            icon: Icons.star_rounded,
                            label: 'Reviews',
                            color: Colors.amber.shade50,
                            iconColor: Colors.amber.shade600,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewsScreen())),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 100,
                          child: _QuickActionCard(
                            icon: Icons.analytics_rounded,
                            label: 'Analytics',
                            color: Colors.orange.shade50,
                            iconColor: Colors.orange.shade600,
                            onTap: () {}, // Planned feature
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // --- PREMIUM RECENT REQUESTS SECTION ---
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AppointmentListScreen(isFromBottomNav: false))
                            );
                          },
                          child: const Text('View All', style: TextStyle(color: Color(0xFF6AA9D8), fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (appointments.isEmpty)
                    Container(
                      height: 120,
                      width: double.infinity,
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No recent activity right now.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 190, // Taller to accommodate status chip
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: appointments.length > 10 ? 10 : appointments.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 16),
                        padding: const EdgeInsets.only(right: 20),
                        itemBuilder: (context, i) {
                          final ap = appointments[i];
                          final pName = ap.patientName ?? 'Patient Request';
                          final formattedDate = DateFormat('MMM d, yyyy').format(ap.dateTime);
                          final status = ap.status.toLowerCase();

                          Color statusColor;
                          IconData statusIcon;
                          if (status == 'confirmed') {
                            statusColor = Colors.green;
                            statusIcon = Icons.check_circle_outline;
                          } else if (status == 'pending') {
                            statusColor = Colors.orange;
                            statusIcon = Icons.hourglass_empty;
                          } else if (status == 'cancelled') {
                            statusColor = Colors.red;
                            statusIcon = Icons.cancel_outlined;
                          } else if (status == 'completed') {
                            statusColor = const Color(0xFF4889A8);
                            statusIcon = Icons.task_alt_rounded;
                          } else {
                            statusColor = Colors.blue;
                            statusIcon = Icons.info_outline;
                          }

                          return Container(
                            width: 220,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF4889A8).withOpacity(0.1),
                                      child: Text(
                                        pName.isNotEmpty ? pName[0].toUpperCase() : 'P',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4889A8), fontSize: 14),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        pName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  formattedDate,
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  ap.startTime,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF4889A8)),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(statusIcon, size: 12, color: statusColor),
                                      const SizedBox(width: 6),
                                      Text(
                                        status.toUpperCase(),
                                        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Today's Schedule Section
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
                                      ap.patientName ?? 'Patient Appointment',
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
          );
        },
          ),
        ],
      ),
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

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
    );
  }
}
