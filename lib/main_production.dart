import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'features/dashboard/presentation/pages/farmer_dashboard_page.dart';

void main() {
  runApp(ZiraAIApp());
}

class ZiraAIApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiraAI',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String message = '';

  Future<void> login() async {
    print('🚀 ZiraAI Production Login Started');
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final dio = Dio();
      final response = await dio.post(
        'https://ziraai-api-sit.up.railway.app/api/v1/authentication/login',
        data: {
          'email': emailController.text,
          'password': passwordController.text,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          final loginData = responseData['data'];
          final token = loginData['token'];
          final claims = loginData['claims'];
          final expiration = loginData['expiration'];
          final refreshToken = loginData['refreshToken'];

          print('✅ Login başarılı!');
          print('🔑 Token alındı: ${token.substring(0, 20)}...');
          print('🏷️ Claims: $claims');
          print('⏰ Expiration: $expiration');

          setState(() {
            isLoading = false;
            message = 'Giriş başarılı! Dashboard yükleniyor...';
          });

          await Future.delayed(Duration(milliseconds: 800));

          if (mounted) {
            print('🎯 Dashboard\'a yönlendiriliyor...');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const FarmerDashboardPage(),
              ),
            );
            print('✅ Dashboard yüklendi');
          }
        } else {
          setState(() {
            isLoading = false;
            message = responseData['message'] ?? 'Giriş başarısız';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          message = 'Sunucu hatası';
        });
      }
    } on DioException catch (e) {
      setState(() {
        isLoading = false;
        if (e.response != null) {
          final errorData = e.response!.data;
          print('Error response: $errorData');

          if (errorData is Map<String, dynamic>) {
            message = errorData['message'] ?? 'Bilinmeyen hata';
          } else if (errorData is String) {
            if (errorData == 'PasswordError') {
              message = 'Şifre hatalı';
            } else if (errorData == 'UserNotFound') {
              message = 'Kullanıcı bulunamadı';
            } else {
              message = 'Hata: $errorData';
            }
          } else {
            message = 'API hatası: ${e.response!.statusCode}';
          }
        } else {
          message = 'Bağlantı hatası: ${e.message}';
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        message = 'Bilinmeyen hata: $e';
      });
      print('❌ Unexpected error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ve başlık
              Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.agriculture,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'ZiraAI',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tarımsal Analiz Platformu',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 48),

              // Email input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Password input
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock_outlined),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Login button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Giriş yapılıyor...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Giriş Yap',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // Status message
              if (message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: message.contains('başarılı') || message.contains('yükleniyor')
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: message.contains('başarılı') || message.contains('yükleniyor')
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              const SizedBox(height: 32),

              // Footer
              const Text(
                'AI destekli bitki analizi ile tarımsal verimliliğinizi artırın',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}