import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/subscription_tier.dart';

class ResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final String? transactionId;
  final String? invoiceUrl;
  final SubscriptionTier? tier;
  final double? amount;
  
  const ResultScreen({
    super.key,
    required this.isSuccess,
    required this.message,
    this.transactionId,
    this.invoiceUrl,
    this.tier,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success/Error Animation
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isSuccess ? Colors.green : Colors.red)
                            .withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    size: 80,
                    color: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                Text(
                  isSuccess ? 'Ödeme Başarılı!' : 'Ödeme Başarısız',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Details Card
                if (isSuccess && tier != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailItem(
                          icon: Icons.shopping_bag,
                          label: 'Satın Alınan Plan',
                          value: tier!.name,
                        ),
                        const Divider(height: 24),
                        _buildDetailItem(
                          icon: Icons.receipt,
                          label: 'Ödenen Tutar',
                          value: '₺${amount?.toStringAsFixed(2)}',
                        ),
                        if (transactionId != null) ...[
                          const Divider(height: 24),
                          _buildDetailItem(
                            icon: Icons.confirmation_number,
                            label: 'İşlem No',
                            value: transactionId!,
                            isCopiable: true,
                            context: context,
                          ),
                        ],
                        const Divider(height: 24),
                        _buildDetailItem(
                          icon: Icons.calendar_today,
                          label: 'Başlangıç Tarihi',
                          value: _formatDate(DateTime.now()),
                        ),
                        const Divider(height: 24),
                        _buildDetailItem(
                          icon: Icons.event,
                          label: 'Bitiş Tarihi',
                          value: _formatDate(
                            DateTime.now().add(const Duration(days: 30)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Invoice Button
                  if (invoiceUrl != null)
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fatura e-postanıza gönderildi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Faturayı İndir'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue.shade700,
                      ),
                    ),
                ],
                
                // Error Details
                if (!isSuccess) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.red.shade600,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Lütfen kart bilgilerinizi kontrol edip tekrar deneyiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sorun devam ederse müşteri hizmetleri ile iletişime geçebilirsiniz.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Action Buttons
                Row(
                  children: [
                    if (!isSuccess)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.red.shade400),
                          ),
                          child: Text(
                            'Tekrar Dene',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ),
                    if (!isSuccess) const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (isSuccess) {
                            // Navigate back to dashboard (root screen)
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          } else {
                            // Just close the result screen
                            Navigator.pop(context, false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isSuccess 
                              ? Colors.green.shade600 
                              : Colors.grey.shade600,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isSuccess ? 'Dashboard\'a Dön' : 'Kapat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    bool isCopiable = false,
    BuildContext? context,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isCopiable && context != null)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kopyalandı'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}