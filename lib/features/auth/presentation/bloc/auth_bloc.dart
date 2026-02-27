import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:doctoroncall/core/error/server_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'dart:async';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final ChatRepository chatRepository;
  StreamSubscription? _syncSubscription;

  AuthBloc({
    required this.authRepository,
    required this.chatRepository,
  }) : super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<SignupRequested>(_onSignupRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<SyncProfileRequested>(_onSyncProfileRequested);

    _syncSubscription = chatRepository.doctorSyncStream().listen((_) {
      print('[AUTH] Profile Sync Signal Received');
      add(SyncProfileRequested());
    });
  }

  @override
  Future<void> close() {
    _syncSubscription?.cancel();
    return super.close();
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final cachedUser = await authRepository.getCachedUser();
      if (cachedUser != null) {
        emit(AuthAuthenticated(user: cachedUser));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user: user));
    } on ServerException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred.'));
    }
  }

  Future<void> _onSignupRequested(
    SignupRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final userModel = UserModel(
        firstName: event.firstName,
        lastName: event.lastName,
        email: event.email,
        role: event.role,
      );
      await authRepository.signUp(userModel, event.password);
      
      // Auto-login after signup
      final loggedInUser = await authRepository.login(event.email, event.password);
      emit(AuthAuthenticated(user: loggedInUser));
      
    } on ServerException catch (e) {
      emit(AuthError(message: e.message));
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred.'));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    await authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onSyncProfileRequested(
    SyncProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      final user = await authRepository.getProfile();
      if (state is AuthAuthenticated) {
        emit(AuthAuthenticated(user: user));
      }
    } catch (e) {
      print('[AUTH] Sync Profile Error: $e');
    }
  }
}
