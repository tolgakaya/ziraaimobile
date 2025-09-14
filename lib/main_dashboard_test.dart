import 'package:flutter/material.dart';
import 'features/dashboard/presentation/pages/farmer_dashboard_page.dart';

void main() {
  runApp(const DashboardTestApp());
}

class DashboardTestApp extends StatelessWidget {
  const DashboardTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiraAI Dashboard Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const FarmerDashboardPage(),
    );
  }
}