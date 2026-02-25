import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:doctoroncall/app.dart';
import 'package:doctoroncall/core/constants/hive_boxes.dart';
import 'package:doctoroncall/core/di/injection_container.dart';

// Hive TypeAdapters (auto-generated via build_runner)
import 'package:doctoroncall/features/auth/data/models/user_model.dart';
import 'package:doctoroncall/features/messages/data/models/chat_contact_model.dart';

// Hive TypeAdapters (manually-written standalone adapters)
import 'package:doctoroncall/features/appointments/data/models/appointment_model_adapter.dart';
import 'package:doctoroncall/features/doctors/data/models/doctor_model_adapter.dart';
import 'package:doctoroncall/features/notifications/data/models/notification_model_adapter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();

  // Initialize Hive
  await Hive.initFlutter();

  // Register TypeAdapters
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(AppointmentModelAdapter());
  Hive.registerAdapter(DoctorModelAdapter());
  Hive.registerAdapter(NotificationModelAdapter());
  Hive.registerAdapter(ChatContactAdapter());

  // Open all boxes
  await Hive.openBox(HiveBoxes.users);
  await Hive.openBox(HiveBoxes.appointments);
  await Hive.openBox(HiveBoxes.doctors);
  await Hive.openBox(HiveBoxes.notifications);
  await Hive.openBox(HiveBoxes.chatContacts);

  runApp(const App());
}
