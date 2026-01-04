import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/api/farmer_invitation_api_service.dart';
import '../../data/models/farmer_invitation_details.dart';
import '../../data/models/farmer_invitation_accept_request.dart';
import '../../data/models/farmer_invitation_accept_response.dart';

/// Farmer Invitation Screen - Deep Link Handler
///
/// This screen is displayed when:
/// 1. Farmer clicks deep link: https://ziraai.com/farmer-invite/{token}
/// 2. App opens and DeepLinkService routes to this screen with token
///
/// Flow:
/// 1. Load invitation details (public API, no auth required)
/// 2. Show sponsor company, code count, expiry date
/// 3. If user not logged in → prompt login/register
/// 4. If logged in → show "Accept" button
/// 5. Accept → activate codes → show success with new subscription end date
class FarmerInvitationScreen extends StatefulWidget {
  final String invitationToken;

  const FarmerInvitationScreen({
    super.key,
    required this.invitationToken,
  });

  @override
  State<FarmerInvitationScreen> createState() => _FarmerInvitationScreenState();
}

class _FarmerInvitationScreenState extends State<FarmerInvitationScreen> {
  final FarmerInvitationApiService _apiService =
      GetIt.instance<FarmerInvitationApiService>();

  FarmerInvitationDetails? _invitationDetails;
  bool _isLoading = true;
  bool _isAccepting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvitationDetails();
  }

  Future<void> _loadInvitationDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _apiService.getInvitationDetails(widget.invitationToken);

      if (mounted) {
        setState(() {
          _invitationDetails = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Davet bilgileri yüklenirken hata oluştu: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _acceptInvitation() async {
    setState(() {
      _isAccepting = true;
    });

    try {
      final response = await _apiService.acceptInvitation(
        FarmerInvitationAcceptRequest(
          invitationToken: widget.invitationToken,
        ),
      );

      if (mounted) {
        setState(() {
          _isAccepting = false;
        });

        _showSuccessDialog(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAccepting = false;
        });

        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(FarmerInvitationAcceptResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.celebration, color: Colors.green[600], size: 32),
            const SizedBox(width: 12),
            const Text('Tebrikler!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              response.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${response.activatedCodes} kod aktif edildi',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Abonelik bitiş: ${_formatDate(response.subscriptionEndDate)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('Hata'),
          ],
        ),
        content: Text(
          'Davet kabul edilirken hata oluştu:\n\n$error',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Çiftçi Daveti'),
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadInvitationDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Welcome Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                Icons.celebration,
                                size: 64,
                                color: Colors.green[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _invitationDetails!.welcomeMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Invitation Details Card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Davet Detayları',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Sponsor Company
                              _buildDetailRow(
                                icon: Icons.business,
                                label: 'Sponsor Firma',
                                value: _invitationDetails!.sponsorCompanyName,
                                iconColor: const Color(0xFF3B82F6),
                              ),

                              const SizedBox(height: 12),

                              // Code Count
                              _buildDetailRow(
                                icon: Icons.card_giftcard,
                                label: 'Kod Sayısı',
                                value: '${_invitationDetails!.codeCount} kod',
                                iconColor: const Color(0xFF10B981),
                              ),

                              const SizedBox(height: 12),

                              // Package Tier (if available)
                              if (_invitationDetails!.packageTier != null &&
                                  _invitationDetails!.tierDisplayName != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildDetailRow(
                                    icon: Icons.stars,
                                    label: 'Paket Seviyesi',
                                    value: _invitationDetails!.tierDisplayName!,
                                    iconColor: const Color(0xFFF59E0B),
                                  ),
                                ),

                              // Expiry Date
                              _buildDetailRow(
                                icon: _invitationDetails!.isExpiringSoon
                                    ? Icons.warning_amber
                                    : Icons.calendar_today,
                                label: 'Geçerlilik',
                                value:
                                    '${_invitationDetails!.remainingDays} gün kaldı',
                                iconColor: _invitationDetails!.isExpiringSoon
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF8B5CF6),
                              ),

                              const SizedBox(height: 12),

                              // Dealer Contact
                              _buildDetailRow(
                                icon: Icons.email,
                                label: 'İletişim',
                                value: _invitationDetails!.dealerEmail,
                                iconColor: const Color(0xFF6B7280),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Accept Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isAccepting ? null : _acceptInvitation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isAccepting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle, size: 24),
                                    SizedBox(width: 8),
                                    Text(
                                      'Daveti Kabul Et',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Terms Note
                      Text(
                        'Daveti kabul ederek kodlar hesabınıza eklenecek ve aboneliğiniz uzatılacaktır.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
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
}
