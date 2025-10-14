import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/sponsorship_tier_comparison.dart';
import '../../data/services/sponsor_service.dart';
import 'purchase_success_screen.dart';

/// Order confirmation screen for sponsor package purchase
/// Step 4: Final review and purchase completion
class OrderConfirmationScreen extends StatefulWidget {
  final SponsorshipTierComparison tier;
  final int quantity;
  final double totalAmount;
  final String companyName;
  final String taxNumber;
  final String invoiceAddress;

  const OrderConfirmationScreen({
    super.key,
    required this.tier,
    required this.quantity,
    required this.totalAmount,
    required this.companyName,
    required this.taxNumber,
    required this.invoiceAddress,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  final _sponsorService = GetIt.instance<SponsorService>();
  bool _acceptTerms = false;
  bool _isProcessing = false;

  Future<void> _completePurchase() async {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen şartlar ve koşulları kabul edin'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Call real purchase endpoint
      final result = await _sponsorService.purchasePackage(
        tierId: widget.tier.id,
        quantity: widget.quantity,
        totalAmount: widget.totalAmount,
        paymentMethod: 'CreditCard',
        paymentReference: 'MOCK-${DateTime.now().millisecondsSinceEpoch}',
        companyName: widget.companyName,
        taxNumber: widget.taxNumber,
        invoiceAddress: widget.invoiceAddress,
      );

      if (mounted) {
        // Check if purchase was successful
        if (result['success'] == true) {
          // Navigate to success screen
          await Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => PurchaseSuccessScreen(
                tier: widget.tier,
                quantity: widget.quantity,
                totalAmount: widget.totalAmount,
              ),
            ),
            (route) => route.isFirst, // Keep only the first route (dashboard)
          );

          // Return 'refresh' signal to dashboard
          if (mounted) {
            Navigator.of(context).pop('refresh');
          }
        } else {
          // Handle API error response
          throw Exception(result['message'] ?? 'Sipariş oluşturulamadı');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sipariş oluşturulamadı: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Sipariş Onayı',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Icon and Message
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.shopping_cart_checkout,
                      size: 40,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Siparişinizi Kontrol Edin',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Onaylamadan önce sipariş detaylarını gözden geçirin',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Order Details Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paket Detayları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow(
                    'Paket Tipi',
                    '${widget.tier.tierName} - ${widget.tier.displayName}',
                  ),
                  _buildDetailRow(
                    'Veri Erişimi',
                    '%${widget.tier.sponsorshipFeatures.dataAccessPercentage}',
                  ),
                  _buildDetailRow(
                    'Miktar',
                    '${widget.quantity} paket',
                  ),
                  _buildDetailRow(
                    'Birim Fiyat',
                    '${widget.tier.monthlyPrice.toStringAsFixed(0)} ${widget.tier.currency}',
                  ),

                  const Divider(height: 24),

                  _buildDetailRow(
                    'Ara Toplam',
                    '${widget.totalAmount.toStringAsFixed(0)} ${widget.tier.currency}',
                    isSubtotal: true,
                  ),
                  _buildDetailRow(
                    'KDV (18%)',
                    '${(widget.totalAmount * 0.18).toStringAsFixed(0)} ${widget.tier.currency}',
                    isSubtotal: true,
                  ),

                  const Divider(height: 24, thickness: 2),

                  _buildDetailRow(
                    'GENEL TOPLAM',
                    '${(widget.totalAmount * 1.18).toStringAsFixed(0)} ${widget.tier.currency}',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Invoice Information Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fatura Bilgileri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildInfoTile(
                    Icons.business,
                    'Şirket Adı',
                    widget.companyName,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    Icons.numbers,
                    'Vergi Kimlik No',
                    widget.taxNumber,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
                    Icons.location_on,
                    'Fatura Adresi',
                    widget.invoiceAddress,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // What You Get Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFDEF7EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFF065F46),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Satın Aldıklarınız',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildBenefitItem(
                    '${widget.quantity} adet sponsorluk kodu',
                  ),
                  _buildBenefitItem(
                    '${widget.quantity * widget.tier.dailyRequestLimit} günlük analiz hakkı',
                  ),
                  _buildBenefitItem(
                    '%${widget.tier.sponsorshipFeatures.dataAccessPercentage} çiftçi veri erişimi',
                  ),
                  if (widget.tier.sponsorshipFeatures.communication.messagingEnabled)
                    _buildBenefitItem('Çiftçilerle mesajlaşma'),
                  if (widget.tier.sponsorshipFeatures.smartLinks.enabled)
                    _buildBenefitItem(
                      '${widget.tier.sponsorshipFeatures.smartLinks.quota} akıllı link',
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Terms and Conditions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _acceptTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF10B981),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _acceptTerms = !_acceptTerms;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                            children: [
                              TextSpan(text: 'Okudum, anladım ve '),
                              TextSpan(
                                text: 'Satış Sözleşmesi',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              TextSpan(text: '\'ni kabul ediyorum.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Info Notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF92400E),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Ödeme Bilgisi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Şu anda test modundasınız. Gerçek ödeme işlemi yapılmayacaktır. Kodlarınız anında oluşturulacaktır.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF78350F),
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
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {bool isSubtotal = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal || isSubtotal
                  ? FontWeight.w600
                  : FontWeight.normal,
              color: isTotal ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 24 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? const Color(0xFF10B981) : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 20,
            color: Color(0xFF065F46),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _completePurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Siparişi Tamamla (${(widget.totalAmount * 1.18).toStringAsFixed(0)} ${widget.tier.currency})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
