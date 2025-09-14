import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';
import '../value_objects/email.dart';
import '../value_objects/password.dart';
import '../value_objects/phone_number.dart';
import '../value_objects/user_role.dart';

/// Use case for user registration with validation.
/// Creates new user account and returns authentication session.
class RegisterUser implements UseCase<AuthSession, RegisterUserParams> {
  final AuthRepository repository;

  const RegisterUser(this.repository);

  @override
  Future<Either<Failure, AuthSession>> call(RegisterUserParams params) async {
    try {
      // Validate email format
      final email = Email(params.email);
      
      // Validate password strength
      final password = Password(params.password);
      
      // Validate phone number if provided
      PhoneNumber? phoneNumber;
      if (params.phoneNumber != null && params.phoneNumber!.isNotEmpty) {
        phoneNumber = PhoneNumber(params.phoneNumber!);
      }
      
      // Validate name fields
      if (params.firstName.trim().isEmpty) {
        return Left(ValidationFailure('First name cannot be empty'));
      }
      
      if (params.lastName.trim().isEmpty) {
        return Left(ValidationFailure('Last name cannot be empty'));
      }
      
      if (params.firstName.trim().length < 2) {
        return Left(ValidationFailure('First name must be at least 2 characters'));
      }
      
      if (params.lastName.trim().length < 2) {
        return Left(ValidationFailure('Last name must be at least 2 characters'));
      }
      
      // Parse user role
      final userRole = UserRole.values.firstWhere(
        (role) => role.name.toLowerCase() == params.role.toLowerCase(),
        orElse: () => UserRole.farmer,
      );
      
      // Perform registration
      final result = await repository.register(
        email: email,
        password: password,
        firstName: params.firstName.trim(),
        lastName: params.lastName.trim(),
        role: userRole,
        phoneNumber: phoneNumber,
        deviceId: params.deviceId,
        metadata: params.metadata,
      );
      
      return result.fold(
        (failure) => Left(failure),
        (session) async {
          // Store tokens if registration successful
          await repository.storeTokens(session.tokens);
          
          return Right(session);
        },
      );
    } on ArgumentError catch (e) {
      return Left(ValidationFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure('Registration failed: ${e.toString()}'));
    }
  }
}

/// Parameters for the RegisterUser use case
class RegisterUserParams extends Equatable {
  final String email;
  final String password;
  final String firstName;
  final String lastName;
  final String role;
  final String? phoneNumber;
  final String? deviceId;
  final Map<String, dynamic>? metadata;

  const RegisterUserParams({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.phoneNumber,
    this.deviceId,
    this.metadata,
  });

  @override
  List<Object?> get props => [
        email,
        password,
        firstName,
        lastName,
        role,
        phoneNumber,
        deviceId,
        metadata,
      ];

  @override
  String toString() {
    return 'RegisterUserParams(email: $email, firstName: $firstName, lastName: $lastName, role: $role)';
  }
}