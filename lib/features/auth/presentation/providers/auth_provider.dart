import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/user_model.dart';
import 'package:doctoroncall/core/di/injection_container.dart';
import 'package:doctoroncall/features/auth/presentation/bloc/auth_state.dart';
import 'package:doctoroncall/features/messages/domain/repositories/chat_repository.dart';
import 'dart:async';

part 'auth_provider.g.dart';

@riverpod
class Auth extends _$Auth {
  late final AuthRepository _authRepository;
  late final ChatRepository _chatRepository;
  StreamSubscription? _syncSubscription;

  @override
  AuthState build() {
    _authRepository = sl<AuthRepository>();
    _chatRepository = sl<ChatRepository>();

    _syncSubscription = _chatRepository.doctorSyncStream().listen((_) {
      syncProfile();
    });

    ref.onDispose(() {
      _syncSubscription?.cancel();
    });

    // We can't return a Future from build in a synchronous Notifier,
    // but the original AuthBloc started with AuthInitial and then checked status.
    // However, Riverpod build is the initial state.
    // We'll use AuthInitial and trigger a check.
    return AuthInitial();
  }

  Future<void> checkAuthStatus() async {
    state = AuthLoading();
    try {
      final cachedUser = await _authRepository.getCachedUser();
      if (cachedUser != null) {
        state = AuthAuthenticated(user: cachedUser);
      } else {
        state = AuthUnauthenticated();
      }
    } catch (e) {
      state = AuthUnauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      final user = await _authRepository.login(email, password);
      state = AuthAuthenticated(user: user);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> googleLogin(String idToken) async {
    state = AuthLoading();
    try {
      final user = await _authRepository.googleLogin(idToken);
      state = AuthAuthenticated(user: user);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> signup(
    String firstName,
    String lastName,
    String email,
    String password,
    String role,
  ) async {
    state = AuthLoading();
    try {
      final userModel = UserModel(
        firstName: firstName,
        lastName: lastName,
        email: email,
        role: role,
      );
      await _authRepository.signUp(userModel, password);
      final loggedInUser = await _authRepository.login(email, password);
      state = AuthAuthenticated(user: loggedInUser);
    } catch (e) {
      state = AuthError(message: e.toString());
    }
  }

  Future<void> logout() async {
    state = AuthLoading();
    await _authRepository.logout();
    state = AuthUnauthenticated();
  }

  Future<void> syncProfile() async {
    try {
      final user = await _authRepository.getProfile();
      if (state is AuthAuthenticated) {
        state = AuthAuthenticated(user: user);
      }
    } catch (e) {
      // Removed sync error print
    }
  }
}
