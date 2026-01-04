import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/api/farmer_invitation_api_service.dart';
import '../../data/models/farmer_invitation_summary.dart';
import 'farmer_invitation_screen.dart';

/// Pending Farmer Invitations Screen
///
/// Shows list of all farmer invitations (pending, accepted, expired, rejected)
/// Accessed from farmer dashboard or profile menu
///
/// Flow:
/// 1. Load farmer's invitation list from GET /my-invitations
/// 2. Display with status badges and colors
/// 3. Tap pending invitation → navigate to details screen
/// 4. Accepted/Expired/Rejected → show status only
class PendingFarmerInvitationsScreen extends StatefulWidget {
  const PendingFarmerInvitationsScreen({super.key});

  @override
  State<PendingFarmerInvitationsScreen> createState() =>
      _PendingFarmerInvitationsScreenState();
}

class _PendingFarmerInvitationsScreenState
    extends State<PendingFarmerInvitationsScreen> {
  final FarmerInvitationApiService _apiService =
      GetIt.instance<FarmerInvitationApiService>();

  List<FarmerInvitationSummary> _invitations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInvitations();
  }

  Future<void> _loadInvitations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invitations = await _apiService.getMyInvitations();

      if (mounted) {
        setState(() {
          _invitations = invitations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Davetler yüklenirken hata oluştu: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(FarmerInvitationSummary invitation) {
    switch (invitation.status) {
      case 'Pending':
        return const Color(0xFFF59E0B); // Amber
      case 'Accepted':
        return const Color(0xFF10B981); // Green
      case 'Expired':
        return const Color(0xFF6B7280); // Gray
      case 'Rejected':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280);
    }
  }

  IconData _getStatusIcon(FarmerInvitationSummary invitation) {
    switch (invitation.status) {
      case 'Pending':
        return Icons.hourglass_empty;
      case 'Accepted':
        return Icons.check_circle;
      case 'Expired':
        return Icons.schedule;
      case 'Rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getStatusText(FarmerInvitationSummary invitation) {
    switch (invitation.status) {
      case 'Pending':
        return 'Beklemede';
      case 'Accepted':
        return 'Kabul Edildi';
      case 'Expired':
        return 'Süresi Doldu';
      case 'Rejected':
        return 'Reddedildi';
      default:
        return invitation.status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Çiftçi Davetlerim'),
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
                          onPressed: _loadInvitations,
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
              : RefreshIndicator(
                  onRefresh: _loadInvitations,
                  child: _invitations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Henüz davet almadınız',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Sponsor firmalardan gelen davetler burada görünecek',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _invitations.length,
                          itemBuilder: (context, index) {
                            final invitation = _invitations[index];
                            return _buildInvitationCard(invitation);
                          },
                        ),
                ),
    );
  }

  Widget _buildInvitationCard(FarmerInvitationSummary invitation) {
    final statusColor = _getStatusColor(invitation);
    final statusIcon = _getStatusIcon(invitation);
    final statusText = _getStatusText(invitation);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: invitation.isPending
            ? () {
                // Navigate to details screen for pending invitations
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FarmerInvitationScreen(
                      invitationToken: invitation.invitationId.toString(),
                    ),
                  ),
                ).then((_) {
                  // Refresh list when returning
                  _loadInvitations();
                });
              }
            : null, // Disable tap for non-pending invitations
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Arrow icon for pending invitations
                  if (invitation.isPending)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Sponsor Company
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invitation.sponsorCompanyName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Code Count
              Row(
                children: [
                  Icon(
                    Icons.card_giftcard,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${invitation.codeCount} kod',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Oluşturulma',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(invitation.createdAt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Son Geçerlilik',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDate(invitation.expiresAt),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Call to Action for Pending Invitations
              if (invitation.isPending) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 18,
                        color: const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Detayları görmek ve kabul etmek için tıklayın',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
