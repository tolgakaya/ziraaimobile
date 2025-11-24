import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../data/models/sponsorship_inbox_item.dart';
import '../../../data/services/sponsor_service.dart';
import '../../widgets/inbox_item_card.dart';
import 'sponsorship_redemption_screen.dart';

/// Sponsorship Inbox Screen
/// Displays list of sponsorship codes sent to farmer's phone number
class SponsorshipInboxScreen extends StatefulWidget {
  const SponsorshipInboxScreen({super.key});

  @override
  State<SponsorshipInboxScreen> createState() => _SponsorshipInboxScreenState();
}

class _SponsorshipInboxScreenState extends State<SponsorshipInboxScreen> {
  final _sponsorService = GetIt.instance<SponsorService>();

  List<SponsorshipInboxItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasRedeemedCode = false; // Track if user redeemed any code

  @override
  void initState() {
    super.initState();
    _loadInbox();
  }

  Future<void> _loadInbox() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch inbox from API (no phone parameter needed - backend gets it from JWT)
      final response = await _sponsorService.fetchInbox(
        includeUsed: true, // Show all codes including used ones
        includeExpired: false, // Don't show expired codes by default
      );

      // Convert to SponsorshipInboxItem objects
      final items = response
          .map((json) => SponsorshipInboxItem.fromJson(json))
          .toList();

      // Sort: Active codes first, then by sent date (newest first)
      items.sort((a, b) {
        // Active codes first
        if (a.isActive != b.isActive) {
          return a.isActive ? -1 : 1;
        }

        // Then by expiry urgency (closest to expiry first) for active codes
        if (a.isActive && b.isActive) {
          return a.daysUntilExpiry.compareTo(b.daysUntilExpiry);
        }

        // Finally by sent date (newest first)
        return b.sentDate.compareTo(a.sentDate);
      });

      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _navigateToRedemption(String code) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SponsorshipRedemptionScreen(
          autoFilledCode: code,
        ),
      ),
    );

    // If redemption was successful, mark flag and refresh inbox
    if (result == true && mounted) {
      setState(() {
        _hasRedeemedCode = true;
      });
      _loadInbox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Sponsorluk Teklifleri',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context, _hasRedeemedCode),
        ),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF111827)),
            onPressed: _isLoading ? null : _loadInbox,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return _buildInboxList();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22C55E)),
          ),
          SizedBox(height: 16),
          Text(
            'Teklifler yükleniyor...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
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
              onPressed: _loadInbox,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Henüz Sponsorluk Kodu Yok',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Size gönderilen sponsorluk kodları burada görünecektir',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _loadInbox,
              icon: const Icon(Icons.refresh),
              label: const Text('Yenile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22C55E),
                side: const BorderSide(color: Color(0xFF22C55E)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInboxList() {
    // Count active codes for header
    final activeCount = _items.where((item) => item.isActive).length;

    return Column(
      children: [
        // Header with count
        if (activeCount > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF22C55E).withOpacity(0.1),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Color(0xFF22C55E),
                ),
                const SizedBox(width: 8),
                Text(
                  '$activeCount aktif teklif mevcut',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF22C55E),
                  ),
                ),
              ],
            ),
          ),

        // List of items
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadInbox,
            color: const Color(0xFF22C55E),
            child: ListView.builder(
              itemCount: _items.length,
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemBuilder: (context, index) {
                final item = _items[index];
                return InboxItemCard(
                  item: item,
                  onRedeemTap: item.isActive
                      ? () => _navigateToRedemption(item.code)
                      : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
