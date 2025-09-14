import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

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

      setState(() {
        isLoading = false;
        if (response.statusCode == 200) {
          message = 'Login başarılı!';
        }
      });
    } on DioException catch (e) {
      setState(() {
        isLoading = false;
        if (e.response != null) {
          final errorData = e.response!.data;
          print('Error data: $errorData');

          if (errorData is String) {
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