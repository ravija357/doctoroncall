import 'package:flutter/material.dart';
import 'package:doctoroncall/screens/patient/book_appointment_screen.dart';
import 'package:doctoroncall/screens/shared/chat_screen.dart';
import 'package:doctoroncall/features/doctors/domain/entities/doctor.dart';

class DoctorProfileScreen extends StatelessWidget {
  final Doctor doctor;
  
  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Profile',
          style: TextStyle(fontFamily: 'PlayfairDisplay'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: doctor.image != null ? NetworkImage(doctor.image!) : null,
              child: doctor.image == null ? const Icon(Icons.person, size: 50) : null,
            ),
            const SizedBox(height: 16),
            Text(
              'Dr. ${doctor.firstName} ${doctor.lastName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${doctor.specialization} - ${doctor.experience} Yrs Experience',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              doctor.bio,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 14,
              ),
            ),
             const SizedBox(height: 16),
            Text(
              'Fees: \$${doctor.fees}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6AA9D8),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      otherUserId: doctor.userId, // Sending to the DOCTOR'S User ID
                      otherUserName: 'Dr. ${doctor.firstName} ${doctor.lastName}',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Chat with Doctor'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookAppointmentScreen(doctor: doctor),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Book Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6AA9D8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
