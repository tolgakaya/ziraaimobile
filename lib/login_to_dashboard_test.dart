import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'features/dashboard/presentation/pages/farmer_dashboard_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiraAI Login',
      home: LoginPage(),
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
    print('🚀 LOGIN FUNCTION STARTED - VERSION 3.0');
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
      print('Response data type: ${response.data.runtimeType}');
      print('Response data: ${response.data}');
      print('Response data as string: ${response.data.toString()}');

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;

        // API'den gelen response yapısını kontrol et
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
          print('🔄 Refresh Token alındı');

          // Token'ı kaydet (SharedPreferences kullanılabilir)
          // TODO: Token'ı secure storage'a kaydet

          setState(() {
            isLoading = false;
            message = 'Login başarılı! Dashboard\'a yönlendiriliyor...';
          });

          print('🔄 Success message set, waiting 500ms...');
          await Future.delayed(Duration(milliseconds: 500));

          print('⏰ Delay tamamlandı, mounted kontrol ediliyor...');
          print('📱 Mounted durumu: $mounted');

          if (mounted) {
            print('🎯 Navigation başlatılıyor...');
            try {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const FarmerDashboardPage(),
                ),
              );
              print('✅ Navigation komutu çalıştırıldı');
            } catch (e) {
              print('❌ Navigation hatası: $e');
              setState(() {
                message = 'Navigation hatası: $e';
              });
            }
          } else {
            print('❌ Widget mounted değil, navigation yapılamıyor');
            setState(() {
              message = 'Navigation hatası: Widget disposed';
            });
          }
        } else {
          // API response success false
          setState(() {
            isLoading = false;
            message = responseData['message'] ?? 'Login başarısız';
          });
          print('❌ Login başarısız: ${responseData['message']}');
        }
      } else {
        setState(() {
          isLoading = false;
          message = 'Login başarısız - Geçersiz response';
        });
      }
    } on DioException catch (e) {
      setState(() {
        isLoading = false;
        if (e.response != null) {
          final errorData = e.response!.data;
          print('Error response: $errorData');

          if (errorData is Map<String, dynamic>) {
            // Structured error response
            final errorMessage = errorData['message'] ?? 'Bilinmeyen hata';
            message = errorMessage;
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
      appBar: AppBar(title: Text('ZiraAI Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: login,
                  child: Text('Login'),
                ),
            SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
}