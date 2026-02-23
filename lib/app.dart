import 'dart:async';
import 'package:doctoroncall/features/call/incoming_call_overlay.dart';
import 'package:doctoroncall/features/messages/data/datasources/chat_remote_data_source.dart';
import 'package:doctoroncall/core/network/api_client.dart';
import 'package:doctoroncall/screens/auth/role_selection_screen.dart';
import 'package:doctoroncall/screens/patient/patient_main_screen.dart';
import 'package:doctoroncall/screens/doctor/doctor_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:doctoroncall/theme_data/theme_data.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_state.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:doctoroncall/features/messages/presentation/bloc/chat_bloc.dart';
import 'package:doctoroncall/features/doctors/presentation/bloc/doctor_bloc.dart';
import 'package:doctoroncall/features/appointments/presentation/bloc/appointment_bloc.dart';
import 'package:doctoroncall/features/notifications/presentation/bloc/notification_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
        BlocProvider<ChatBloc>(create: (_) => sl<ChatBloc>()),
        BlocProvider<DoctorBloc>(create: (_) => sl<DoctorBloc>()),
        BlocProvider<AppointmentBloc>(create: (_) => sl<AppointmentBloc>()),
        BlocProvider<NotificationBloc>(create: (_) => sl<NotificationBloc>()),
      ],
      child: MaterialApp(
        title: 'doctoroncall',
        debugShowCheckedModeBanner: false,
        theme: getApplicationTheme(),
        home: const _IncomingCallWrapper(),
      ),
    );
  }
}

/// Wraps the main content and listens for incoming call events globally.
class _IncomingCallWrapper extends StatefulWidget {
  const _IncomingCallWrapper();

  @override
  State<_IncomingCallWrapper> createState() => _IncomingCallWrapperState();
}

class _IncomingCallWrapperState extends State<_IncomingCallWrapper> {
  StreamSubscription? _incomingCallSub;

  @override
  void initState() {
    super.initState();
    // Start listening for incoming calls once socket may connect
    WidgetsBinding.instance.addPostFrameCallback((_) => _listenForIncomingCalls());
  }

  void _listenForIncomingCalls() {
    final dataSource = sl<ChatRemoteDataSource>();
    _incomingCallSub = dataSource.incomingCallStream.listen((data) async {
      if (!mounted) return;
      // Get local user id for answering
      final apiClient = sl<ApiClient>();
      final localUserId = await apiClient.secureStorage.read(key: 'user_id') ?? '';

      if (!mounted) return;
      final signal = data['signal'] as Map<String, dynamic>?;
      final from = data['from']?.toString() ?? '';
      final name = data['name']?.toString() ?? 'Unknown';
      final callType = data['callType']?.toString() ?? 'audio';
      final isVideo = callType == 'video';

      if (signal == null || from.isEmpty) return;

      await showIncomingCallDialog(
        context,
        callerName: name,
        callerId: from,
        localUserId: localUserId,
        offer: signal,
        isVideo: isVideo,
      );
    });
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return state.user.role == 'DOCTOR'
              ? const DoctorMainScreen()
              : const PatientMainScreen();
        }
        return const RoleSelectionScreen();
      },
    );
  }
}
