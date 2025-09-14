# Authentication Domain Layer - Clean Architecture

This directory contains the complete authentication domain layer for the ZiraAI Flutter mobile app, built following Clean Architecture principles.

## Overview

The authentication domain layer is responsible for:
- User authentication (login/logout)
- User registration with role-based access (Farmer/Sponsor)
- JWT token management and refresh
- Password management (change/reset)
- Session validation and state management
- Email and phone verification
- Role-based permissions

## Architecture

Follows Clean Architecture with clear separation of concerns:

```
domain/
├── entities/          # Core business objects
├── value_objects/     # Domain value objects with validation
├── repositories/      # Repository interfaces (contracts)
├── usecases/         # Business logic use cases
├── failures/         # Domain-specific error handling
└── state/            # State management contracts
```

## Entities

### User Entity
- **File**: `entities/user.dart`
- **Purpose**: Core user representation supporting Farmer and Sponsor roles
- **Key Features**:
  - Role-based properties and permissions
  - Email validation integration
  - Immutable with copyWith pattern
  - Equality comparison support

### AuthTokens Entity
- **File**: `entities/auth_tokens.dart`
- **Purpose**: JWT token management with expiration tracking
- **Key Features**:
  - Automatic expiration checking
  - Authorization header generation
  - Refresh requirement detection

### AuthSession Entity
- **File**: `entities/auth_session.dart`
- **Purpose**: Complete authentication session combining user and tokens
- **Key Features**:
  - Session validity checking
  - Device tracking support
  - Metadata storage capability

## Value Objects

### Email Value Object
- **File**: `value_objects/email.dart`
- **Purpose**: Email validation and normalization
- **Features**:
  - RFC 5322 compliant validation
  - Automatic normalization (lowercase, trim)
  - Domain extraction utilities
  - Privacy-conscious masking

### Password Value Object
- **File**: `value_objects/password.dart`
- **Purpose**: Password security and validation
- **Features**:
  - Comprehensive strength validation
  - Security requirement enforcement
  - Pattern detection (sequential/repeating chars)
  - Strength scoring (0-100)

### UserRole Enum
- **File**: `value_objects/user_role.dart`
- **Purpose**: Role-based access control
- **Roles**:
  - **Farmer**: Agricultural professionals using plant analysis
  - **Sponsor**: Companies providing sponsored services
  - **Admin**: System administrators
- **Features**:
  - Permission level hierarchy
  - Role-specific capability checks
  - Assignment validation

### PhoneNumber Value Object
- **File**: `value_objects/phone_number.dart`
- **Purpose**: Phone number validation with Turkish market focus
- **Features**:
  - Turkish (+90) format primary support
  - International format support
  - Automatic normalization
  - Mobile/landline detection

## Repository Interface

### AuthRepository
- **File**: `repositories/auth_repository.dart`
- **Purpose**: Defines authentication data access contract
- **Key Methods**:
  - Authentication: login, register, logout
  - Token Management: refresh, validate, store
  - Profile Management: update, password change
  - Verification: email, phone, 2FA
  - Session Management: validation, cleanup
  - Security: permissions, audit logging

## Use Cases

### Core Authentication

#### LoginUser
- **File**: `usecases/login_user.dart`
- **Purpose**: User authentication with credentials
- **Validation**: Email format, password presence
- **Features**: Remember me, device tracking, activity logging

#### RegisterUser
- **File**: `usecases/register_user.dart`
- **Purpose**: New user account creation
- **Validation**: Email, password strength, name format, role permissions
- **Features**: Automatic token storage, email verification trigger

#### LogoutUser
- **File**: `usecases/logout_user.dart`
- **Purpose**: Secure user logout with cleanup
- **Features**: Single/multi-device logout, graceful failure handling

### Token Management

#### RefreshToken
- **File**: `usecases/refresh_token.dart`
- **Purpose**: Automatic token renewal
- **Features**: Storage integration, failure recovery, activity tracking

#### ValidateSession
- **File**: `usecases/validate_session.dart`
- **Purpose**: Comprehensive session validation
- **Features**: Auto-refresh, server validation, session reconstruction

### User Management

#### GetCurrentUser
- **File**: `usecases/get_current_user.dart`
- **Purpose**: Retrieve authenticated user information
- **Features**: Session validation, account status checking

#### ChangePassword
- **File**: `usecases/change_password.dart`
- **Purpose**: Secure password updates
- **Validation**: Current password verification, strength requirements

### Password Recovery

#### RequestPasswordReset & ConfirmPasswordReset
- **File**: `usecases/reset_password.dart`
- **Purpose**: Password recovery workflow
- **Features**: Email-based reset, token validation, strength enforcement

