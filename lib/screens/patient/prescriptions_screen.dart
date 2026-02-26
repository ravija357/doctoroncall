import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:intl/intl.dart';

class PrescriptionsScreen extends StatelessWidget {
  const PrescriptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4889A8), Color(0xFFF8FAFC)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_left, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Prescriptions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Records List
              Expanded(
                child: BlocBuilder<AppointmentBloc, AppointmentState>(
                  builder: (context, state) {
                    if (state is AppointmentLoading) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF4889A8)));
                    }
                    if (state is AppointmentsLoaded) {
                      // Filter appointments that might have prescriptions (e.g. completed)
                      final records = state.appointments
                          .where((a) => a.status.toLowerCase() == 'completed')
                          .toList();
                      
                      if (records.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _PrescriptionCard(record: record);
                        },
                      );
                    }
                    return _buildEmptyState();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No prescriptions found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Digital prescriptions from your visits will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final dynamic record;
  const _PrescriptionCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, y').format(record.dateTime);
    
    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.medication_rounded, color: Colors.teal.shade600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prescription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Dr. ${record.doctorName ?? "Specialist"}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Opening prescription PDF...'),
                        backgroundColor: const Color(0xFF4889A8),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text('View PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4889A8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.download_done_rounded, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Prescription saved to downloads'),
                          ],
                        ),
                        backgroundColor: Colors.green.shade600,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.file_download_outlined),
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
