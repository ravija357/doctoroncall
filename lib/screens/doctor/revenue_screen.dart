import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_bloc.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_event.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';

class RevenueScreen extends StatefulWidget {
  const RevenueScreen({super.key});

  @override
  State<RevenueScreen> createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> with SingleTickerProviderStateMixin {
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
    final doctorState = context.read<DoctorBloc>().state;
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
      context.read<DoctorBloc>().add(LoadDoctorsRequested());
      
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Revenue & Earnings',
          style: TextStyle(
            color: Color(0xFF1A1D26),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
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
      ),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: BlocBuilder<AppointmentBloc, AppointmentState>(
            builder: (context, state) {
              if (state is DoctorAppointmentsLoaded) {
                _cachedAppointments = state.appointments;
              }
              
              if (state is AppointmentLoading && _cachedAppointments.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8)));
              }
              
              final appointments = _cachedAppointments;
              final bool isRefreshing = state is AppointmentLoading;
              
              // Only consider completed and confirmed appointments for revenue
              final completed = appointments.where((a) {
                final s = a.status.toLowerCase();
                return s == 'completed' || s == 'confirmed';
              }).toList();
              
              // Calculate current month's revenue vs total
              final now = DateTime.now();
              final currentMonthCompleted = completed.where((a) {
                final d = DateTime.tryParse(a.dateTime.toString()) ?? a.dateTime;
                return d.year == now.year && d.month == now.month;
              }).toList();
              
              return BlocBuilder<DoctorBloc, DoctorState>(
                builder: (context, doctorState) {
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
                        // Update the text field if the fee changed externally
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
                        child:Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                              _buildRevenueHero(totalRevenue, monthlyRevenue),
                              const SizedBox(height: 24),
                              _buildFeeEditor(fees),
                              const SizedBox(height: 32),
                              const Text(
                                'Recent Transactions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A1D26),
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
                                    color: Colors.blue.shade50,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.receipt_long_rounded, size: 60, color: Colors.blue.shade200),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Completed appointments will appear here.',
                                  style: TextStyle(color: Colors.grey.shade500),
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
                                // Show most recent first
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
                }
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueHero(double total, double monthly) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6AA9D8), Color(0xFF4889A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6AA9D8).withOpacity(0.4),
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
              fontSize: 36,
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
                    Text('Completed', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text(
                      'Ready to withdraw',
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

  Widget _buildFeeEditor(double currentFee) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: const Color(0xFFF0F4F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: Color(0xFF6AA9D8), size: 22),
              SizedBox(width: 8),
              Text(
                'Consultation Fee',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1A1D26)),
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
                    color: const Color(0xFFF8FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(14.0),
                        child: Text('Rs.', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey, fontSize: 16)),
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
                    color: const Color(0xFF1A1D26),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF1A1D26).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Center(
                    child: _isUpdatingFee
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            'Save',
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
    final dateStr = DateFormat('MMM d, y • h:mm a').format(record.dateTime);
    final patientName = record.patientName ?? "Patient";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle_rounded, color: Colors.green.shade500, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1A1D26)),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Completed',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
