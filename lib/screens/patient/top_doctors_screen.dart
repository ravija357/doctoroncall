import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_bloc.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_state.dart';
import 'package:doctoroncall/screens/shared/doctor_profile_screen.dart';
import 'package:doctoroncall/core/utils/image_utils.dart';

class TopDoctorsScreen extends StatelessWidget {
  const TopDoctorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
        title: const Text(
          'Top Rated Doctors',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19, color: Color(0xFF1A1D26), letterSpacing: -0.3),
        ),
      ),
      body: BlocBuilder<DoctorBloc, DoctorState>(
        builder: (context, state) {
          if (state is DoctorLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6AA9D8), strokeWidth: 2.5));
          }
          if (state is DoctorError) {
            return Center(child: Text(state.message));
          }
          if (state is DoctorsLoaded) {
            final sorted = List<Doctor>.from(state.doctors)
              ..sort((a, b) => b.averageRating.compareTo(a.averageRating));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: sorted.length,
              itemBuilder: (context, index) => _TopDoctorCard(doctor: sorted[index], rank: index + 1),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _TopDoctorCard extends StatelessWidget {
  final Doctor doctor;
  final int rank;
  const _TopDoctorCard({required this.doctor, required this.rank});

  String get _name {
    final first = doctor.firstName.trim();
    final last = doctor.lastName.trim();
    if (first.isEmpty && last.isEmpty) return 'Doctor';
    return 'Dr. $first $last'.trim();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DoctorProfileScreen(doctor: doctor)));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: rank <= 3 ? Colors.amber.shade100 : const Color(0xFFF0F4F8),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: rank <= 3 ? Colors.amber.shade800 : Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Doctor image
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey.shade100,
              backgroundImage: ImageUtils.getImageProvider(doctor.image),
              child: doctor.image == null ? const Icon(Icons.person, color: Colors.grey, size: 28) : null,
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1D26))),
                  const SizedBox(height: 3),
                  Text(
                    '${doctor.specialization} • ${doctor.experience} yrs',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Rating
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 3),
                    Text(
                      doctor.averageRating.toStringAsFixed(1),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1A1D26)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${doctor.totalReviews} reviews',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
