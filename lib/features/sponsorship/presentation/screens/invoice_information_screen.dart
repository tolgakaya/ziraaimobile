import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/sponsorship_tier_comparison.dart';
import '../../data/services/sponsor_service.dart';
import 'order_confirmation_screen.dart';

/// Invoice information screen for sponsor package purchase
/// Step 3: User enters/confirms invoice details
class InvoiceInformationScreen extends StatefulWidget {
  final SponsorshipTierComparison tier;
  final int quantity;
  final double totalAmount;

  const InvoiceInformationScreen({
    super.key,
    required this.tier,
    required this.quantity,
    required this.totalAmount,
  });

  @override
  State<InvoiceInformationScreen> createState() =>
      _InvoiceInformationScreenState();
}

class _InvoiceInformationScreenState extends State<InvoiceInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sponsorService = GetIt.instance<SponsorService>();

  final _companyNameController = TextEditingController();
  final _taxNumberController = TextEditingController();
  final _invoiceAddressController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSponsorProfile();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _taxNumberController.dispose();
    _invoiceAddressController.dispose();
    super.dispose();
  }

  Future<void> _loadSponsorProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _sponsorService.getSponsorProfile();

      if (mounted) {
        setState(() {
          // Pre-fill from SponsorProfile if available
          final data = profile['data'] as Map<String, dynamic>?;
          if (data != null) {
            _companyNameController.text = data['companyName'] ?? '';
            _taxNumberController.text = data['taxNumber'] ?? '';
            _invoiceAddressController.text = data['address'] ?? '';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Profil bilgileri yüklenemedi: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      // Navigate to order confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(
            tier: widget.tier,
            quantity: widget.quantity,
            totalAmount: widget.totalAmount,
            companyName: _companyNameController.text.trim(),
            taxNumber: _taxNumberController.text.trim(),
            invoiceAddress: _invoiceAddressController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Fatura Bilgileri',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order Summary Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.tier.tierName} Paketi',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${widget.quantity} adet × ${widget.tier.monthlyPrice.toStringAsFixed(0)} ${widget.tier.currency}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${widget.totalAmount.toStringAsFixed(0)} ${widget.tier.currency}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Instructions
                    const Text(
                      'Fatura Bilgileriniz',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Fatura için gerekli bilgileri girin. Bilgiler profilinizden otomatik olarak yüklenmiştir.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning,
                              color: Color(0xFFEF4444),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Form Fields Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        children: [
                          // Company Name
                          TextFormField(
                            controller: _companyNameController,
                            decoration: InputDecoration(
                              labelText: 'Şirket Adı *',
                              hintText: 'Örn: ABC Tarım Ltd. Şti.',
                              prefixIcon: const Icon(
                                Icons.business,
                                color: Color(0xFF10B981),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Şirket adı gereklidir';
                              }
                              if (value.trim().length < 3) {
                                return 'Şirket adı en az 3 karakter olmalıdır';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Tax Number
                          TextFormField(
                            controller: _taxNumberController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Vergi Kimlik No *',
                              hintText: '10 haneli vergi numarası',
                              prefixIcon: const Icon(
                                Icons.numbers,
                                color: Color(0xFF10B981),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vergi kimlik numarası gereklidir';
                              }
                              if (value.trim().length != 10) {
                                return 'Vergi kimlik numarası 10 haneli olmalıdır';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Invoice Address
                          TextFormField(
                            controller: _invoiceAddressController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Fatura Adresi *',
                              hintText: 'Tam fatura adresinizi girin',
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(bottom: 50),
                                child: Icon(
                                  Icons.location_on,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E7EB),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF10B981),
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Fatura adresi gereklidir';
                              }
                              if (value.trim().length < 10) {
                                return 'Lütfen tam adresi girin';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Info Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDEF7EC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Fatura Bilgisi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Fatura bilgileri profilinize kaydedilecektir. Bir sonraki alışverişinizde otomatik olarak yüklenecektir.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF047857),
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
      bottomNavigationBar: _buildBottomBar(),
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
          onPressed: _isLoading ? null : _continue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Siparişi Onayla',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
