import 'package:flutter/material.dart';
import 'features/dashboard/presentation/pages/farmer_dashboard_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation Test',
      home: TestLoginPage(),
    );
  }
}

class TestLoginPage extends StatefulWidget {
  @override
  _TestLoginPageState createState() => _TestLoginPageState();
}

class _TestLoginPageState extends State<TestLoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  String message = '';

  Future<void> testNavigation() async {
    print('🚀 TEST NAVIGATION STARTED');
    setState(() {
      isLoading = true;
      message = 'Test ediliyor...';
    });

    await Future.delayed(Duration(seconds: 1));

    setState(() {
      isLoading = false;
      message = 'Navigation test başarılı! Dashboard\'a yönlendiriliyor...';
    });

    await Future.delayed(Duration(milliseconds: 500));

    print('🎯 Navigating to dashboard...');

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const FarmerDashboardPage(),
        ),
      );
      print('✅ Navigation completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Navigation Test')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Email (test only)'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password (test only)'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            isLoading
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: testNavigation,
                  child: Text('Test Navigation'),
                ),
            SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }
}