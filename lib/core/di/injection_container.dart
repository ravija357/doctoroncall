import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import 'package:doctoroncall/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:doctoroncall/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:doctoroncall/features/auth/domain/repositories/auth_repository.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:doctoroncall/core/network/api_client.dart';

import 'package:doctoroncall/features/call/call_service.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_local_data_source.dart';
import 'package:doctoroncall/features/messages/data/repositories/chat_repository_impl.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_bloc.dart';

import 'package:doctoroncall/features/doctors/data/datasources/doctor_remote_data_source.dart';
import 'package:doctoroncall/features/doctors/data/datasources/doctor_local_data_source.dart';
import 'package:doctoroncall/features/doctors/data/repositories/doctor_repository_impl.dart';
import 'package:doctoroncall/features/doctors/domain/repositories/doctor_repository.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_bloc.dart';

import 'package:doctoroncall/features/appointments/data/datasources/appointment_remote_data_source.dart';
import 'package:doctoroncall/features/appointments/data/datasources/appointment_local_data_source.dart';
import 'package:doctoroncall/features/appointments/data/repositories/appointment_repository_impl.dart';
import 'package:doctoroncall/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';

import 'package:doctoroncall/features/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:doctoroncall/features/notifications/data/datasources/notification_local_data_source.dart';
import 'package:doctoroncall/features/notifications/data/repositories/notification_repository_impl.dart';
import 'package:doctoroncall/features/notifications/domain/repositories/notification_repository.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ---- Core ----
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => ApiClient(dio: sl(), secureStorage: sl()));

  // ---- Local Data Sources (Hive) ----
  sl.registerLazySingleton(() => AppointmentLocalDataSource());
  sl.registerLazySingleton(() => DoctorLocalDataSource());
  sl.registerLazySingleton(() => NotificationLocalDataSource());
  sl.registerLazySingleton(() => ChatLocalDataSource());

  // ---- Features ----
  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(remoteDataSource: sl()));
  sl.registerFactory(() => AuthBloc(authRepository: sl()));

  // Doctors
  sl.registerLazySingleton<DoctorRemoteDataSource>(
      () => DoctorRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<DoctorRepository>(
      () => DoctorRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()));
  sl.registerFactory(() => DoctorBloc(doctorRepository: sl()));

  // Appointments
  sl.registerLazySingleton<AppointmentRemoteDataSource>(
      () => AppointmentRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<AppointmentRepository>(
      () => AppointmentRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()));
  sl.registerFactory(() => AppointmentBloc(repository: sl()));

  // Notifications
  sl.registerLazySingleton<NotificationRemoteDataSource>(
      () => NotificationRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<NotificationRepository>(
      () => NotificationRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()));
  sl.registerFactory(() => NotificationBloc(repository: sl(), chatRemoteDataSource: sl()));

  // Messages
  sl.registerLazySingleton<ChatRemoteDataSource>(
      () => ChatRemoteDataSourceImpl(apiClient: sl()));
  sl.registerLazySingleton<ChatRepository>(
      () => ChatRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()));
  sl.registerFactory(() => ChatBloc(chatRepository: sl()));

  // Call
  sl.registerFactory(() => CallService(dataSource: sl<ChatRemoteDataSource>()));
}
