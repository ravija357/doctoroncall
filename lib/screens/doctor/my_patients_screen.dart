import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_state.dart';
import 'package:doctoroncall/features/appointments/domain/entities/appointment.dart';
import 'package:doctoroncall/screens/doctor/patient_detail_screen.dart';
import 'package:intl/intl.dart';

class MyPatientsScreen extends StatelessWidget {
  const MyPatientsScreen({super.key});

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
                      'My Patients',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Patient List
              Expanded(
                child: BlocBuilder<AppointmentBloc, AppointmentState>(
                  builder: (context, state) {
                    if (state is AppointmentLoading) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF4889A8)));
                    }
                    if (state is DoctorAppointmentsLoaded) {
                      final patients = _groupPatients(state.appointments);
                      
                      if (patients.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: patients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final patient = patients[index];
                          return _PatientCard(
                            patient: patient,
                            onTap: () => _showPatientHistory(context, patient, state.appointments),
                          );
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

  List<_PatientSummary> _groupPatients(List<Appointment> appointments) {
    final Map<String, _PatientSummary> patientMap = {};

    for (var app in appointments) {
      final pid = app.patientId;
      if (!patientMap.containsKey(pid)) {
        patientMap[pid] = _PatientSummary(
          id: pid,
          name: app.patientName ?? 'Unknown Patient',
          totalVisits: 1,
          lastVisit: app.dateTime,
        );
      } else {
        final existing = patientMap[pid]!;
        patientMap[pid] = _PatientSummary(
          id: pid,
          name: existing.name,
          totalVisits: existing.totalVisits + 1,
          lastVisit: app.dateTime.isAfter(existing.lastVisit) ? app.dateTime : existing.lastVisit,
        );
      }
    }

    return patientMap.values.toList()
      ..sort((a, b) => b.lastVisit.compareTo(a.lastVisit));
  }

  void _showPatientHistory(BuildContext context, _PatientSummary patient, List<Appointment> allAppointments) {
    final history = allAppointments.where((a) => a.patientId == patient.id).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientDetailScreen(
          patientId: patient.id,
          patientName: patient.name,
          totalVisits: patient.totalVisits,
          history: history,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No patients rostered',
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
              'Confirm patient requests to see them in your roster.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientSummary {
  final String id;
  final String name;
  final int totalVisits;
  final DateTime lastVisit;

  _PatientSummary({
    required this.id,
    required this.name,
    required this.totalVisits,
    required this.lastVisit,
  });
}

class _PatientCard extends StatelessWidget {
  final _PatientSummary patient;
  final VoidCallback onTap;

  const _PatientCard({required this.patient, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF6AA9D8).withOpacity(0.15),
              child: Text(
                patient.name.isNotEmpty ? patient.name[0].toUpperCase() : 'P',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4889A8), fontSize: 20),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    patient.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D26),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Last visit: ${DateFormat('MMM d, y').format(patient.lastVisit)}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4889A8),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF4889A8).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '${patient.totalVisits}',
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, height: 1),
                  ),
                  const Text(
                    'Visits',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Replaced Bottom Sheet with Dedicated Detail Screen
