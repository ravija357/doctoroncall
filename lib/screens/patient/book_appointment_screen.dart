import 'package:flutter/material.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/screens/patient/esewa_payment_screen.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';

class BookAppointmentScreen extends ConsumerStatefulWidget {
  final Doctor? doctor;
  const BookAppointmentScreen({super.key, this.doctor});

  @override
  ConsumerState<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends ConsumerState<BookAppointmentScreen>
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
    Future.microtask(() => _loadAvailability());
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
    ref.read(appointmentNotifierProvider.notifier).loadAvailability(widget.doctor!.id, _selectedDate);
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
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      return;
    }

    final slot = _slots[_selectedSlotIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EsewaPaymentScreen(
          doctor: widget.doctor!,
          selectedDate: _selectedDate,
          startTime: slot['startTime'] as String,
          endTime: slot['endTime'] as String,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    ref.listen<AppointmentState>(appointmentNotifierProvider, (previous, next) {
      if (next is AvailabilityLoaded) {
        setState(() {
          _slots = next.slots.isNotEmpty ? next.slots : _generateDefaultSlots();
          _loadingSlots = false;
        });
      } else if (next is AppointmentError) {
        setState(() {
          _slots = _generateDefaultSlots();
          _loadingSlots = false;
        });
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // Premium App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : null,
                  ),
                  child: Icon(Icons.arrow_back_ios_new, color: theme.iconTheme.color, size: 18),
                ),
              ),
                centerTitle: true,
                title: Text(
                  'Make An Appointment',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent, 
                          isDark ? theme.dividerColor.withOpacity(0.1) : Colors.grey.shade200, 
                          Colors.transparent
                        ],
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
                        _buildDoctorInfoBar(theme, isDark),
                        const SizedBox(height: 24),
                      ],

                      // Calendar card
                      _buildCalendarCard(theme, isDark),
                      const SizedBox(height: 28),

                      // Time Slots section
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Available Time Slots',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTimeSlots(theme, isDark),
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
    );
  }

  Widget _buildDoctorInfoBar(ThemeData theme, bool isDark) {
    final doctor = widget.doctor!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? theme.cardColor : theme.primaryColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (!isDark) BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
        border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? theme.scaffoldBackgroundColor : Colors.white.withOpacity(0.25),
              borderRadius: BorderRadius.circular(14),
              image: doctor.image != null
                  ? DecorationImage(image: ImageUtils.getImageProvider(doctor.image)!, fit: BoxFit.cover)
                  : null,
            ),
            child: doctor.image == null
                ? Icon(Icons.person, color: isDark ? Colors.grey.shade700 : Colors.white, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dr. ${doctor.firstName} ${doctor.lastName}',
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w700, 
                    color: isDark ? theme.textTheme.titleMedium?.color : Colors.white
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${doctor.specialization} • ${doctor.experience} yrs exp',
                  style: TextStyle(
                    fontSize: 13, 
                    color: isDark ? Colors.grey.shade400 : Colors.white.withOpacity(0.85)
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? theme.scaffoldBackgroundColor : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? theme.dividerColor.withOpacity(0.1) : Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              'NPR ${doctor.fees.toStringAsFixed(0)}',
              style: TextStyle(
                color: isDark ? theme.primaryColor : Colors.white, 
                fontWeight: FontWeight.w700, 
                fontSize: 13
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(ThemeData theme, bool isDark) {
    final monthYear = DateFormat('MMMM yyyy').format(_focusedMonth);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 6)),
        ],
        border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : null,
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
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : null,
                  ),
                  child: Icon(Icons.chevron_left, color: theme.iconTheme.color, size: 22),
                ),
              ),
              Text(
                monthYear,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: _goToNextMonth,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : null,
                  ),
                  child: Icon(Icons.chevron_right, color: theme.iconTheme.color, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Day labels
          _buildDayLabels(isDark),
          const SizedBox(height: 8),
          // Day grid
          _buildDayGrid(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildDayLabels(bool isDark) {
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
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDayGrid(ThemeData theme, bool isDark) {
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
                        ? theme.primaryColor
                        : isToday
                            ? theme.primaryColor.withOpacity(0.1)
                            : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected && !isDark
                        ? [BoxShadow(color: theme.primaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 3))]
                        : [],
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isPast
                            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade300)
                            : isSelected
                                ? Colors.white
                                : isToday
                                    ? theme.primaryColor
                                    : (isDark ? Colors.grey.shade400 : theme.primaryColor),
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

  Widget _buildTimeSlots(ThemeData theme, bool isDark) {
    if (_loadingSlots) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: theme.primaryColor, strokeWidth: 2.5),
        ),
      );
    }

    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 44, color: isDark ? Colors.grey.shade700 : Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No slots for this date',
              style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
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
                  ? (isDark ? Colors.grey.shade900 : theme.scaffoldBackgroundColor)
                  : isSelected
                      ? theme.primaryColor
                      : theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isBooked
                    ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
                    : isSelected
                        ? theme.primaryColor
                        : theme.dividerColor.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: isSelected && !isDark
                  ? [BoxShadow(color: theme.primaryColor.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4))]
                  : [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isBooked
                    ? (isDark ? Colors.grey.shade700 : Colors.grey.shade400)
                    : isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey.shade300 : theme.primaryColor),
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
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
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
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.green, fontStyle: FontStyle.italic),
                  ),
                  TextSpan(
                    text: 'Sewa',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.green),
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
