import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/features/notifications/presentation/providers/notification_provider.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_state.dart';
import 'package:doctoroncall/screens/shared/notification_screen.dart';
import 'package:doctoroncall/screens/shared/profile_screen.dart';
import 'package:doctoroncall/screens/doctor/availability_screen.dart';
import 'package:doctoroncall/screens/doctor/my_patients_screen.dart';
import 'package:doctoroncall/screens/doctor/revenue_screen.dart';
import 'package:doctoroncall/screens/doctor/reviews_screen.dart';
import 'package:doctoroncall/features/doctors/presentation/providers/doctor_provider.dart';
import 'package:doctoroncall/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/screens/patient/appointment_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';

class DoctorDashboardScreen extends ConsumerStatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  ConsumerState<DoctorDashboardScreen> createState() =>
      _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends ConsumerState<DoctorDashboardScreen> {
  List<dynamic> _cachedAppointments = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(appointmentNotifierProvider.notifier).loadDoctorAppointments();
      ref.read(doctorNotifierProvider.notifier).loadDoctors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final appointmentState = ref.watch(appointmentNotifierProvider);
    final doctorState = ref.watch(doctorNotifierProvider);

    if (appointmentState is DoctorAppointmentsLoaded) {
      _cachedAppointments = appointmentState.appointments;
    }

    final appointments = _cachedAppointments;
    final bool isRefreshing = appointmentState is AppointmentLoading;

    // Only confirmed/completed/scheduled for today
    final today = appointments.where((a) {
      final d = DateTime.tryParse(a.dateTime.toString()) ?? a.dateTime;
      final isToday =
          d.year == DateTime.now().year &&
          d.month == DateTime.now().month &&
          d.day == DateTime.now().day;
      return isToday && a.status.toLowerCase() != 'pending';
    }).toList();

    // All pending appointments regardless of date, sorted by date (newest first)
    final pending =
        appointments.where((a) => a.status.toLowerCase() == 'pending').toList()
          ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    double rating = 0.0;
    double fees = 1000.0;

    if (doctorState is DoctorsLoaded) {
      final currentUserData = Hive.box(HiveBoxes.users).get('currentUser');
      if (currentUserData is Map) {
        final currentUserId = currentUserData['_id'] ?? currentUserData['id'];
        try {
          final myDoc = doctorState.doctors.firstWhere(
            (d) => d.userId == currentUserId,
          );
          rating = myDoc.averageRating;
          fees = myDoc.fees;
        } catch (_) {
          rating =
              (currentUserData['averageRating'] as num?)?.toDouble() ?? 0.0;
          fees = (currentUserData['fees'] as num?)?.toDouble() ?? 1000.0;
        }
      }
    }

    final completed = appointments.where((a) {
      final s = a.status.toLowerCase();
      return s == 'completed' || s == 'confirmed';
    }).toList();
    final revenue = completed.length * fees;

    return Stack(
      children: [
        // Background Gradient
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF70c0fa).withValues(alpha: isDark ? 0.3 : 0.6),
                  const Color(0xFF70c0fa).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
        RefreshIndicator(
          color: theme.primaryColor,
          backgroundColor: theme.cardColor,
          onRefresh: () async {
            await ref
                .read(appointmentNotifierProvider.notifier)
                .loadDoctorAppointments();
            await ref.read(doctorNotifierProvider.notifier).loadDoctors();
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
                        Text(
                          'Dashboard',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ValueListenableBuilder(
                          valueListenable: Hive.box(
                            HiveBoxes.users,
                          ).listenable(),
                          builder: (context, Box box, _) {
                            final userData = box.get('currentUser');
                            final String firstName;
                            final String lastName;
                            if (userData is Map) {
                              firstName = userData['firstName'] ?? 'Doctor';
                              lastName = userData['lastName'] ?? '';
                            } else {
                              firstName = box.get(
                                'firstName',
                                defaultValue: 'Doctor',
                              );
                              lastName = box.get('lastName', defaultValue: '');
                            }
                            return Text(
                              'Welcome, Dr. $firstName $lastName',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        ValueListenableBuilder(
                          valueListenable: Hive.box(
                            HiveBoxes.users,
                          ).listenable(),
                          builder: (context, Box box, _) {
                            final userData = box.get('currentUser');
                            final String? imageUrl;
                            if (userData is Map) {
                              imageUrl = userData['profileImage'];
                            } else {
                              imageUrl = box.get('profileImage');
                            }
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 2,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isDark
                                      ? theme.cardColor
                                      : Colors.grey.shade100,
                                  backgroundImage: ImageUtils.getImageProvider(
                                    imageUrl,
                                  ),
                                  child: imageUrl == null
                                      ? Icon(
                                          Icons.person,
                                          color: Colors.grey.shade500,
                                        )
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        () {
                          final state = ref.watch(notificationNotifierProvider);
                          final unread = state is NotificationsLoaded
                              ? state.unreadCount
                              : 0;
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationScreen(),
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.2 : 0.04,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    border: isDark
                                        ? Border.all(
                                            color: theme.dividerColor
                                                .withValues(alpha: 0.1),
                                          )
                                        : null,
                                  ),
                                  child: Icon(
                                    Icons.notifications_rounded,
                                    color: theme.iconTheme.color,
                                    size: 26,
                                  ),
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF70c0fa),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? Colors.black
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 20,
                                        minHeight: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unread > 9 ? '9+' : unread.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Live stat cards
                Column(
                  children: [
                    if (isRefreshing)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(
                          backgroundColor: theme.primaryColor.withValues(
                            alpha: 0.1,
                          ),
                          color: theme.primaryColor,
                          minHeight: 2,
                        ),
                      ),
                    Row(
                      children: [
                        _StatCard(
                          title: 'Appointments',
                          value: isRefreshing ? '…' : '${appointments.length}',
                          icon: Icons.calendar_today_rounded,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 16),
                        _StatCard(
                          title: 'Requests',
                          value: isRefreshing ? '…' : '${pending.length}',
                          icon: Icons.hourglass_top_rounded,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatCard(
                          title: 'Revenue',
                          value: isRefreshing
                              ? '…'
                              : 'Rs. ${revenue.toStringAsFixed(0)}',
                          icon: Icons.payments_rounded,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _StatCard(
                          title: 'Rating',
                          value: doctorState is DoctorLoading
                              ? '…'
                              : (rating > 0
                                    ? rating.toStringAsFixed(1)
                                    : 'N/A'),
                          icon: Icons.star_rounded,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // --- SECTION: MANAGEMENT SERVICES ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Management Services',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _QuickActionCard(
                            icon: Icons.calendar_month_rounded,
                            label: 'Schedules',
                            color: Colors.blue,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AvailabilityScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _QuickActionCard(
                            icon: Icons.people_rounded,
                            label: 'Patients',
                            color: Colors.teal,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MyPatientsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _QuickActionCard(
                            icon: Icons.payments_rounded,
                            label: 'Revenue',
                            color: Colors.green,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RevenueScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _QuickActionCard(
                            icon: Icons.star_rounded,
                            label: 'Reviews',
                            color: Colors.amber,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReviewsScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _QuickActionCard(
                            icon: Icons.analytics_rounded,
                            label: 'Analytics',
                            color: Colors.orange,
                            onTap: () {}, // Planned feature
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- RECENT ACTIVITY SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Activity',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AppointmentListScreen(
                                  isFromBottomNav: false,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'View All',
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (appointments.isEmpty)
                      Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: isDark
                              ? Border.all(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.1,
                                  ),
                                )
                              : null,
                          boxShadow: [
                            if (!isDark)
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_rounded,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No recent activity right now.',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 190,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: appointments.length > 5
                              ? 5
                              : appointments.length,
                          separatorBuilder: (_, contextX) =>
                              const SizedBox(width: 16),
                          itemBuilder: (context, i) {
                            final ap = appointments[i];
                            final pName = ap.patientName ?? 'Patient Request';
                            final formattedDate = DateFormat(
                              'MMM d, yyyy',
                            ).format(ap.dateTime);
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
                              statusColor = theme.primaryColor;
                              statusIcon = Icons.task_alt_rounded;
                            } else {
                              statusColor = Colors.blue;
                              statusIcon = Icons.info_outline;
                            }

                            return Container(
                              width: 220,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: isDark
                                    ? Border.all(
                                        color: theme.dividerColor.withValues(
                                          alpha: 0.1,
                                        ),
                                      )
                                    : null,
                                boxShadow: [
                                  if (!isDark)
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
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
                                        backgroundColor: theme.primaryColor
                                            .withValues(alpha: 0.1),
                                        child: Text(
                                          pName.isNotEmpty
                                              ? pName[0].toUpperCase()
                                              : 'P',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: theme.primaryColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          pName,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    formattedDate,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ap.startTime,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: isDark ? 0.15 : 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: statusColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          statusIcon,
                                          size: 12,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          status.toUpperCase(),
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Today's Schedule",
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (appointmentState is AppointmentLoading &&
                        appointments.isEmpty)
                      Center(
                        child: CircularProgressIndicator(
                          color: theme.primaryColor,
                        ),
                      )
                    else if (appointmentState is AppointmentError)
                      Center(
                        child: Text(
                          appointmentState.message,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (today.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          border: isDark
                              ? Border.all(
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.1,
                                  ),
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            'No appointments for today.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: today.length,
                        separatorBuilder: (_, contextX) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final ap = today[i];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: isDark
                                  ? Border.all(
                                      color: theme.dividerColor.withValues(
                                        alpha: 0.1,
                                      ),
                                    )
                                  : null,
                              boxShadow: [
                                if (!isDark)
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                  ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ap.patientName ?? 'Patient Appointment',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(ap.dateTime),
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 13,
                                        ),
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
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? color.withValues(alpha: 1.0) : color,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
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
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 95,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: isDark
              ? Border.all(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                )
              : null,
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