## Error Handling

### Core Failures
- **Location**: `../../../../core/errors/failures.dart`
- **Pattern**: Either<Failure, Success> for all operations
- **Types**: Server, Network, Authentication, Validation, etc.

### Domain-Specific Failures
- **File**: `failures/auth_failures.dart`
- **Purpose**: Authentication-specific error handling
- **Examples**:
  - InvalidCredentialsFailure
  - AccountLockedFailure
  - TokenExpiredFailure
  - InsufficientPermissionsFailure
  - RateLimitExceededFailure

## State Management

### AuthState
- **File**: `state/auth_state.dart`
- **Purpose**: Comprehensive authentication state representation
- **States**:
  - Initial, Loading, Authenticated, Unauthenticated
  - Failure, Refreshing, SessionExpired
  - Registration, Verification states
- **Features**: State checking extensions, convenience getters

### AuthEvents
- **File**: `state/auth_events.dart`
- **Purpose**: All authentication actions/events
- **Categories**:
  - Authentication: Login, Register, Logout
  - Session: Validate, Refresh, Expire
  - Profile: Update, Password Change
  - Verification: Email, Phone, 2FA

## Integration with ZiraAI Backend

### JWT Authentication
- Bearer token format: `Authorization: Bearer <token>`
- Automatic token refresh before expiration
- Secure token storage using platform keychain

### Role-Based Features
- **Farmer Role**: Plant analysis access, subscription management
- **Sponsor Role**: Company profiles, tier-based features, analytics
- **Admin Role**: Full system administration

### API Endpoints Integration
- Base URL: `https://api.ziraai.com/api/v1`
- Authentication endpoints: `/auth/login`, `/auth/register`
- Profile management: `/auth/profile`, `/auth/change-password`
- Verification: `/auth/verify-email`, `/auth/verify-phone`

## Security Features

### Password Security
- Minimum 8 characters with complexity requirements
- Uppercase, lowercase, numbers, special characters
- Sequential and repeating character detection
- Strength scoring and visual feedback

### Token Security
- JWT with expiration tracking
- Automatic refresh 5 minutes before expiry
- Secure storage using platform-specific mechanisms
- Token validation with server when required

### Session Security
- Device tracking and metadata
- Activity timestamp updates
- Graceful session expiration handling
- Multi-device logout support

## Usage Examples

### Basic Login
```dart
final loginUseCase = LoginUser(authRepository);
final result = await loginUseCase(
  LoginUserParams(
    email: 'farmer@example.com',
    password: 'SecurePass123!',
    rememberMe: true,
  ),
);

result.fold(
  (failure) => print('Login failed: ${failure.message}'),
  (session) => print('Welcome ${session.user.fullName}!'),
);
```

### Session Validation
```dart
final validateUseCase = ValidateSession(authRepository, refreshTokenUseCase, getCurrentUserUseCase);
final result = await validateUseCase(ValidateSessionParams.standard());

result.fold(
  (failure) => navigateToLogin(),
  (session) => proceedWithAuthenticatedFlow(),
);
```

### Password Strength Validation
```dart
try {
  final password = Password('MySecurePassword123!');
  print('Password strength: ${password.strength.displayName}');
  print('Is secure: ${password.isSecure}');
} on ArgumentError catch (e) {
  print('Password validation failed: ${e.message}');
}
```

## Dependencies

### Required Packages
- `dartz`: Functional programming (Either pattern)
- `equatable`: Value equality comparison
- `flutter_secure_storage`: Secure token storage
- `flutter_bloc`: State management (for presentation layer)

### Internal Dependencies
- Core error handling: `../../../../core/errors/failures.dart`
- Use case interfaces: `../../../../core/usecases/usecase.dart`
- Secure storage: `../../../../core/storage/secure_storage.dart`

## Testing Considerations

### Unit Testing
- All value objects have validation test cases
- Use cases include success and failure scenarios
- Entity equality and copyWith operations
- State transitions and event handling

### Mock Objects
- Repository interface allows easy mocking
- Use case parameters are value objects (testable)
- Failure objects are comparable for test assertions

## Future Enhancements

### Planned Features
- Biometric authentication integration
- Social login providers (Google, Apple)
- Advanced 2FA with authenticator apps
- Advanced session management and analytics

### Scalability Considerations
- Repository pattern allows easy data source switching
- Value objects ensure consistent validation
- Use cases enable feature composition
- State management supports complex UI flows

This domain layer provides a robust, secure, and scalable foundation for authentication in the ZiraAI mobile application, following Clean Architecture principles and supporting the Turkish agricultural market's specific requirements.