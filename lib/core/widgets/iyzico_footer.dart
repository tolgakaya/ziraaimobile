import 'package:flutter/material.dart';

/// Iyzico payment provider logo footer widget
/// Displays payment method logos (Mastercard, Visa, American Express, Troy)
/// Used in subscription and payment screens
class IyzicoFooter extends StatelessWidget {
  final EdgeInsetsGeometry? padding;
  final double? height;

  const IyzicoFooter({
    super.key,
    this.padding,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Center(
        child: Image.asset(
          'assets/images/payment/iyzico_logo_band.png',
          height: height ?? 24,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
