import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/models/sponsorship_code.dart';
import '../../data/models/code_package.dart';
import '../../data/models/code_recipient.dart';
import '../../data/services/sponsor_service.dart';
import '../widgets/package_selector_widget.dart';
import '../widgets/recipient_list_item.dart';
import '../widgets/add_recipient_dialog.dart';
import '../widgets/channel_selector_widget.dart';

class CodeDistributionScreen extends StatefulWidget {
  const CodeDistributionScreen({super.key});

  @override
  State<CodeDistributionScreen> createState() => _CodeDistributionScreenState();
}

class _CodeDistributionScreenState extends State<CodeDistributionScreen> {
  final SponsorService _sponsorService = GetIt.instance<SponsorService>();

  List<SponsorshipCode> _allCodes = [];
  List<CodePackage> _packages = [];
  CodePackage? _selectedPackage;
  List<CodeRecipient> _recipients = [];
  MessageChannel? _selectedChannel;

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUnusedCodes();
  }

  Future<void> _loadUnusedCodes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final codes = await _sponsorService.getUnusedCodes();

      if (mounted) {
        setState(() {
          _allCodes = codes;
          _packages = CodePackage.groupByPurchase(codes);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Kod Dağıt'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildMainContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Bir hata oluştu',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUnusedCodes,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_packages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Kullanılabilir kod bulunamadı',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Selector
          PackageSelectorWidget(
            selectedPackage: _selectedPackage,
            packages: _packages,
            onPackageSelected: (package) {
              setState(() {
                _selectedPackage = package;
              });
            },
          ),
          const SizedBox(height: 24),

          // Recipients Section
          const Text(
            'Alıcı Listesi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),

          // Recipients List
          if (_recipients.isNotEmpty)
            ..._recipients.map((recipient) {
              return RecipientListItem(
                recipient: recipient,
                onDelete: () => _removeRecipient(recipient),
              );
            }),

          // Add Recipient Buttons
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddRecipientDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Manuel Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Channel Selector
          ChannelSelectorWidget(
            selectedChannel: _selectedChannel,
            onChannelSelected: (channel) {
              setState(() {
                _selectedChannel = channel;
              });
            },
          ),
          const SizedBox(height: 24),

          // Summary Card
          if (_selectedPackage != null || _recipients.isNotEmpty)
            _buildSummaryCard(),
          const SizedBox(height: 16),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSend() ? _sendLinks : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Kodları Gönder',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final recipientCount = _recipients.length;
    final availableCodes = _selectedPackage?.unusedCount ?? 0;
    final hasEnoughCodes = recipientCount <= availableCodes;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Özet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(
            'Seçilen Paket',
            _selectedPackage?.displayName ?? 'Seçilmedi',
          ),
          _buildSummaryRow(
            'Alıcı Sayısı',
            '$recipientCount kişi',
          ),
          _buildSummaryRow(
            'Gönderim Kanalı',
            _selectedChannel == MessageChannel.sms
                ? 'SMS'
                : _selectedChannel == MessageChannel.whatsapp
                    ? 'WhatsApp'
                    : 'Seçilmedi',
          ),
          const Divider(height: 24),
          Row(
            children: [
              Icon(
                hasEnoughCodes ? Icons.check_circle : Icons.warning,
                color: hasEnoughCodes ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasEnoughCodes
                      ? '$recipientCount kod otomatik atanacak'
                      : 'Yetersiz kod! $availableCodes kod mevcut, $recipientCount gerekli',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasEnoughCodes ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
            ),
          ),
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
    );
  }

  void _showAddRecipientDialog() async {
    final recipient = await showDialog<CodeRecipient>(
      context: context,
      builder: (context) => const AddRecipientDialog(),
    );

    if (recipient != null) {
      setState(() {
        _recipients.add(recipient);
      });
    }
  }

  void _removeRecipient(CodeRecipient recipient) {
    setState(() {
      _recipients.remove(recipient);
    });
  }

  bool _canSend() {
    if (_isSending) return false;
    if (_selectedPackage == null) return false;
    if (_recipients.isEmpty) return false;
    if (_selectedChannel == null) return false;
    if (_recipients.length > _selectedPackage!.unusedCount) return false;

    return true;
  }

  Future<void> _sendLinks() async {
    if (!_canSend()) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Get codes from selected package
      final unusedCodes = _selectedPackage!.codes
          .where((code) => !code.isUsed)
          .take(_recipients.length)
          .map((code) => code.code)
          .toList();

      // Send links
      final channelName = _selectedChannel == MessageChannel.sms ? 'SMS' : 'WhatsApp';

      final response = await _sponsorService.sendSponsorshipLinks(
        recipients: _recipients,
        channel: channelName,
        selectedCodes: unusedCodes,
      );

      if (mounted) {
        if (response.success) {
          _showSuccessDialog(response);
        } else {
          _showErrorDialog(response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showSuccessDialog(SendLinkResponse response) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 12),
            const Text('Başarılı!'),
          ],
        ),
        content: Text(
          '${response.data?.successCount ?? 0} kod başarıyla gönderildi!\n\n'
          '${response.data?.failureCount ?? 0} başarısız gönderim.',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to dashboard
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600]),
            const SizedBox(width: 12),
            const Text('Hata'),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }
}
