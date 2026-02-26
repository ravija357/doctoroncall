import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class AppointmentListScreen extends StatefulWidget {
  final bool isFromBottomNav;
  const AppointmentListScreen({super.key, this.isFromBottomNav = false});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen>
    with SingleTickerProviderStateMixin {
  bool _showCurrent = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadAppointments();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadAppointments() {
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    final String? role = userData is Map ? userData['role'] : box.get('role');

    if (role == 'doctor') {
      context.read<AppointmentBloc>().add(const LoadDoctorAppointmentsRequested());
    } else {
      final userId = _getUserId();
      if (userId != null) {
        context.read<AppointmentBloc>().add(LoadAppointmentsRequested(userId: userId));
      }
    }
  }

  String? _getUserId() {
    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    if (userData is Map) return userData['id'] as String?;
    return box.get('userId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // Premium App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: (Navigator.canPop(context) && !widget.isFromBottomNav)
                  ? GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4F8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF344955), size: 18),
                      ),
                    )
                  : null,
              centerTitle: true,
              title: const Text(
                'My Appointments',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 19,
                  color: Color(0xFF1A1D26),
                  letterSpacing: -0.3,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.grey.shade200, Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),

            // Tab toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 20, 32, 4),
                child: _buildTabToggle(),
              ),
            ),

            // Appointment list
            SliverFillRemaining(
              child: BlocBuilder<AppointmentBloc, AppointmentState>(
                builder: (context, state) {
                  if (state is AppointmentLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8), strokeWidth: 2.5));
                  } else if (state is AppointmentError) {
                    return _buildErrorState(state.message);
                  } else if (state is AppointmentsLoaded) {
                    return _buildAppointmentList(state.appointments);
                  } else if (state is DoctorAppointmentsLoaded) {
                    return _buildAppointmentList(state.appointments);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _tabButton('Current', _showCurrent, () => setState(() => _showCurrent = true))),
          Expanded(child: _tabButton('History', !_showCurrent, () => setState(() => _showCurrent = false))),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isActive
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isActive ? const Color(0xFF1A1D26) : Colors.grey.shade500,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 40, color: Colors.red.shade300),
            ),
            const SizedBox(height: 18),
            Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _loadAppointments,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6AA9D8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(List<Appointment> appointments) {
    final now = DateTime.now();
    List<Appointment> filtered;
    if (_showCurrent) {
      filtered = appointments.where((a) {
        final isFuture = a.dateTime.isAfter(now.subtract(const Duration(days: 1)));
        final isActive = a.status == 'pending' || a.status == 'confirmed';
        return isFuture && isActive;
      }).toList();
    } else {
      filtered = appointments.where((a) {
        final isPast = a.dateTime.isBefore(now.subtract(const Duration(days: 1)));
        final isDone = a.status == 'cancelled' || a.status == 'completed';
        return isPast || isDone;
      }).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _showCurrent ? Icons.event_available : Icons.history,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _showCurrent ? 'No upcoming appointments' : 'No past appointments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                _showCurrent ? 'Book one with your doctor today!' : 'Your history will appear here',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadAppointments(),
      color: const Color(0xFF6AA9D8),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        itemCount: filtered.length,
        itemBuilder: (context, index) => _buildAppointmentCard(filtered[index], index),
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment apt, int index) {
    final dateStr = DateFormat('d MMM yyyy').format(apt.dateTime);
    final timeStr = _formatTime(apt.startTime);
    final doctorName = apt.doctorName ?? 'Doctor';
    final type = apt.specialization ?? apt.reason ?? 'Consultation';
    final place = apt.hospital ?? 'Online';
    final status = apt.status;
    final userId = _getUserId();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          children: [
            // Top row: Date, Time, Doctor
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date icon + text
                Expanded(child: _infoColumn(Icons.calendar_today, 'Date', dateStr)),
                Expanded(child: _infoColumn(Icons.access_time_rounded, 'Time', timeStr)),
                Expanded(child: _infoColumn(Icons.person_outline, 'Doctor', doctorName)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.grey.shade200, Colors.transparent],
                  ),
                ),
              ),
            ),
            // Bottom row: Type, Place, Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Type', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(type, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D26))),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Place', style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(place, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D26))),
                    ],
                  ),
                ),
                _buildStatusBadge(status, apt.id, userId),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: const Color(0xFF6AA9D8)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1D26)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, String? appointmentId, String? userId) {
    switch (status.toLowerCase()) {
      case 'cancelled':
        return _statusChip('Cancelled', const Color(0xFFE53935), Icons.cancel_outlined);
      case 'completed':
        return _statusChip('Done', const Color(0xFF6AA9D8), Icons.check_circle_outline);
      case 'confirmed':
        final cancelBtn = GestureDetector(
          onTap: () {
            if (appointmentId != null && userId != null) {
              _showCancelDialog(appointmentId, userId);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFD32F2F)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: const Color(0xFFE53935).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.close, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              ],
            ),
          ),
        );
        return cancelBtn;
      case 'pending':
        return Column(
          children: [
            _statusChip('Pending', Colors.orange, Icons.hourglass_empty),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                if (appointmentId != null && userId != null) {
                  _showCancelDialog(appointmentId, userId);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFD32F2F)]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFE53935).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.close, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        );
      default:
        return _statusChip('Unknown', Colors.grey, Icons.help_outline);
    }
  }

  Widget _statusChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }

  void _showCancelDialog(String appointmentId, String userId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.event_busy, color: Colors.red.shade400, size: 36),
            ),
            const SizedBox(height: 18),
            const Text(
              'Cancel Appointment?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF1A1D26)),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to cancel this appointment? This action cannot be undone.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.w500, height: 1.5),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: Text('Keep It', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF344955), fontSize: 15)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<AppointmentBloc>().add(
                      CancelAppointmentRequested(appointmentId: appointmentId, userId: userId),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFD32F2F)]),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFE53935).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Center(
                      child: Text('Yes, Cancel', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 15)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final ampm = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $ampm';
    } catch (_) {
      return time24;
    }
  }
}
