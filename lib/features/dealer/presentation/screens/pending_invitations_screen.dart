import 'package:flutter/material.dart';
import '../../../../core/di/injection.dart';
import '../../data/dealer_api_service.dart';
import '../../domain/models/dealer_invitation_summary.dart';
import '../widgets/package_tier_badge.dart';
import 'dealer_invitation_screen.dart';

/// Pending Dealer Invitations List Screen
///
/// ✅ UPDATED: Shows pending dealer invitations from backend API
///
/// Features:
/// - Fetch pending invitations from backend API
/// - Filter: Backend returns only "Pending" invitations
/// - Sort: Backend sorts by urgency (expiring soon first)
/// - Navigate to detail screen for acceptance
/// - Pull-to-refresh support
class PendingInvitationsScreen extends StatefulWidget {
  const PendingInvitationsScreen({Key? key}) : super(key: key);

  @override
  State<PendingInvitationsScreen> createState() => _PendingInvitationsScreenState();
}

class _PendingInvitationsScreenState extends State<PendingInvitationsScreen> {
  late final DealerApiService _dealerApiService;

  bool _isLoading = false;
  List<DealerInvitationSummary> _pendingInvitations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dealerApiService = getIt<DealerApiService>();
    _fetchPendingInvitations();
  }

  /// ✅ NEW: Fetch pending invitations from backend API
  /// Replaces SMS scanning with direct backend call
  Future<void> _fetchPendingInvitations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('[PendingInvitations] 🔍 Fetching pending invitations from backend...');

      // Call backend API to get pending invitations
      // Backend already filters by "Pending" status and sorts by urgency
      final invitations = await _dealerApiService.getMyPendingInvitations();

      setState(() {
        _pendingInvitations = invitations;
        _isLoading = false;
      });

      print('[PendingInvitations] ✅ Found ${invitations.length} pending invitations');
    } catch (e) {
      print('[PendingInvitations] ❌ Error fetching pending invitations: $e');
      setState(() {
        _errorMessage = 'Davetiyeler yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Color _getUrgencyColor(int days) {
    if (days <= 1) return Colors.red;
    if (days <= 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bekleyen Davetiyeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _fetchPendingInvitations,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Davetiyeler yükleniyor...'),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchPendingInvitations,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_pendingInvitations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.inbox,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Bekleyen Davetiye Yok',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Şu anda bekleyen dealer davetiyeniz bulunmuyor.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchPendingInvitations,
                icon: const Icon(Icons.refresh),
                label: const Text('Yenile'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  // Navigate to detail screen and wait for result
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DealerInvitationScreen(),
                    ),
                  );

                  // If invitation was accepted, refresh the list
                  if (result == true && mounted) {
                    print('[PendingInvitations] 🔄 Manual invitation accepted, refreshing list...');
                    _fetchPendingInvitations();
                  }
                },
                child: const Text('Manuel Token Gir'),
              ),
            ],
          ),
        ),
      );
    }

    // List of pending invitations
    return RefreshIndicator(
      onRefresh: _fetchPendingInvitations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _pendingInvitations.length + 1, // +1 for header
        itemBuilder: (context, index) {
          // Header
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.pending_actions, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bekleyen Davetiyeler (${_pendingInvitations.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Süresi yakında dolanlar en üstte',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          // Invitation card
          final invitation = _pendingInvitations[index - 1];
          return _buildInvitationCard(invitation);
        },
      ),
    );
  }

  Widget _buildInvitationCard(DealerInvitationSummary invitation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () async {
          // Navigate to detail screen and wait for result
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DealerInvitationScreen(token: invitation.token),
            ),
          );

          // If invitation was accepted, refresh the list
          if (result == true && mounted) {
            print('[PendingInvitations] 🔄 Invitation accepted, refreshing list...');
            _fetchPendingInvitations();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sponsor name and urgency indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invitation.sponsorCompanyName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor(invitation.remainingDays).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getUrgencyColor(invitation.remainingDays),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: _getUrgencyColor(invitation.remainingDays),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${invitation.remainingDays} gün',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getUrgencyColor(invitation.remainingDays),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Code count and tier
              Row(
                children: [
                  const Icon(Icons.confirmation_number, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${invitation.codeCount} adet kod',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (invitation.packageTier != null) ...[
                    const SizedBox(width: 16),
                    CompactTierBadge(tier: invitation.packageTier!),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Action button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Navigate to detail screen and wait for result
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DealerInvitationScreen(token: invitation.token),
                      ),
                    );

                    // If invitation was accepted, refresh the list
                    if (result == true && mounted) {
                      print('[PendingInvitations] 🔄 Invitation accepted, refreshing list...');
                      _fetchPendingInvitations();
                    }
                  },
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: const Text('Detayları Gör'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
