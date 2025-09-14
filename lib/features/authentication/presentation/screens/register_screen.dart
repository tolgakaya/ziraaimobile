import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../dashboard/presentation/pages/farmer_dashboard_page.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _countryCodeController = TextEditingController(text: '+1');
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  bool _isPhoneVerified = false;
  
  String? _fullNameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateAndRegister() {
    setState(() {
      _fullNameError = _validateFullName(_fullNameController.text);
      _emailError = _validateEmail(_emailController.text);
      _phoneError = _validatePhone(_phoneController.text);
      _passwordError = _validatePassword(_passwordController.text);
      _confirmPasswordError = _validateConfirmPassword(
        _passwordController.text, 
        _confirmPasswordController.text
      );
    });

    if (_fullNameError == null && 
        _emailError == null && 
        _phoneError == null &&
        _passwordError == null && 
        _confirmPasswordError == null &&
        _agreeToTerms) {
      
      // Parse firstName and lastName from full name
      List<String> nameParts = _fullNameController.text.trim().split(' ');
      String firstName = nameParts.first;
      String lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
      
      context.read<AuthBloc>().add(
        AuthRegisterRequested(
          firstName: firstName,
          lastName: lastName,
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmPasswordController.text,
          phoneNumber: '${_countryCodeController.text.trim()}${_phoneController.text.trim()}',
        ),
      );
    } else if (!_agreeToTerms) {
      _showErrorSnackBar('Please accept Terms & Conditions');
    }
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 7) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Please confirm your password';
    }
    if (password != confirmPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  double _getPasswordStrength() {
    String password = _passwordController.text;
    if (password.isEmpty) return 0.0;
    
    double strength = 0.0;
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.2;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.2;
    
    return strength;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _verifyPhone() {
    if (_phoneController.text.isNotEmpty) {
      // TODO: Implement phone verification
      setState(() {
        _isPhoneVerified = true;
      });
      _showErrorSnackBar('Phone verification not yet implemented');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Navigate to dashboard on successful registration and login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const FarmerDashboardPage(),
            ),
          );
        } else if (state is AuthError) {
          _showErrorSnackBar(state.message);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header with back button
              _buildHeader(),
              
              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildForm(),
                ),
              ),
              
              // Fixed footer with register button
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: const Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),
          
          // Centered title
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 40), // Compensate for back button
                child: Text(
                  'Create Account',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          
          // Full Name Field
          _buildFormField(
            label: 'Full Name',
            controller: _fullNameController,
            placeholder: 'Enter your full name',
            errorText: _fullNameError,
            onChanged: (value) {
              if (_fullNameError != null) {
                setState(() {
                  _fullNameError = _validateFullName(value);
                });
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email Field
          _buildFormField(
            label: 'Email',
            controller: _emailController,
            placeholder: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: (value) {
              if (_emailError != null) {
                setState(() {
                  _emailError = _validateEmail(value);
                });
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Phone Number Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Country Code
              Expanded(
                flex: 1,
                child: _buildFormField(
                  label: 'Code',
                  controller: _countryCodeController,
                  placeholder: '+1',
                  keyboardType: TextInputType.phone,
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Phone Number
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phone Number',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4F0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          hintStyle: const TextStyle(
                            color: Color(0xFF638863),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          errorText: _phoneError,
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(8),
                            child: TextButton(
                              onPressed: _verifyPhone,
                              style: TextButton.styleFrom(
                                backgroundColor: _isPhoneVerified 
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.transparent,
                                minimumSize: const Size(60, 32),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                              ),
                              child: Text(
                                _isPhoneVerified ? 'Verified' : 'Verify',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _isPhoneVerified 
                                      ? Colors.green 
                                      : const Color(0xFF17CF17),
                                ),
                              ),
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          if (_phoneError != null) {
                            setState(() {
                              _phoneError = _validatePhone(value);
                            });
                          }
                          if (_isPhoneVerified) {
                            setState(() {
                              _isPhoneVerified = false;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Password Field with Strength Indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordField(
                label: 'Password',
                controller: _passwordController,
                placeholder: 'Enter your password',
                obscureText: _obscurePassword,
                errorText: _passwordError,
                onToggleVisibility: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                onChanged: (value) {
                  if (_passwordError != null) {
                    setState(() {
                      _passwordError = _validatePassword(value);
                    });
                  }
                  setState(() {}); // Refresh strength indicator
                },
              ),
              
              // Password Strength Indicator
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _getPasswordStrength(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF17CF17),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Confirm Password Field
          _buildPasswordField(
            label: 'Confirm Password',
            controller: _confirmPasswordController,
            placeholder: 'Confirm your password',
            obscureText: _obscureConfirmPassword,
            errorText: _confirmPasswordError,
            onToggleVisibility: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
            onChanged: (value) {
              if (_confirmPasswordError != null) {
                setState(() {
                  _confirmPasswordError = _validateConfirmPassword(
                    _passwordController.text, 
                    value
                  );
                });
              }
            },
          ),
          
          const SizedBox(height: 24),
          
          // Terms and Conditions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: Checkbox(
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() {
                      _agreeToTerms = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF17CF17),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _agreeToTerms = !_agreeToTerms;
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF638863),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(text: 'By registering, you agree to our '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: const TextStyle(
                            color: Color(0xFF17CF17),
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TODO: Show terms and conditions
                              _showErrorSnackBar('Terms & Conditions not implemented');
                            },
                        ),
                        const TextSpan(text: '. A trial subscription will be created automatically.'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF638863),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorText: errorText,
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required bool obscureText,
    String? errorText,
    required VoidCallback onToggleVisibility,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: const TextStyle(
                color: Color(0xFF638863),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              errorText: errorText,
              suffixIcon: IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF638863),
                  size: 20,
                ),
              ),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Register Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              
              return Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF17CF17),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF17CF17).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(25),
                    onTap: isLoading ? null : _validateAndRegister,
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Login Link
          Center(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF638863),
                ),
                children: [
                  const TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Login',
                    style: const TextStyle(
                      color: Color(0xFF17CF17),
                      fontWeight: FontWeight.w700,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.of(context).pop();
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}