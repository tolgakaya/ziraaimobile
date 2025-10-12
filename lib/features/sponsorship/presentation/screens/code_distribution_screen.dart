import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../data/models/sponsorship_code.dart';
import '../../data/models/code_package.dart';
import '../../data/models/code_recipient.dart';
import '../../data/models/send_link_response.dart';
import '../../data/models/sponsor_dashboard_summary.dart';
import '../../data/services/sponsor_service.dart';
import '../widgets/package_selector_widget.dart';
import '../widgets/recipient_list_item.dart';
import '../widgets/add_recipient_dialog.dart';
import '../widgets/channel_selector_widget.dart';
import 'code_distribution_success_screen.dart';

class CodeDistributionScreen extends StatefulWidget {
  final SponsorDashboardSummary dashboardSummary;

  const CodeDistributionScreen({
    super.key,
    required this.dashboardSummary,
  });

  @override
  State<CodeDistributionScreen> createState() => _CodeDistributionScreenState();
}

class _CodeDistributionScreenState extends State<CodeDistributionScreen> {
  final SponsorService _sponsorService = GetIt.instance<SponsorService>();

  List<SponsorshipCode> _allCodes = [];
  List<CodePackage> _packages = [];
  CodePackage? _selectedPackage;
  // Store recipients per package (purchaseId -> recipients list)
  // This prevents data loss when switching between packages
  Map<int, List<CodeRecipient>> _packageRecipients = {};
  MessageChannel _selectedChannel = MessageChannel.sms; // SMS default

  // Helper getter for current package recipients
  List<CodeRecipient> get _currentRecipients {
    if (_selectedPackage == null) return [];
    return _packageRecipients[_selectedPackage!.purchaseId] ?? [];
  }

  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;

  // Pagination state
  int _currentPage = 1;
  bool _hasMoreCodes = true;
  bool _isLoadingMore = false;
  int _totalCodesAvailable = 0;

  @override
  void initState() {
    super.initState();
    _loadUnusedCodes();
  }

