import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import '../../data/services/sponsor_service.dart';
import '../../../../core/security/token_manager.dart';
import '../../../../core/widgets/farmer_bottom_nav.dart';
import 'dart:developer' as developer;

class CreateSponsorProfileScreen extends StatefulWidget {
  const CreateSponsorProfileScreen({super.key});

  @override
  State<CreateSponsorProfileScreen> createState() => _CreateSponsorProfileScreenState();
}

class _CreateSponsorProfileScreenState extends State<CreateSponsorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _businessEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sponsorService = GetIt.instance<SponsorService>();

      developer.log(
        'Creating sponsor profile...',
        name: 'CreateSponsorProfile',
      );

      await sponsorService.createSponsorProfile(
        companyName: _companyNameController.text.trim(),
        businessEmail: _businessEmailController.text.trim(),
        password: _passwordController.text,
      );

      developer.log(
        'Sponsor profile created successfully',
        name: 'CreateSponsorProfile',
      );
      print('✅ CreateSponsorProfile: Sponsor profile created successfully!');

      // Get refresh token and attempt to refresh access token
      final tokenManager = GetIt.instance<TokenManager>();
      final refreshToken = await tokenManager.getRefreshToken();

      if (refreshToken != null) {
        print('🔄 CreateSponsorProfile: Attempting token refresh to get updated roles...');
        
        final refreshSuccess = await _attemptTokenRefresh(refreshToken);
        
        if (refreshSuccess) {
          print('✅ CreateSponsorProfile: Token refresh successful! Navigating to sponsor dashboard...');
          
          if (mounted) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ziraat Firması profili başarıyla oluşturuldu!'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Wait a moment for snackbar
            await Future.delayed(const Duration(milliseconds: 500));

            // Navigate back and trigger sponsor dashboard navigation
            Navigator.of(context).pop(true); // Return true to trigger sponsor dashboard navigation
          }
        } else {
          print('⚠️ CreateSponsorProfile: Token refresh failed, requiring logout/login');
          
          if (mounted) {
            // Show message that logout/login is needed
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ziraat Firması profili oluşturuldu! Lütfen çıkış yapıp tekrar giriş yapın.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );

            await Future.delayed(const Duration(milliseconds: 500));
            Navigator.of(context).pop(false);
          }
        }
      } else {
        print('⚠️ CreateSponsorProfile: No refresh token available');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ziraat Firması profili oluşturuldu! Lütfen çıkış yapıp tekrar giriş yapın.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(false);
        }
      }
    } catch (e) {
      developer.log(
        'Failed to create sponsor profile',
        name: 'CreateSponsorProfile',
        error: e,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Attempt to refresh access token (same logic as splash screen)
  Future<bool> _attemptTokenRefresh(String refreshToken) async {
    try {
      print('🔄 CreateSponsorProfile: Starting token refresh API call...');

      // Use Dio directly for refresh (create new instance to avoid circular dependencies)
      final dio = Dio();

      final response = await dio.post(
        'https://ziraai-api-sit.up.railway.app/api/v1/auth/refresh-token',
        data: {
          'refreshToken': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      print('📡 CreateSponsorProfile: Refresh API response status: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        print('📦 CreateSponsorProfile: Refresh API response data keys: ${data.keys}');

        // Extract new tokens
        String? newAccessToken;
        String? newRefreshToken;

        if (data.containsKey('data')) {
          final tokenData = data['data'] as Map<String, dynamic>;
          newAccessToken = tokenData['token'] ?? tokenData['accessToken'];
          newRefreshToken = tokenData['refreshToken'];
          print('🔑 CreateSponsorProfile: Extracted from data.data - hasToken: ${newAccessToken != null}');
        } else {
          newAccessToken = data['token'] ?? data['accessToken'];
          newRefreshToken = data['refreshToken'];
          print('🔑 CreateSponsorProfile: Extracted from data - hasToken: ${newAccessToken != null}');
        }

        if (newAccessToken != null) {
          print('💾 CreateSponsorProfile: Saving new access token...');
          final tokenManager = GetIt.instance<TokenManager>();
          await tokenManager.saveToken(newAccessToken);

          if (newRefreshToken != null) {
            print('💾 CreateSponsorProfile: Saving new refresh token...');
            await tokenManager.saveRefreshToken(newRefreshToken);
          }

          // Verify roles in new token
          final roles = await tokenManager.getUserRoles();
          print('✅ CreateSponsorProfile: New token roles: $roles');

          return true;
        } else {
          print('⚠️ CreateSponsorProfile: No access token in response!');
        }
      } else {
        print('⚠️ CreateSponsorProfile: Invalid response - status: ${response.statusCode}');
      }

      return false;
    } on DioException catch (e) {
      print('❌ CreateSponsorProfile: Token refresh DioException');
      print('   Status Code: ${e.response?.statusCode}');
      print('   Response Data: ${e.response?.data}');
      print('   Error Message: ${e.message}');
      developer.log(
        'Token refresh error',
        name: 'CreateSponsorProfile',
        error: e,
      );
      return false;
    } catch (e) {
      print('❌ CreateSponsorProfile: Token refresh exception: $e');
      developer.log(
        'Token refresh error',
        name: 'CreateSponsorProfile',
        error: e,
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Ziraat Firması Ol'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Ziraat Firması Profili Oluştur',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ziraat Firması olarak tarım topluluğuna destek olun ve özel özelliklerden yararlanın.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 32),

              // Company Name
              TextFormField(
                controller: _companyNameController,
                decoration: InputDecoration(
                  labelText: 'Şirket Adı *',
                  hintText: 'Örnek: ZiraAI Tarım A.Ş.',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Şirket adı gerekli';
                  }
                  if (value.trim().length < 3) {
                    return 'Şirket adı en az 3 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Business Email
              TextFormField(
                controller: _businessEmailController,
                decoration: InputDecoration(
                  labelText: 'İş E-posta *',
                  hintText: 'ornek@sirket.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'E-posta gerekli';
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Geçerli bir e-posta adresi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Şifre *',
                  hintText: 'E-posta ile giriş için şifre belirleyin',
                  helperText: 'Min 6 karakter',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre gerekli';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalı';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Şifre Tekrar *',
                  hintText: 'Şifrenizi tekrar girin',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Şifre tekrarı gerekli';
                  }
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3B82F6)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Profil oluşturulduktan sonra hem telefon hem de e-posta ile giriş yapabilirsiniz. Ziraat Firması seviyeniz paket satın alma ile belirlenecektir.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Ziraat Firması Profili Oluştur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const FarmerBottomNav(currentIndex: 0), // Ana Sayfa sekmesi
    );
  }
}
