import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/features/auth/domain/repositories/auth_repository.dart';
import 'package:doctoroncall/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:doctoroncall/features/doctors/domain/repositories/doctor_repository.dart';
import 'package:doctoroncall/features/doctors/data/datasources/doctor_remote_data_source.dart';
import 'package:doctoroncall/features/doctors/data/datasources/doctor_local_data_source.dart';
import 'package:doctoroncall/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:doctoroncall/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:doctoroncall/features/appointments/data/datasources/appointment_local_data_source.dart';
import 'package:doctoroncall/features/notifications/domain/repositories/notification_repository.dart';
import 'package:doctoroncall/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:doctoroncall/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:dio/dio.dart';

@GenerateMocks([
  ApiClient,
  FlutterSecureStorage,
  Box,
  AuthRepository,
  AuthRemoteDataSource,
  DoctorRepository,
  DoctorRemoteDataSource,
  DoctorLocalDataSource,
  AppointmentRepository,
  AppointmentRemoteDataSource,
  AppointmentLocalDataSource,
  NotificationRepository,
  NotificationRemoteDataSource,
  NotificationLocalDataSource,
  ChatRepository,
  ChatRemoteDataSource,
  Dio,
])
void main() {}
