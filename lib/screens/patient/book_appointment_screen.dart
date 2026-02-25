import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_event.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/screens/patient/esewa_payment_screen.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Doctor? doctor;
  const BookAppointmentScreen({super.key, this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  int _selectedSlotIndex = -1;
  List<Map<String, dynamic>> _slots = [];
  bool _loadingSlots = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _selectedDate = DateTime.now();
    _loadAvailability();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _loadAvailability() {
    if (widget.doctor == null) return;
    setState(() {
      _selectedSlotIndex = -1;
      _loadingSlots = true;
    });
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    context.read<AppointmentBloc>().add(
      LoadAvailabilityRequested(doctorId: widget.doctor!.id, date: dateStr),
    );
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDate = day;
      _selectedSlotIndex = -1;
    });
    _loadAvailability();
  }

  void _navigateToPayment() {
    if (_selectedSlotIndex < 0 || _selectedSlotIndex >= _slots.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a time slot', style: TextStyle(fontWeight: FontWeight.w500)),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: const Color(0xFF344955),
        ),
      );
      return;
    }

    final slot = _slots[_selectedSlotIndex];
    final appointmentBloc = context.read<AppointmentBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: appointmentBloc,
          child: EsewaPaymentScreen(
            doctor: widget.doctor!,
            selectedDate: _selectedDate,
            startTime: slot['startTime'] as String,
            endTime: slot['endTime'] as String,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: BlocListener<AppointmentBloc, AppointmentState>(
        listener: (context, state) {
          if (state is AvailabilityLoaded) {
            setState(() {
              _slots = state.slots.isNotEmpty ? state.slots : _generateDefaultSlots();
              _loadingSlots = false;
            });
          } else if (state is AppointmentError) {
            setState(() {
              _slots = _generateDefaultSlots();
              _loadingSlots = false;
            });
          }
        },
        child: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            slivers: [
              // Premium App Bar
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF344955), size: 18),
                  ),
                ),
                centerTitle: true,
                title: const Text(
                  'Make An Appointment',
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

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Doctor info bar
                      if (widget.doctor != null) ...[
                        _buildDoctorInfoBar(),
                        const SizedBox(height: 24),
                      ],

                      // Calendar card
                      _buildCalendarCard(),
                      const SizedBox(height: 28),

                      // Time Slots section
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6AA9D8),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Available Time Slots',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D26),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTimeSlots(),
                      const SizedBox(height: 36),

                      // eSewa pay button
                      _buildEsewaPayButton(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorInfoBar() {
    final doctor = widget.doctor!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6AA9D8), Color(0xFF4A8FBF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6AA9D8).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              image: doctor.image != null
                  ? DecorationImage(image: ImageUtils.getImageProvider(doctor.image)!, fit: BoxFit.cover)
                  : null,
            ),
            child: doctor.image == null
                ? const Icon(Icons.person, color: Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${doctor.firstName} ${doctor.lastName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 3),
                Text(
                  '${doctor.specialization} • ${doctor.experience} yrs exp',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'NPR ${doctor.fees.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    final monthYear = DateFormat('MMMM yyyy').format(_focusedMonth);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          // Month header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: _goToPreviousMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_left, color: Color(0xFF344955), size: 22),
                ),
              ),
              Text(
                monthYear,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D26),
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: _goToNextMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4F8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right, color: Color(0xFF344955), size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Day labels
          _buildDayLabels(),
          const SizedBox(height: 8),
          // Day grid
          _buildDayGrid(),
        ],
      ),
    );
  }

  Widget _buildDayLabels() {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: labels.map((d) => SizedBox(
        width: 40,
        child: Center(
          child: Text(
            d,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDayGrid() {
    final year = _focusedMonth.year;
    final month = _focusedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final offset = firstDay.weekday - 1;

    return Column(
      children: List.generate(6, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col - offset;
              if (cellIndex < 0 || cellIndex >= daysInMonth) {
                return const SizedBox(width: 40, height: 40);
              }
              final day = cellIndex + 1;
              final cellDate = DateTime(year, month, day);
              final isToday = _isSameDay(cellDate, DateTime.now());
              final isSelected = _isSameDay(cellDate, _selectedDate);
              final isPast = cellDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

              return GestureDetector(
                onTap: isPast ? null : () => _onDaySelected(cellDate),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6AA9D8)
                        : isToday
                            ? const Color(0xFFE8F2F8)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF6AA9D8).withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isPast
                            ? Colors.grey.shade300
                            : isSelected
                                ? Colors.white
                                : isToday
                                    ? const Color(0xFF6AA9D8)
                                    : const Color(0xFF344955),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildTimeSlots() {
    if (_loadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFF6AA9D8), strokeWidth: 2.5),
        ),
      );
    }

    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No slots for this date',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(_slots.length, (index) {
        final slot = _slots[index];
        final isBooked = slot['isBooked'] == true;
        final isSelected = _selectedSlotIndex == index;
        final startTime = slot['startTime'] as String? ?? '';
        final endTime = slot['endTime'] as String? ?? '';
        final label = '${_formatTime(startTime)} - ${_formatTime(endTime)}';

        return GestureDetector(
          onTap: isBooked ? null : () => setState(() => _selectedSlotIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isBooked
                  ? const Color(0xFFF0F0F0)
                  : isSelected
                      ? const Color(0xFF6AA9D8)
                      : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isBooked
                    ? Colors.grey.shade200
                    : isSelected
                        ? const Color(0xFF6AA9D8)
                        : const Color(0xFFDDE3E8),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFF6AA9D8).withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isBooked
                    ? Colors.grey.shade400
                    : isSelected
                        ? Colors.white
                        : const Color(0xFF344955),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
                letterSpacing: 0.2,
                decoration: isBooked ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEsewaPayButton() {
    return GestureDetector(
      onTap: _navigateToPayment,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF60BB46), Color(0xFF4DA336)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: const Color(0xFF60BB46).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'e',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: 'Sewa',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(width: 1, height: 28, color: Colors.white.withOpacity(0.4)),
            const SizedBox(width: 14),
            const Text(
              'Pay & Book',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _generateDefaultSlots() {
    final slots = <Map<String, dynamic>>[];
    for (int hour = 9; hour < 17; hour++) {
      slots.add({'startTime': '${hour.toString().padLeft(2, '0')}:00', 'endTime': '${hour.toString().padLeft(2, '0')}:30', 'isBooked': false});
      slots.add({'startTime': '${hour.toString().padLeft(2, '0')}:30', 'endTime': '${(hour + 1).toString().padLeft(2, '0')}:00', 'isBooked': false});
    }
    return slots;
  }

  String _formatTime(String time24) {
    try {
      final parts = time24.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts[1];
      final ampm = hour >= 12 ? 'pm' : 'am';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute}$ampm';
    } catch (_) {
      return time24;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
