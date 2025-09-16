import 'package:flutter/material.dart';
import '../../models/subscription_tier.dart';
import '../../services/mock_payment_service.dart';
import 'result_screen.dart';

class ConfirmationScreen extends StatefulWidget {
  final SubscriptionTier tier;
  final String cardNumber;
  final String cardHolder;
  final double totalAmount;
  
  const ConfirmationScreen({
    super.key,
    required this.tier,
    required this.cardNumber,
    required this.cardHolder,
    required this.totalAmount,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  bool _termsAccepted = false;
  bool _isProcessing = false;
  
  String get _maskedCardNumber {
    final cleaned = widget.cardNumber.replaceAll(' ', '');
    if (cleaned.length < 12) return widget.cardNumber;
    
    final last4 = cleaned.substring(cleaned.length - 4);
    return '**** **** **** $last4';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sipariş Onayı'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Order Summary Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.shopping_cart_checkout,
                          size: 48,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Sipariş Özeti',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Plan Details
                  _buildSectionTitle('Abonelik Detayları'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Plan:', widget.tier.name),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'Günlük Limit:',
                            '${widget.tier.dailyAnalysisLimit} analiz',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'Aylık Limit:',
                            '${widget.tier.monthlyAnalysisLimit} analiz',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow('Süre:', '1 Ay'),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'Otomatik Yenileme:',
                            'Aktif',
                            valueColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Payment Details
                  _buildSectionTitle('Ödeme Bilgileri'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow('Kart:', _maskedCardNumber),
                          const Divider(height: 16),
                          _buildDetailRow('Kart Sahibi:', widget.cardHolder),
                          const Divider(height: 16),
                          _buildDetailRow('Ödeme Tipi:', '3D Secure'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Price Breakdown
                  _buildSectionTitle('Fiyat Detayı'),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Ara Toplam:',
                            '₺${widget.tier.price.toStringAsFixed(2)}',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'KDV (%20):',
                            '₺${(widget.tier.price * 0.20).toStringAsFixed(2)}',
                          ),
                          const Divider(height: 16),
                          _buildDetailRow(
                            'TOPLAM:',
                            '₺${widget.totalAmount.toStringAsFixed(2)}',
                            keyStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            valueStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Terms and Conditions
                  CheckboxListTile(
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _termsAccepted = value ?? false;
                      });
                    },
                    title: const Text(
                      'Kullanım koşullarını ve gizlilik politikasını okudum, kabul ediyorum',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  
                  // Info Messages
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Önemli Bilgiler:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '• Aboneliğiniz otomatik olarak yenilenecektir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              Text(
                                '• İstediğiniz zaman iptal edebilirsiniz',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                              Text(
                                '• Faturanız e-posta ile gönderilecektir',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: (_termsAccepted && !_isProcessing) 
                          ? _confirmPayment 
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isProcessing
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Onaylanıyor...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Ödemeyi Onayla',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(
    String key, 
    String value, {
    TextStyle? keyStyle,
    TextStyle? valueStyle,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: keyStyle ?? TextStyle(color: Colors.grey.shade700),
        ),
        Text(
          value,
          style: valueStyle ?? TextStyle(
            fontWeight: FontWeight.w500,
            color: valueColor,
          ),
        ),
      ],
    );
  }
  
  Future<void> _confirmPayment() async {
    setState(() => _isProcessing = true);
    
    // Process payment with mock service
    final result = await MockPaymentService.processPayment(
      cardNumber: widget.cardNumber,
      cardHolder: widget.cardHolder,
      expiryDate: '12/25', // Mock expiry
      cvv: '123', // Mock CVV
      amount: widget.totalAmount,
      currency: 'TRY',
      tierId: widget.tier.id,
    );
    
    if (!mounted) return;
    
    // Navigate to result screen
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          isSuccess: result.success,
          message: result.message,
          transactionId: result.transactionId,
          invoiceUrl: result.invoiceUrl,
          tier: widget.tier,
          amount: widget.totalAmount,
        ),
      ),
    );
    
    if (mounted) {
      setState(() => _isProcessing = false);
      
      if (success == true) {
        // Close all payment screens and return to dashboard
        Navigator.pop(context, true);
      }
    }
  }
}