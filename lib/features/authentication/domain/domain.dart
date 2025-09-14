// Authentication Domain Layer Exports
// This file provides a single import point for all domain layer components

// Entities
export 'entities/user.dart';
export 'entities/auth_tokens.dart';
export 'entities/auth_session.dart';

// Value Objects
export 'value_objects/email.dart';
export 'value_objects/password.dart';
export 'value_objects/user_role.dart';
export 'value_objects/phone_number.dart';

// Repository Interface
export 'repositories/auth_repository.dart';

// Use Cases
export 'usecases/login_user.dart';
export 'usecases/register_user.dart';
export 'usecases/logout_user.dart';
export 'usecases/refresh_token.dart';
export 'usecases/get_current_user.dart';
export 'usecases/validate_session.dart';
export 'usecases/change_password.dart';
export 'usecases/reset_password.dart';

// Domain-Specific Failures
export 'failures/auth_failures.dart';

// State Management
export 'state/auth_state.dart';
// Note: auth_events.dart is excluded due to naming conflict with auth_state.dart

// Core Dependencies (re-exported for convenience)
export '../../../../core/errors/failures.dart';
export '../../../../core/usecases/usecase.dart';