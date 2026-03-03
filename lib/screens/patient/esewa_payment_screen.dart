import 'package:flutter/material.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';

class EsewaPaymentScreen extends ConsumerStatefulWidget {
  final Doctor doctor;
  final DateTime selectedDate;
  final String startTime;
  final String endTime;

  const EsewaPaymentScreen({
    super.key,
    required this.doctor,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
  });

  @override
  ConsumerState<EsewaPaymentScreen> createState() => _EsewaPaymentScreenState();
}

class _EsewaPaymentScreenState extends ConsumerState<EsewaPaymentScreen>
    with SingleTickerProviderStateMixin {
  final _esewaIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isProcessing = false;
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _esewaIdController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _processPayment() {
    final esewaId = _esewaIdController.text.trim();
    final password = _passwordController.text.trim();

    if (esewaId.isEmpty || password.isEmpty) {
      _showSnack('Please enter eSewa ID and Password', isError: true);
      return;
    }

    if (esewaId != '9800000000' || password != 'Nepal@1234') {
      _showSnack(
        'Invalid eSewa credentials.\nUse: 9800000000 / Nepal@1234',
        isError: true,
      );
      return;
    }

    setState(() => _isProcessing = true);

    final box = Hive.box(HiveBoxes.users);
    final userData = box.get('currentUser');
    final String? userId;
    if (userData is Map) {
      userId = userData['id'] as String?;
    } else {
      userId = box.get('userId');
    }

    if (userId == null) {
      _showSnack('Error: Not logged in', isError: true);
      setState(() => _isProcessing = false);
      return;
    }

    final appointment = Appointment(
      doctorId: widget.doctor.id,
      patientId: userId,
      dateTime: widget.selectedDate,
      startTime: widget.startTime,
      endTime: widget.endTime,
      status: 'pending',
      reason: '${widget.doctor.specialization} consultation',
    );

    ref.read(appointmentNotifierProvider.notifier).bookAppointment(appointment);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).primaryColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fees = widget.doctor.fees;
    final doctorName =
        'Dr. ${widget.doctor.firstName} ${widget.doctor.lastName}';
    final spec = widget.doctor.specialization;
    final dateStr = DateFormat('MMM d, yyyy').format(widget.selectedDate);
    final timeStr =
        '${_formatTime(widget.startTime)} - ${_formatTime(widget.endTime)}';

    ref.listen<AppointmentState>(appointmentNotifierProvider, (previous, next) {
      if (next is AppointmentSuccess) {
        setState(() => _isProcessing = false);
        _showSuccessDialog(theme, isDark, doctorName, dateStr, timeStr);
      } else if (next is AppointmentError) {
        final errorState = next as AppointmentError;
        setState(() => _isProcessing = false);
        _showSnack(errorState.message, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
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
                  border: isDark
                      ? Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        )
                      : null,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: theme.iconTheme.color,
                  size: 18,
                ),
              ),
            ),
            centerTitle: true,
            title: Text(
              'Checkout',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Doctor card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 5),
                            ),
                        ],
                        border: isDark
                            ? Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.1,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isDark
                                  ? theme.scaffoldBackgroundColor
                                  : theme.primaryColor.withValues(alpha: 0.1),
                              image: widget.doctor.image != null
                                  ? DecorationImage(
                                      image: ImageUtils.getImageProvider(
                                        widget.doctor.image,
                                      )!,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: widget.doctor.image == null
                                ? Icon(
                                    Icons.person,
                                    color: isDark
                                        ? Colors.grey.shade700
                                        : theme.primaryColor,
                                    size: 30,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doctorName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  spec,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 13,
                                      color: isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade500,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '$dateStr, $timeStr',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey.shade500
                                            : Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Amount breakdown
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                        ],
                        border: isDark
                            ? Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.1,
                                ),
                              )
                            : null,
                      ),
                      child: Column(
                        children: [
                          _amountRow(
                            theme,
                            isDark,
                            'Consultation Fee',
                            'NPR ${fees.toStringAsFixed(2)}',
                          ),
                          const SizedBox(height: 14),
                          _amountRow(theme, isDark, 'Tax Amount', 'NPR 00.00'),
                          const SizedBox(height: 14),
                          _amountRow(
                            theme,
                            isDark,
                            'Service Charge',
                            'NPR 00.00',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    isDark
                                        ? theme.dividerColor.withValues(
                                            alpha: 0.1,
                                          )
                                        : Colors.grey.shade300,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          _amountRow(
                            theme,
                            isDark,
                            'Total Amount',
                            'NPR ${fees.toStringAsFixed(2)}',
                            isBold: true,
                            highlight: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // eSewa login section
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                        ],
                        border: isDark
                            ? Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.1,
                                ),
                              )
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // eSewa header
                          Row(
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'e',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        color: theme.primaryColor,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Sewa',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: theme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),

                          // eSewa ID field
                          Text(
                            'eSewa Mobile Number',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _esewaIdController,
                            keyboardType: TextInputType.phone,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '98XXXXXXXX',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                              ),
                              prefixIcon: Icon(
                                Icons.phone_android,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? theme.dividerColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? theme.dividerColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Password field
                          Text(
                            'Password',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade400,
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: theme.primaryColor,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: theme.scaffoldBackgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? theme.dividerColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.grey.shade200,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? theme.dividerColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : Colors.grey.shade200,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Pay Now button
                    GestureDetector(
                      onTap: _isProcessing ? null : _processPayment,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: _isProcessing
                                ? [Colors.grey.shade400, Colors.grey.shade500]
                                : [theme.primaryColor, theme.primaryColor],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _isProcessing || isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color: theme.primaryColor.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                        child: Center(
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.payment,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Pay Now',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    const SizedBox(height: 36),
                    const SizedBox(height: 36),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    ThemeData theme,
    bool isDark,
    String label,
    String value, {
    bool isBold = false,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: highlight
                ? theme.textTheme.titleLarge?.color
                : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: highlight
                ? theme.primaryColor
                : theme.textTheme.titleLarge?.color,
          ),
        ),
      ],
    );
  }

  void _showSuccessDialog(
    ThemeData theme,
    bool isDark,
    String doctorName,
    String dateStr,
    String timeStr,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: 56,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Payment Successful!',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Appointment booked with\n$doctorName\n$dateStr at $timeStr',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'View Appointments',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
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
      final ampm = hour >= 12 ? 'pm' : 'am';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:${minute}$ampm';
    } catch (_) {
      return time24;
    }
  }
}
