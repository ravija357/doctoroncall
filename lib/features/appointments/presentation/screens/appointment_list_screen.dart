import 'package:flutter/material.dart';
import 'package:doctoroncall/features/appointments/presentation/screens/book_appointment_screen.dart';

class AppointmentListScreen extends StatelessWidget {
  const AppointmentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BookAppointmentScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: 0, // TODO: Fetch from state
        itemBuilder: (context, index) {
          return const ListTile(
            title: Text('Appointment'),
          );
        },
      ),
    );
  }
}