  Future<void> _loadUnusedCodes({bool loadMore = false}) async {
    // Prevent concurrent loads
    if (_isLoadingMore) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentPage = 1;
        _hasMoreCodes = true;
      }
      _errorMessage = null;
    });

    try {
      // IMPORTANT: Use getUnsentCodes() to get ONLY codes that have never been sent
      // This prevents duplicate code distribution (DistributionDate = NULL)
      final result = await _sponsorService.getUnsentCodes(
        page: loadMore ? _currentPage + 1 : 1,
        pageSize: 50,
      );

      // Create mapping of purchaseId -> totalCodes from dashboard
      // Dashboard has tier-based info, but codes have purchaseId
      // We'll match by tier for now (assuming one package per tier)
      final Map<int, int> packageTotalCodesMap = {};

      // Build map from dashboard active packages
      for (final dashboardPackage in widget.dashboardSummary.activePackages) {
        // Find a code with matching tier to get purchaseId
        if (result.items.isNotEmpty) {
          final matchingCode = result.items.firstWhere(
            (code) {
              // Map tierId to tierName for comparison
              final tierNameMap = {1: 'Trial', 2: 'S', 3: 'M', 4: 'L', 5: 'XL'};
              final codeTierName = tierNameMap[code.subscriptionTierId] ?? '';
              return codeTierName == dashboardPackage.tierName;
            },
            orElse: () => result.items.first,
          );

          packageTotalCodesMap[matchingCode.sponsorshipPurchaseId] = dashboardPackage.totalCodes;
        }
      }

      if (mounted) {
        setState(() {
          if (loadMore) {
            // Append new codes to existing list
            _allCodes.addAll(result.items);
            _currentPage++;
          } else {
            // Replace with fresh data
            _allCodes = result.items;
            _currentPage = result.page;
          }

          // Update pagination state
          _hasMoreCodes = result.hasNextPage;
          _totalCodesAvailable = result.totalCount;

          // Rebuild packages from all loaded codes
          _packages = CodePackage.groupByPurchase(
            _allCodes,
            packageTotalCodesMap: packageTotalCodesMap,
          );

          // Set first package as default selection (only on initial load)
          if (!loadMore && _packages.isNotEmpty && _selectedPackage == null) {
            _selectedPackage = _packages.first;
          }

          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _isLoadingMore = false;
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

    return RefreshIndicator(
      onRefresh: () => _loadUnusedCodes(loadMore: false),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pagination Info Card
            if (_totalCodesAvailable > 0)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20, color: Color(0xFF6B7280)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toplam $_totalCodesAvailable kod mevcut. Şu an ${_allCodes.length} kod yüklendi.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Package Selector with dynamic remaining count
            PackageSelectorWidget(
              selectedPackage: _selectedPackage,
              packages: _packages,
              recipientCount: _currentRecipients.length, // Current package recipient count for display
              onPackageSelected: (package) {
                setState(() {
                  _selectedPackage = package;
                  // Recipients are now stored per-package, so switching preserves each package's list
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
            if (_currentRecipients.isNotEmpty)
              ..._currentRecipients.map((recipient) {
                return RecipientListItem(
                  recipient: recipient,
                  onDelete: () => _removeRecipient(recipient),
                );
              }),

            // Add Recipient Buttons
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickContactsFromPhone,
                    icon: const Icon(Icons.contacts),
                    label: const Text('Telefon Rehberinden Seç'),
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
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _showAddRecipientDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Manuel Ekle'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF10B981),
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

            // Load More Codes Button
            if (_hasMoreCodes && !_isLoadingMore)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24),
                child: OutlinedButton.icon(
                  onPressed: () => _loadUnusedCodes(loadMore: true),
                  icon: const Icon(Icons.download),
                  label: const Text('Daha Fazla Kod Yükle'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Loading More Indicator
            if (_isLoadingMore)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                child: const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Kodlar yükleniyor...',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Summary Card
            if (_selectedPackage != null || _currentRecipients.isNotEmpty)
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
      ),
    );
  }

  Widget _buildSummaryCard() {
    // Calculate totals across ALL packages
    int totalRecipients = 0;
    for (final recipients in _packageRecipients.values) {
      totalRecipients += recipients.length;
    }

    // Get packages with recipients
    final packagesWithRecipients = _packageRecipients.entries
        .where((entry) => entry.value.isNotEmpty)
        .toList();

    final tierNameMap = {1: 'Trial', 2: 'S', 3: 'M', 4: 'L', 5: 'XL'};

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gönderim Özeti',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'TOPLAM: $totalRecipients kişi',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Show all packages with recipients
          if (packagesWithRecipients.isNotEmpty) ...[
            ...packagesWithRecipients.map((entry) {
              final purchaseId = entry.key;
              final recipients = entry.value;
              
              // Find the package for this purchaseId
              final package = _packages.firstWhere(
                (p) => p.purchaseId == purchaseId,
                orElse: () => _packages.first,
              );
              
              final tierName = tierNameMap[package.tierId] ?? 'Bilinmeyen';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Paket $tierName',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${recipients.length} kişi',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Show recipients for this package
                    ...recipients.take(3).map((recipient) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.person, size: 12, color: Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${recipient.name} - ${recipient.phone}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (recipients.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '+${recipients.length - 3} kişi daha...',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Henüz alıcı eklenmedi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ],

          const Divider(height: 24),
          _buildSummaryRow(
            'Gönderim Kanalı',
            _selectedChannel == MessageChannel.sms
                ? 'SMS'
                : _selectedChannel == MessageChannel.whatsapp
                    ? 'WhatsApp'
                    : 'Seçilmedi',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRecipientDialog() async {
    if (_selectedPackage == null) return;

    // Check if we have available codes
    final availableCodes = _selectedPackage!.codes.length;
    final currentRecipients = _currentRecipients.length;

    if (currentRecipients >= availableCodes) {
      _showMaxRecipientsDialog();
      return;
    }

    final recipient = await showDialog<CodeRecipient>(
      context: context,
      builder: (context) => const AddRecipientDialog(),
    );

    if (recipient != null) {
      setState(() {
        final purchaseId = _selectedPackage!.purchaseId;
        _packageRecipients[purchaseId] = [..._currentRecipients, recipient];
      });
    }
  }

  void _showMaxRecipientsDialog() {
    final packageName = _selectedPackage?.displayName ?? 'Bu paket';
    final availableCodes = _selectedPackage?.codes.length ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            const SizedBox(width: 12),
            const Text('Maksimum Kişi Sayısına Ulaşıldı'),
          ],
        ),
        content: Text(
          '$packageName için maksimum $availableCodes kişiye kod gönderebilirsiniz.\n\nDaha fazla kod göndermek için başka bir paket seçin veya yeni paket satın alın.',
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

  void _removeRecipient(CodeRecipient recipient) {
    if (_selectedPackage == null) return;

    setState(() {
      final purchaseId = _selectedPackage!.purchaseId;
      final updatedList = List<CodeRecipient>.from(_currentRecipients);
      updatedList.remove(recipient);
      _packageRecipients[purchaseId] = updatedList;
    });
  }

  Future<void> _pickContactsFromPhone() async {
    try {
      // Request permission using flutter_contacts (avoids conflict with telephony package)
      final permissionGranted = await FlutterContacts.requestPermission();

      if (!permissionGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rehber izni gerekli'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        return;
      }

      // Fetch contacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (!mounted) return;

      // Show contact selection dialog
      final selectedContacts = await showDialog<List<Contact>>(
        context: context,
        builder: (context) => _ContactSelectionDialog(contacts: contacts),
      );

      if (selectedContacts != null && selectedContacts.isNotEmpty) {
        if (_selectedPackage == null) return;

        // Check available space
        final availableCodes = _selectedPackage!.codes.length;
        final currentRecipients = _currentRecipients.length;
        final remainingSlots = availableCodes - currentRecipients;

        if (remainingSlots <= 0) {
          _showMaxRecipientsDialog();
          return;
        }

        // Convert selected contacts to CodeRecipient
        final newRecipients = <CodeRecipient>[];

        for (final contact in selectedContacts) {
          if (contact.phones.isNotEmpty) {
            final phone = contact.phones.first.number;
            final name = contact.displayName;

            // Check if contact already added
            final exists = _currentRecipients.any((r) =>
              CodeRecipient.normalizePhone(r.phone) == CodeRecipient.normalizePhone(phone)
            );

            if (!exists) {
              // Stop adding if we reach the limit
              if (newRecipients.length + currentRecipients >= availableCodes) {
                break;
              }
              newRecipients.add(CodeRecipient(
                name: name,
                phone: phone,
              ));
            }
          }
        }

        if (newRecipients.isNotEmpty) {
          setState(() {
            final purchaseId = _selectedPackage!.purchaseId;
            _packageRecipients[purchaseId] = [..._currentRecipients, ...newRecipients];
          });

          if (mounted) {
            final limitReached = _currentRecipients.length >= availableCodes;
            final message = limitReached
                ? '${newRecipients.length} kişi eklendi. Maksimum kişi sayısına ulaşıldı.'
                : '${newRecipients.length} kişi eklendi';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: limitReached ? Colors.orange : const Color(0xFF10B981),
                duration: Duration(seconds: limitReached ? 4 : 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  bool _canSend() {
    if (_isSending) return false;

    // Check if we have ANY recipients across ALL packages
    int totalRecipients = 0;
    for (final recipients in _packageRecipients.values) {
      totalRecipients += recipients.length;
    }

    if (totalRecipients == 0) return false;
    
    // Check if each package has enough codes for its recipients
    for (final entry in _packageRecipients.entries) {
      if (entry.value.isEmpty) continue;
      
      final package = _packages.firstWhere(
        (p) => p.purchaseId == entry.key,
        orElse: () => _packages.first,
      );
      
      final availableCodes = package.codes.where((c) => !c.isUsed).length;
      if (entry.value.length > availableCodes) {
        return false; // Not enough codes for this package
      }
    }

    return true;
  }

  Future<void> _sendLinks() async {
    if (!_canSend()) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Collect ALL recipients and codes from ALL packages
      final List<CodeRecipient> allRecipients = [];
      final List<String> allCodes = [];

      for (final entry in _packageRecipients.entries) {
        if (entry.value.isEmpty) continue;

        final purchaseId = entry.key;
        final recipients = entry.value;

        // Find the package
        final package = _packages.firstWhere(
          (p) => p.purchaseId == purchaseId,
          orElse: () => _packages.first,
        );

        // Get unused codes for this package
        final packageCodes = package.codes
            .where((code) => !code.isUsed)
            .take(recipients.length)
            .map((code) => code.code)
            .toList();

        allRecipients.addAll(recipients);
        allCodes.addAll(packageCodes);
      }

      // Send links
      final channelName = _selectedChannel == MessageChannel.sms ? 'SMS' : 'WhatsApp';

      // DEBUG LOG
      print('🚀 BULK CODE DISTRIBUTION: Sending ${allRecipients.length} links via $channelName');
      print('🚀 BULK CODE DISTRIBUTION: Total packages: ${_packageRecipients.entries.where((e) => e.value.isNotEmpty).length}');
      print('🚀 BULK CODE DISTRIBUTION: Selected codes: $allCodes');
      print('🚀 BULK CODE DISTRIBUTION: Recipients: ${allRecipients.map((r) => '${r.name} (${r.phone})').toList()}');

      final response = await _sponsorService.sendSponsorshipLinks(
        recipients: allRecipients,
        channel: channelName,
        selectedCodes: allCodes,
      );

      // DEBUG LOG
      print('🚀 BULK CODE DISTRIBUTION: Response received - success: ${response.success}');
      print('🚀 BULK CODE DISTRIBUTION: Success count: ${response.data?.successCount}');
      print('🚀 BULK CODE DISTRIBUTION: Failure count: ${response.data?.failureCount}');

      if (mounted) {
        if (response.success) {
          _showSuccessDialog(response);
        } else {
          _showErrorDialog(response.message);
        }
      }
    } catch (e) {
      print('🚀 BULK CODE DISTRIBUTION: ERROR - $e');
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
    // Navigate to success screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CodeDistributionSuccessScreen(response: response),
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

// Contact Selection Dialog
class _ContactSelectionDialog extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactSelectionDialog({required this.contacts});

  @override
  State<_ContactSelectionDialog> createState() => _ContactSelectionDialogState();
}

class _ContactSelectionDialogState extends State<_ContactSelectionDialog> {
  late List<Contact> _filteredContacts;
  final Set<Contact> _selectedContacts = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts = widget.contacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kişi Seç',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kişi ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterContacts,
            ),
            const SizedBox(height: 16),

            // Selected count
            if (_selectedContacts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedContacts.length} kişi seçildi',
                      style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Contact List
            Expanded(
              child: _filteredContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Kişi bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final isSelected = _selectedContacts.contains(contact);
                        final hasPhone = contact.phones.isNotEmpty;

                        return ListTile(
                          enabled: hasPhone,
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE5E7EB),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : Text(
                                    contact.displayName.isNotEmpty
                                        ? contact.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                          ),
                          title: Text(
                            contact.displayName,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: hasPhone
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          subtitle: hasPhone
                              ? Text(
                                  contact.phones.first.number,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                )
                              : const Text(
                                  'Telefon numarası yok',
                                  style: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                          onTap: hasPhone
                              ? () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedContacts.remove(contact);
                                    } else {
                                      _selectedContacts.add(contact);
                                    }
                                  });
                                }
                              : null,
                        );
                      },
                    ),
            ),

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'İptal',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedContacts.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selectedContacts.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: const Text('Ekle'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
