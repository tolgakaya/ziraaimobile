import 'package:flutter/material.dart';
import 'features/dashboard/presentation/pages/farmer_dashboard_page.dart';

void main() {
  runApp(const TestAnalysisFlowApp());
}

class TestAnalysisFlowApp extends StatelessWidget {
  const TestAnalysisFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZiraAI - Analysis Flow Test',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const FarmerDashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}