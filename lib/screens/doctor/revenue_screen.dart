import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctoroncall/features/appointments/presentation/providers/appointment_provider.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/features/doctors/presentation/providers/doctor_provider.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class RevenueScreen extends ConsumerStatefulWidget {
  const RevenueScreen({super.key});

  @override
  ConsumerState<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends ConsumerState<RevenueScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  bool _isUpdatingFee = false;
  final TextEditingController _feeController = TextEditingController();
  List<dynamic> _cachedAppointments = [];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    
    // Wait for the first frame to read bloc and initialize fee
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFeeFromBloc();
    });
  }

  void _syncFeeFromBloc() {
    if (!mounted) return;
    final doctorState = ref.read(doctorNotifierProvider);
    if (doctorState is DoctorsLoaded) {
      final currentUserData = Hive.box(HiveBoxes.users).get('currentUser');
      final currentUserId = currentUserData is Map 
          ? (currentUserData['_id'] ?? currentUserData['id']) 
          : null;
          
      if (currentUserId != null) {
        try {
          final myDoc = (doctorState as DoctorsLoaded).doctors.firstWhere((d) => d.userId == currentUserId);
          if (!_isUpdatingFee) {
            _feeController.text = myDoc.fees.toStringAsFixed(0);
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _updateFee() async {
    final newFee = double.tryParse(_feeController.text);
    if (newFee == null || newFee < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid fee amount')),
      );
      return;
    }

    setState(() => _isUpdatingFee = true);
    
    try {
      final apiClient = sl<ApiClient>();
      
      // We will make a direct API call to update the profile fees
      // sending it to the generic profile update route /doctors/profile
      await apiClient.dio.put('/doctors/profile', data: {'fees': newFee});
      
      // Update local storage so it reflects immediately
      final box = Hive.box(HiveBoxes.users);
      final userData = Map<String, dynamic>.from(box.get('currentUser') as Map? ?? {});
      userData['fees'] = newFee;
      await box.put('currentUser', userData);
      
      if (!mounted) return;
      
      // Trigger a reload of doctors to refresh other screens
      ref.read(doctorNotifierProvider.notifier).loadDoctors();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Consultation fee updated successfully!'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update fee: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingFee = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        centerTitle: true,
        title: Text(
          'Revenue & Earnings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
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
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: () {
            final state = ref.watch(appointmentNotifierProvider);
            if (state is DoctorAppointmentsLoaded) {
              _cachedAppointments = state.appointments;
            }
              
              if (state is AppointmentLoading && _cachedAppointments.isEmpty) {
                return Center(child: CircularProgressIndicator(color: theme.primaryColor));
              }
              
              final appointments = _cachedAppointments;
              final bool isRefreshing = state is AppointmentLoading;
              
              final completed = appointments.where((a) {
                final s = a.status.toLowerCase();
                return s == 'completed' || s == 'confirmed';
              }).toList();
              
              final now = DateTime.now();
              final currentMonthCompleted = completed.where((a) {
                final d = DateTime.tryParse(a.dateTime.toString()) ?? a.dateTime;
                return d.year == now.year && d.month == now.month;
              }).toList();
              
              return () {
                final doctorState = ref.watch(doctorNotifierProvider);
                double fees = 1000.0;
                  final box = Hive.box(HiveBoxes.users);
                  final userData = box.get('currentUser');
                  
                  if (userData is Map) {
                    fees = (userData['fees'] as num?)?.toDouble() ?? 1000.0;
                    final currentUserId = userData['_id'] ?? userData['id'];
                    
                    if (doctorState is DoctorsLoaded && currentUserId != null) {
                      try {
                        final myDoc = (doctorState as DoctorsLoaded).doctors.firstWhere((d) => d.userId == currentUserId);
                        fees = myDoc.fees;
                        if (!_isUpdatingFee && _feeController.text != myDoc.fees.toStringAsFixed(0)) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) _feeController.text = myDoc.fees.toStringAsFixed(0);
                          });
                        }
                      } catch (_) {}
                    }
                  }
                  
                  final totalRevenue = completed.length * fees;
                  final monthlyRevenue = currentMonthCompleted.length * fees;
                  
                  return CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isRefreshing)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: LinearProgressIndicator(
                                    backgroundColor: Colors.transparent,
                                    color: theme.primaryColor,
                                    minHeight: 2,
                                  ),
                                ),
                              _buildRevenueHero(theme, totalRevenue, monthlyRevenue),
                              const SizedBox(height: 24),
                              _buildFeeEditor(theme, isDark, fees),
                              const SizedBox(height: 32),
                              Text(
                                'Recent Transactions',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                      
                      if (completed.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.receipt_long_rounded, size: 60, color: theme.primaryColor.withOpacity(0.5)),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Completed appointments will appear here.',
                                  style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final record = completed[completed.length - 1 - index];
                                return _TransactionCard(record: record, feeAmount: fees);
                              },
                              childCount: completed.length,
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
                    ],
                  );
              }();
            }(),
        ),
      ),
    );
  }

  Widget _buildRevenueHero(ThemeData theme, double total, double monthly) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Total Earnings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.trending_up_rounded, color: Colors.white, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rs. ${total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('This Month', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      'Rs. ${monthly.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
                    ),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text(
                      'Withdraw Now',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeEditor(ThemeData theme, bool isDark, double currentFee) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : null,
        boxShadow: [
          if (!isDark) BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note_rounded, color: theme.primaryColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'Consultation Fee',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? theme.dividerColor.withOpacity(0.2) : Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    decoration: InputDecoration(
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Text('Rs.', style: TextStyle(fontWeight: FontWeight.w700, color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 16)),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _isUpdatingFee ? null : _updateFee,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: _isUpdatingFee
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Update',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
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
}

class _TransactionCard extends StatelessWidget {
  final dynamic record;
  final double feeAmount;
  
  const _TransactionCard({required this.record, required this.feeAmount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateStr = DateFormat('MMM d, y • h:mm a').format(record.dateTime);
    final patientName = record.patientName ?? "Patient";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: theme.dividerColor.withOpacity(0.1)) : null,
        boxShadow: [
          if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+Rs. ${feeAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Completed',
                  style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
