import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/di/injection.dart';
import '../../data/dealer_api_service.dart';
import '../../domain/models/dealer_invitation_details.dart';
import '../../domain/models/dealer_invitation_accept_response.dart';
import '../widgets/package_tier_badge.dart';

/// Dealer invitation screen
/// Shows invitation details and allows dealer to accept invitation
///
/// Features:
/// - Auto-filled token from SMS or deep link
/// - Display invitation details (sponsor info, code count, tier)
/// - Accept/Reject invitation
/// - Email verification requirement display
/// - Manual token input option
///
/// API Integration:
/// - GET /api/v1/sponsorship/dealer/invitation-details?token={token}
/// - POST /api/v1/sponsorship/dealer/accept-invitation
class DealerInvitationScreen extends StatefulWidget {
  final String? token; // Optional auto-filled token from SMS/deep link

  const DealerInvitationScreen({
    Key? key,
    this.token,
  }) : super(key: key);

  @override
  State<DealerInvitationScreen> createState() => _DealerInvitationScreenState();
}

class _DealerInvitationScreenState extends State<DealerInvitationScreen> {
  final TextEditingController _tokenController = TextEditingController();
  late final DealerApiService _dealerApiService;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isTokenValid = false;
  bool _invitationFetched = false;

  // Invitation details from API
  DealerInvitationDetails? _invitationDetails;

  @override
  void initState() {
    super.initState();

    // Initialize API service
    _dealerApiService = getIt<DealerApiService>();

    // Auto-fill token from arguments (deep link or SMS)
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenController.text = widget.token!;
      _validateTokenFormat(widget.token!);
      print('[DealerInvitation] Token auto-filled: ${widget.token}');

      // Auto-fetch invitation details
      _fetchInvitationDetails();
    }

    // Listen for token changes
    _tokenController.addListener(_onTokenChanged);
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  void _onTokenChanged() {
    final token = _tokenController.text.trim().toLowerCase();
    _validateTokenFormat(token);
  }

  void _validateTokenFormat(String token) {
    // Validate format: 32-character hexadecimal (lowercase)
    final isValid = RegExp(r'^[a-f0-9]{32}$', caseSensitive: false).hasMatch(token);

    setState(() {
      _isTokenValid = isValid;
      if (token.isNotEmpty && !isValid) {
        _errorMessage = 'Geçersiz token formatı (32 karakter hexadecimal bekleniyor)';
      } else {
        _errorMessage = null;
      }
    });
  }

  Future<void> _fetchInvitationDetails() async {
    final token = _tokenController.text.trim().toLowerCase();

    if (token.isEmpty) {
      setState(() {
        _errorMessage = 'Lütfen davetiye tokenını girin';
      });
      return;
    }

    if (!_isTokenValid) {
      setState(() {
        _errorMessage = 'Geçersiz token formatı';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[DealerInvitation] Fetching invitation details for token: $token');

      // Real API call
      final details = await _dealerApiService.getInvitationDetails(token);

      setState(() {
        _invitationDetails = details;
        _invitationFetched = true;
        _isLoading = false;
      });

      print('[DealerInvitation] Invitation details fetched successfully');
      print('[DealerInvitation] Sponsor: ${details.sponsorCompanyName}, Codes: ${details.codeCount}, Tier: ${details.packageTier}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Davetiye bilgileri alınamadı: ${_getErrorMessage(e)}';
        _isLoading = false;
      });
      print('[DealerInvitation] Error fetching invitation details: $e');
    }
  }

  String _getErrorMessage(dynamic error) {
    // Enhanced v2.0 error handling - extract backend message first
    if (error is DioException) {
      // Priority 1: Extract backend error message from response
      if (error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map<String, dynamic> && data['message'] != null) {
          return data['message'].toString();
        }
      }

      // Priority 2: Status code based fallbacks (if no backend message)
      switch (error.response?.statusCode) {
        case 400:
          return 'Davetiye bulunamadı veya süresi dolmuş';
        case 410:
          return 'Bu davetiye zaten kabul edilmiş';
        case 404:
          return 'Davetiye kaydı bulunamadı';
        case 401:
          return 'Yetkilendirme hatası. Lütfen giriş yapın';
        case 500:
          return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin';
      }
    }

    // Priority 3: Generic error strings
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('socket')) {
      return 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin';
    } else if (errorString.contains('timeout')) {
      return 'Zaman aşımı. Lütfen tekrar deneyin';
    }

