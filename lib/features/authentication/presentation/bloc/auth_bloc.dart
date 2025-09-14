import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

@injectable
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthCheckStatusRequested>(_onCheckStatusRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.login(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message ?? 'Login failed'));
      },
      (user) {
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.register(
      firstName: event.firstName,
      lastName: event.lastName,
      email: event.email,
      password: event.password,
      confirmPassword: event.confirmPassword,
      phoneNumber: event.phoneNumber,
    );

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message ?? 'Registration failed'));
      },
      (user) {
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.logout();

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message ?? 'Logout failed'));
      },
      (_) {
        emit(const AuthInitial());
      },
    );
  }

  Future<void> _onCheckStatusRequested(
    AuthCheckStatusRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await _authRepository.isLoggedIn();

    result.fold(
      (failure) {
        emit(const AuthInitial());
      },
      (isLoggedIn) async {
        if (isLoggedIn) {
          final userResult = await _authRepository.getCurrentUser();
          userResult.fold(
            (failure) {
              emit(const AuthInitial());
            },
            (user) {
              emit(AuthAuthenticated(user: user));
            },
          );
        } else {
          emit(const AuthInitial());
        }
      },
    );
  }
}