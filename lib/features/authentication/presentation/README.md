# Authentication Presentation Layer

This document outlines the complete authentication presentation layer implementation for the ZiraAI Flutter mobile app using the BLoC pattern with clean architecture principles.

## Architecture Overview

The authentication presentation layer follows the clean architecture pattern with the following structure:

```
authentication/presentation/
├── bloc/                     # Business Logic Components
│   ├── auth_bloc.dart       # Main BLoC implementation
│   ├── auth_event.dart      # Authentication events
│   └── auth_state.dart      # Authentication states
├── screens/                 # UI Screens
│   ├── login_screen.dart    # Login interface
│   ├── register_screen.dart # Multi-step registration
│   └── forgot_password_screen.dart # Password reset
├── widgets/                 # Reusable UI Components
│   ├── auth_button.dart     # Custom button components
│   ├── auth_text_field.dart # Form input fields
│   ├── auth_loading_overlay.dart # Loading states
│   └── widgets.dart         # Widget exports
├── navigation/              # Routing Configuration
│   └── auth_router.dart     # Authentication routes
├── utils/                   # Utilities & Validators
│   └── auth_validators.dart # Form validation logic
└── presentation.dart        # Barrel export file
```

## Key Features

### 🎯 **BLoC State Management**
- **Events**: Login, Register, Logout, Password Reset, Status Check
- **States**: Loading, Authenticated, Unauthenticated, Failure, Success
- **Error Handling**: Comprehensive error management with user-friendly messages

### 🎨 **UI Components**
- **Responsive Design**: Mobile-first approach with adaptive layouts
- **Accessibility**: WCAG 2.1 AA compliance with screen reader support
- **Turkish Localization**: Primary language support with contextual messaging
- **Material 3**: Modern UI following Material Design principles

### 📱 **Screen Implementations**

#### Login Screen
- Email/password authentication
- Remember me functionality
- Forgot password navigation
- Social login integration (Google)
- Form validation with real-time feedback

#### Register Screen
- Multi-step registration flow (3 steps)
- Personal information collection
- Account type selection (Farmer/Sponsor/Admin)
- Terms and conditions acceptance
- Phone number validation (Turkish format)

#### Forgot Password Screen
- Email-based password reset
- Success confirmation with instructions
- Resend email functionality
- Clear user guidance

### 🔧 **Form Validation**

#### Email Validation
```dart
static String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'E-posta adresi gerekli';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Geçerli bir e-posta adresi girin';
  }
  return null;
}
```

#### Password Strength Validation
- Minimum 6 characters
- Must contain letters and numbers
- Optional strict mode with special characters
- Real-time strength indicator

#### Turkish Phone Validation
```dart
static String? validateTurkishPhone(String? value) {
  final cleanPhone = value.replaceAll(RegExp(r'[^\d]'), '');
  if (cleanPhone.length != 11 || !cleanPhone.startsWith('05')) {
    return 'Geçerli bir cep telefonu numarası girin (05xxxxxxxxx)';
  }
  return null;
}
```

## Usage Examples

### Basic Implementation

```dart
// 1. Setup in main.dart
void main() async {
  await setupServiceLocator();
  runApp(const ZiraAIApp());
}

// 2. BLoC Provider setup
MultiBlocProvider(
  providers: [
    BlocProvider<AuthBloc>(
      create: (context) => GetIt.instance<AuthBloc>()
        ..add(const AuthCheckStatusRequested()),
    ),
  ],
  child: MaterialApp.router(
    routerConfig: AppRouter.router,
  ),
)

// 3. Using in screens
BlocListener<AuthBloc, AuthState>(
  listener: (context, state) {
    if (state is AuthAuthenticated) {
      context.go('/home');
    } else if (state is AuthFailure) {
      _showErrorSnackBar(state.message);
    }
  },
  child: // Your UI here
)
```

### Custom Navigation

```dart
// Using extension methods
context.goToLogin();
context.goToRegister();
context.goToForgotPassword();

// Traditional navigation
context.go('/login');
context.push('/register');
```

### Form Implementation