    return 'Bir hata oluştu. Lütfen tekrar deneyin';
  }

  Future<void> _acceptInvitation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = _tokenController.text.trim().toLowerCase();
      print('[DealerInvitation] Accepting invitation with token: $token');

      // Real API call
      final response = await _dealerApiService.acceptInvitation(token);

      setState(() {
        _isLoading = false;
      });

      // Show success dialog with API response data (v2.0 fields)
      if (mounted) {
        _showSuccessDialog(
          codeCount: response.codesTransferred,
          packageTier: response.packageTier,
          codeIds: response.transferredCodeIds,
          dealerName: response.dealerName,
        );
      }

      print('[DealerInvitation] Invitation accepted successfully');
      print('[DealerInvitation] Codes transferred: ${response.codesTransferred}, Tier: ${response.packageTier}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Davetiye kabul edilemedi: ${_getErrorMessage(e)}';
        _isLoading = false;
      });
      print('[DealerInvitation] Error accepting invitation: $e');
    }
  }

  void _showSuccessDialog({
    required int codeCount,
    String? packageTier,
    List<int>? codeIds,
    String? dealerName,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Başarılı!'),
          ],
        ),
        content: Text(
          'Davetiye başarıyla kabul edildi.\n$codeCount adet kod hesabınıza transfer edildi.',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Go back to pending invitations screen with refresh signal
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(int days) {
    if (days <= 1) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.green;
  }

  /// Check if invitation can be accepted based on status
  bool _canAcceptInvitation() {
    if (_invitationDetails == null) return false;
    final status = _invitationDetails!.status?.toLowerCase();
    return status == 'pending' || status == null;
  }

  /// Get status display info (icon, color, message)
  Map<String, dynamic> _getStatusInfo() {
    final status = _invitationDetails?.status?.toLowerCase() ?? 'pending';
    
    switch (status) {
      case 'accepted':
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'title': 'Davetiye Kabul Edilmiş',
          'message': 'Bu davetiye daha önce kabul edilmiş. Yeni bir davetiye denemek için token alanını temizleyin.',
        };
      case 'expired':
        return {
          'icon': Icons.access_time,
          'color': Colors.orange,
          'title': 'Davetiye Süresi Dolmuş',
          'message': 'Bu davetiyenin süresi dolmuş. Lütfen sponsor ile iletişime geçin.',
        };
      case 'rejected':
        return {
          'icon': Icons.cancel,
          'color': Colors.red,
          'title': 'Davetiye Reddedilmiş',
          'message': 'Bu davetiye daha önce reddedilmiş.',
        };
      case 'pending':
      default:
        return {
          'icon': Icons.pending,
          'color': Colors.blue,
          'title': 'Davetiye Bekliyor',
          'message': 'Bu davetiye kabul edilmeyi bekliyor.',
        };
    }
  }

  /// Clear token and reset state for new invitation
  void _clearTokenAndRetry() {
    setState(() {
      _tokenController.clear();
      _invitationDetails = null;
      _invitationFetched = false;
      _errorMessage = null;
      _isTokenValid = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ücretsiz Abonelik Hediyesi'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Token input field (if not auto-filled)
              if (!_invitationFetched) ...[
                const Text(
                  'Davetiye Tokenı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    hintText: '32 karakterlik hex token',
                    border: const OutlineInputBorder(),
                    errorText: _errorMessage,
                    suffixIcon: _isTokenValid
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                  maxLength: 32,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-f0-9]')),
                    LowerCaseTextFormatter(),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isTokenValid && !_isLoading
                      ? _fetchInvitationDetails
                      : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Davetiye Bilgilerini Getir'),
                ),
                const SizedBox(height: 24),
              ],

              // Invitation details (if fetched from API)
              if (_invitationFetched && _invitationDetails != null) ...[
                // 🆕 Status Indicator Card
                Builder(
                  builder: (context) {
                    final statusInfo = _getStatusInfo();

                    return Card(
                      color: (statusInfo['color'] as Color).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              statusInfo['icon'] as IconData,
                              color: statusInfo['color'] as Color,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    statusInfo['title'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: statusInfo['color'] as Color,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    statusInfo['message'] as String,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Clear token button (if invitation is not pending)
                if (!_canAcceptInvitation())
                  ElevatedButton.icon(
                    onPressed: _clearTokenAndRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yeni Davetiye Dene'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      backgroundColor: Colors.blue,
                    ),
                  ),
                if (!_canAcceptInvitation()) const SizedBox(height: 16),

                // Invitation message card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _invitationDetails!.welcomeMessage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Sponsor info
                _buildInfoCard('🏢 Sponsor', _invitationDetails!.sponsorCompanyName),
                const SizedBox(height: 12),

                // Code count
                _buildInfoCard('📦 Kod Adedi', '${_invitationDetails!.codeCount} adet'),
                const SizedBox(height: 12),

                // Package tier with badge (🆕 v2.0 enhanced display)
                // Only show if package tier is available
                if (_invitationDetails!.packageTier != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🎁 Paket Tipi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          PackageTierBadge(tier: _invitationDetails!.packageTier!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Remaining days
                Card(
                  color: _getUrgencyColor(_invitationDetails!.remainingDays).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: _getUrgencyColor(_invitationDetails!.remainingDays),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⏰ Kalan Süre',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_invitationDetails!.remainingDays} gün',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getUrgencyColor(_invitationDetails!.remainingDays),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email requirement info
                if (_invitationDetails!.dealerEmail.isNotEmpty)
                  Card(
                    color: Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Önemli Bilgi',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bu daveti kabul etmek için ${_invitationDetails!.dealerEmail} adresi ile giriş yapmanız gerekmektedir.',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Action buttons (only show if invitation can be accepted)
                if (_canAcceptInvitation())
                  ElevatedButton(
                    onPressed: _isLoading ? null : _acceptInvitation,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Daveti Kabul Et',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  ),
                if (_canAcceptInvitation()) const SizedBox(height: 12),
                if (_canAcceptInvitation())
                  OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Reddet',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
              ],

              // Error message
              if (_errorMessage != null && !_invitationFetched)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}

/// Text formatter to convert input to lowercase
class LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toLowerCase(),
      selection: newValue.selection,
    );
  }
}
