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
    // Phone OTP authentication
    on<PhoneLoginOtpRequested>(_onPhoneLoginOtpRequested);
    on<PhoneLoginOtpVerifyRequested>(_onPhoneLoginOtpVerifyRequested);
    on<PhoneRegisterOtpRequested>(_onPhoneRegisterOtpRequested);
    on<PhoneRegisterOtpVerifyRequested>(_onPhoneRegisterOtpVerifyRequested);
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

  // Phone OTP Authentication Handlers

  Future<void> _onPhoneLoginOtpRequested(
    PhoneLoginOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.requestPhoneLoginOtp(
      mobilePhone: event.mobilePhone,
    );

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message ?? 'Failed to send OTP'));
      },
      (otpCode) {
        // OTP sent successfully via real SMS service
        // No OTP code in response (always 'OTP_SENT')
        emit(PhoneOtpSent(
          mobilePhone: event.mobilePhone,
          otpCode: null,
          isRegistration: false,
        ));
      },
    );
  }

  Future<void> _onPhoneLoginOtpVerifyRequested(
    PhoneLoginOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🔷 AuthBloc: PhoneLoginOtpVerifyRequested received');
    print('🔷 AuthBloc: mobilePhone: ${event.mobilePhone}, code: ${event.code}');

    emit(const AuthLoading());
    print('🔷 AuthBloc: State changed to AuthLoading');

    print('🔷 AuthBloc: Calling verifyPhoneLoginOtp...');
    final result = await _authRepository.verifyPhoneLoginOtp(
      mobilePhone: event.mobilePhone,
      code: event.code,
    );
    print('🔷 AuthBloc: verifyPhoneLoginOtp completed');

    result.fold(
      (failure) {
        print('❌ AuthBloc: OTP verification failed: ${failure.message}');
        emit(AuthError(message: failure.message ?? 'OTP verification failed'));
      },
      (user) {
        print('✅ AuthBloc: OTP verification successful, user: ${user.phoneNumber}');
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  Future<void> _onPhoneRegisterOtpRequested(
    PhoneRegisterOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.requestPhoneRegisterOtp(
      mobilePhone: event.mobilePhone,
      referralCode: event.referralCode,
    );

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message ?? 'Failed to send OTP'));
      },
      (otpCode) {
        // OTP sent successfully via real SMS service
        // No OTP code in response (always 'OTP_SENT')
        emit(PhoneOtpSent(
          mobilePhone: event.mobilePhone,
          otpCode: null,
          isRegistration: true,
        ));
      },
    );
  }

  Future<void> _onPhoneRegisterOtpVerifyRequested(
    PhoneRegisterOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    final result = await _authRepository.verifyPhoneRegisterOtp(
      mobilePhone: event.mobilePhone,
      code: event.code,
      referralCode: event.referralCode,
    );

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message ?? 'Registration OTP verification failed'));
      },
      (user) {
        emit(AuthAuthenticated(user: user));
      },
    );
  }
}