```dart
AuthTextField(
  label: 'E-posta',
  hint: 'ornek@email.com',
  controller: _emailController,
  keyboardType: TextInputType.emailAddress,
  prefixIcon: const Icon(Icons.email_outlined),
  errorText: _emailError,
  onChanged: (value) {
    if (_emailError != null) {
      setState(() {
        _emailError = AuthValidators.validateEmail(value);
      });
    }
  },
)

LoginButton(
  onPressed: _validateAndLogin,
  isLoading: state is AuthLoading,
)
```

## Accessibility Features

### Screen Reader Support
- Semantic labels for all interactive elements
- Proper focus management
- Descriptive button text
- Form field labeling

### Keyboard Navigation
- Tab order optimization
- Enter key submission
- Escape key handling
- Focus indicators

### Turkish Language Context
```dart
// Error messages in Turkish
'E-posta adresi gerekli'
'Şifre en az 6 karakter olmalı'
'Geçerli bir telefon numarası girin'
```

## State Management Flow

```
User Action → Event → BLoC → State → UI Update

Example Flow:
1. User taps "Giriş Yap" button
2. AuthLoginRequested event fired
3. BLoC processes login logic
4. AuthLoading state emitted
5. UI shows loading indicator
6. Success: AuthAuthenticated state
7. UI navigates to home screen
```

## Testing Considerations

### Unit Tests
- BLoC event/state testing
- Validator function testing
- Form submission logic

### Widget Tests
- Screen rendering tests
- User interaction tests
- Form validation tests

### Integration Tests
- Complete authentication flows
- Navigation testing
- Error scenario handling

## Security Features

### Input Validation
- XSS prevention through validation
- SQL injection prevention
- Phone number normalization
- Email format verification

### Data Protection
- Secure password handling
- No sensitive data logging
- Proper error message sanitization

## Customization

### Theming
```dart
// Custom authentication theme
AuthButton(
  text: 'Custom Button',
  backgroundColor: Colors.customGreen,
  textColor: Colors.white,
  type: AuthButtonType.primary,
)
```

### Validation Rules
```dart
// Custom validation
String? customValidator(String? value) {
  // Your custom logic
  return null;
}
```

## Integration Points

### Domain Layer Integration
```dart
// When domain layer is ready
BlocProvider<AuthBloc>(
  create: (context) => AuthBloc(
    loginUseCase: GetIt.instance<LoginUseCase>(),
    registerUseCase: GetIt.instance<RegisterUseCase>(),
    // ... other use cases
  ),
)
```

### API Integration
```dart
// BLoC will call use cases which call repositories
context.read<AuthBloc>().add(
  AuthLoginRequested(
    email: email,
    password: password,
  ),
);
```

## Performance Optimizations

### Lazy Loading
- BLoC instances created only when needed
- Form controllers disposed properly
- Memory leak prevention

### Widget Optimization
- Const constructors where possible
- Efficient rebuild patterns
- Optimized form validation

## Error Handling

### User-Friendly Messages
```dart
// Network errors
'İnternet bağlantınızı kontrol edin'

// Validation errors
'E-posta formatı geçersiz'

// Server errors
'Sunucu geçici olarak kullanılamıyor'
```

### Recovery Strategies
- Retry mechanisms for network calls
- Form state preservation
- Graceful error recovery

## Development Guidelines

### Code Standards
- Follow Dart/Flutter conventions
- Use meaningful variable names
- Document complex logic
- Maintain consistent formatting

### Git Workflow
- Feature branch development
- Meaningful commit messages
- Code review requirements
- Testing before merge

---

## Quick Start

1. **Setup Dependencies**: Ensure all required packages are in pubspec.yaml
2. **Initialize Service Locator**: Register BLoC and dependencies
3. **Configure Router**: Add authentication routes to app router
4. **Implement Screens**: Use provided screen components
5. **Handle Navigation**: Configure route guards and redirects
6. **Test Flows**: Verify all authentication scenarios

This implementation provides a complete, production-ready authentication presentation layer with Turkish localization, accessibility support, and modern Flutter best practices.