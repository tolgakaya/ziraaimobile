import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../../../../core/services/sponsorship_sms_listener.dart';
import '../../../data/services/sponsor_service.dart';

/// Farmer-side screen for redeeming sponsorship codes
///
/// Features:
/// - Auto-filled code from SMS or deep link
/// - Real-time code format validation
/// - API integration for redemption
/// - Success/error feedback
/// - Queue status notification
/// - Help section
class SponsorshipRedemptionScreen extends StatefulWidget {
  final String? autoFilledCode;

  const SponsorshipRedemptionScreen({
    Key? key,
    this.autoFilledCode,
  }) : super(key: key);

  @override
  State<SponsorshipRedemptionScreen> createState() =>
      _SponsorshipRedemptionScreenState();
}

class _SponsorshipRedemptionScreenState
    extends State<SponsorshipRedemptionScreen> {
  final TextEditingController _codeController = TextEditingController();
  late final SponsorService _sponsorService;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isCodeValid = false;

  @override
  void initState() {
    super.initState();

    // Initialize service from GetIt
    _sponsorService = GetIt.instance<SponsorService>();

    // Auto-fill code from arguments (deep link or SMS)
    if (widget.autoFilledCode != null && widget.autoFilledCode!.isNotEmpty) {
      _codeController.text = widget.autoFilledCode!;
      _validateCodeFormat(widget.autoFilledCode!);
      print('[SponsorshipRedeem] Code auto-filled: ${widget.autoFilledCode}');
    }

    // Listen for code changes
    _codeController.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    final code = _codeController.text.trim().toUpperCase();
    _validateCodeFormat(code);
  }

  void _validateCodeFormat(String code) {
    // Validate format: AGRI-XXXXX or SPONSOR-XXXXX
    final isValid = RegExp(r'^(AGRI|SPONSOR)-[A-Z0-9]+$').hasMatch(code);

    setState(() {
      _isCodeValid = isValid;
      if (code.isNotEmpty && !isValid) {
        _errorMessage = 'Geçersiz kod formatı';
      } else {
        _errorMessage = null;
      }
    });
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen sponsorluk kodunu girin';
      });
      return;
    }

    if (!_isCodeValid) {
      setState(() {
        _errorMessage = 'Geçersiz kod formatı. Örnek: AGRI-X3K9';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[SponsorshipRedeem] Redeeming code: $code');

      // Call API to redeem code
      final response = await _sponsorService.redeemSponsorshipCode(code);

      if (response['success'] == true) {
        print('[SponsorshipRedeem] ✅ Redemption successful');

        // Clear pending code from storage
        await SponsorshipSmsListener.clearPendingCode();

        // Show success dialog
        _showSuccessDialog(response);
      } else {
        // Show error
        final errorMsg = response['message'] ?? 'Kod kullanılamadı';
        print('[SponsorshipRedeem] ❌ Redemption failed: $errorMsg');

        setState(() {
          _errorMessage = errorMsg;
        });

        _showErrorSnackbar(errorMsg);
      }
    } catch (e) {
      print('[SponsorshipRedeem] ❌ Error: $e');

      setState(() {
        _errorMessage = 'Bağlantı hatası. Lütfen tekrar deneyin.';
      });

      _showErrorSnackbar(
        'Kod kullanılırken bir hata oluştu. Lütfen internet bağlantınızı kontrol edin.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    final data = response['data'] ?? {};
    final tierName = data['tierName'] ?? 'Premium';
    final message = response['message'] ??
        'Sponsorluk aboneliğiniz başarıyla aktive edildi!';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tebrikler!',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.card_giftcard, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Tier: $tierName',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  if (data['dailyLimit'] != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined,
                            color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('Günlük Limit: ${data['dailyLimit']}'),
                      ],
                    ),
                  ],
                  if (data['endDate'] != null) ...[
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bitiş: ${_formatDate(data['endDate'])}',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Premium özelliklere artık erişebilirsiniz!',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close redemption screen
              // Navigate to home/dashboard
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Anasayfaya Dön',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Tamam',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Yardım'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sponsorluk Kodu Nedir?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Tarım şirketleri tarafından gönderilen ücretsiz premium abonelik kodudur.',
              ),
              SizedBox(height: 16),
              Text(
                'Kod Formatı',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• AGRI-XXXXX', style: TextStyle(fontFamily: 'monospace')),
                    Text('• SPONSOR-XXXXX', style: TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Kodu Nasıl Bulabilirim?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                '1. SMS mesajınızı kontrol edin\n'
                '2. Kod otomatik olarak SMS\'den alınır\n'
                '3. Manuel olarak da girebilirsiniz',
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Her kod sadece bir kez kullanılabilir.',
                        style: TextStyle(color: Colors.blue.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Anladım'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sponsorluk Kodu Kullan'),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.green.shade50,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.green.shade200),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sponsorluk Kodu',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Ücretsiz Premium Abonelik',
                                style: TextStyle(
                                  color: Colors.green.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Divider(color: Colors.green.shade200),
                    SizedBox(height: 8),
                    Text(
                      'SMS ile gelen sponsorluk kodunuzu kullanarak ücretsiz premium abonelik kazanın!',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 32),

            // Code input field
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Sponsorluk Kodu',
                hintText: 'AGRI-X3K9',
                prefixIcon: Icon(
                  Icons.qr_code,
                  color: _isCodeValid ? Colors.green : Colors.grey,
                ),
                suffixIcon: _isCodeValid
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _isCodeValid ? Colors.green : Colors.grey.shade300,
                    width: _isCodeValid ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                errorText: _errorMessage,
                filled: true,
                fillColor: Colors.white,
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
              ],
              enabled: !_isLoading,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            SizedBox(height: 24),

            // Redeem button
            ElevatedButton(
              onPressed: _isLoading || !_isCodeValid ? null : _redeemCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isLoading ? 0 : 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.redeem, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Kodu Kullan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: 24),

            // Help button
            Center(
              child: TextButton.icon(
                onPressed: _showHelpDialog,
                icon: Icon(Icons.help_outline, size: 20),
                label: Text('Kodumu nasıl bulabilirim?'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Info section
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Bilgi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Kod SMS ile otomatik gelir\n'
                    '• Her kod sadece bir kez kullanılabilir\n'
                    '• Kodun geçerlilik süresi vardır\n'
                    '• Aktif sponsorluk varsa kod sıraya alınır',
                    style: TextStyle(
                      color: Colors.blue.shade800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }
}
