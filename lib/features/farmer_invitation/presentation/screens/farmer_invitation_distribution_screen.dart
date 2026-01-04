import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../sponsorship/data/models/code_recipient.dart';
import '../../../sponsorship/data/models/sponsor_dashboard_summary.dart';
import '../../../sponsorship/data/models/sponsorship_code.dart';
import '../../../sponsorship/data/models/code_package.dart';
import '../../../sponsorship/data/models/unified_code.dart';
import '../../../sponsorship/presentation/widgets/recipient_list_item.dart';
import '../../../sponsorship/presentation/widgets/add_recipient_dialog.dart';
import '../../../sponsorship/presentation/widgets/channel_selector_widget.dart';
import '../../../sponsorship/data/services/sponsor_service.dart';
import '../../../dealer/data/dealer_api_service.dart';
import '../../data/api/farmer_invitation_api_service.dart';
import '../../data/models/create_farmer_invitation_request.dart';

/// Farmer Invitation Distribution Screen
///
/// 3-mode system like CodeDistributionScreen:
/// - Yeni (Purchased New): Sponsor's purchased unsent codes
/// - Dolmuş (Purchased Expired): Sponsor's expired codes for resend
/// - Bayi (Dealer Transferred): Dealer's transferred codes
///
/// Key difference from old code distribution:
/// - Each farmer gets exactly ONE code (no selector)
/// - Uses /farmer/invite endpoint with deep link
/// - Backend has single endpoint, modes differentiate code source
enum FarmerInvitationMode {
  purchasedNew,        // Sponsor's purchased unsent codes
  purchasedExpired,    // Sponsor's expired codes for resend
  dealerTransferred,   // Dealer's transferred codes
}

class FarmerInvitationDistributionScreen extends StatefulWidget {
  final SponsorDashboardSummary dashboardSummary;

  const FarmerInvitationDistributionScreen({
    super.key,
    required this.dashboardSummary,
  });

  @override
  State<FarmerInvitationDistributionScreen> createState() =>
      _FarmerInvitationDistributionScreenState();
}

class _FarmerInvitationDistributionScreenState
    extends State<FarmerInvitationDistributionScreen> {
  final FarmerInvitationApiService _farmerInvitationService =
      GetIt.instance<FarmerInvitationApiService>();
  final PermissionService _permissionService = getIt<PermissionService>();
  final SponsorService _sponsorService = getIt<SponsorService>();
  final DealerApiService _dealerApiService = GetIt.instance<DealerApiService>();

  // Mode management
  FarmerInvitationMode _currentMode = FarmerInvitationMode.purchasedNew;

  // Code management
  List<SponsorshipCode> _allCodes = [];
  List<CodePackage> _packages = [];
  CodePackage? _selectedPackage;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasMoreCodes = true;
  int _totalCodesAvailable = 0;

  // Recipient management
  Map<int, List<CodeRecipient>> _packageRecipients = {};
  MessageChannel _selectedChannel = MessageChannel.sms;

  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCodes();
  }

  /// Load codes based on current mode
  Future<void> _loadCodes({bool loadMore = false}) async {
    if (_currentMode == FarmerInvitationMode.dealerTransferred) {
      await _loadDealerCodes(loadMore: loadMore);
      return;
    }

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    try {
      final result = _currentMode == FarmerInvitationMode.purchasedExpired
          ? await _sponsorService.getSentExpiredCodes(
              page: loadMore ? _currentPage + 1 : 1,
              pageSize: 50,
              excludeDealerTransferred: true,
            )
          : await _sponsorService.getUnsentCodes(
              page: loadMore ? _currentPage + 1 : 1,
              pageSize: 50,
              excludeDealerTransferred: true,
            );

      if (mounted) {
        setState(() {
          if (loadMore) {
            _allCodes.addAll(result.items);
            _currentPage++;
          } else {
            _allCodes = result.items;
            _currentPage = result.page;

            // Group codes into packages
            final packageTotalCodesMap = <int, int>{};
            for (var code in _allCodes) {
              packageTotalCodesMap[code.sponsorshipPurchaseId] =
                  (packageTotalCodesMap[code.sponsorshipPurchaseId] ?? 0) + 1;
            }

            _packages = CodePackage.groupByPurchase(_allCodes, packageTotalCodesMap: packageTotalCodesMap);

            // Set first package as default selection
            if (_packages.isNotEmpty && _selectedPackage == null) {
              _selectedPackage = _packages.first;
            }
          }

          _hasMoreCodes = result.hasNextPage;
          _totalCodesAvailable = result.totalCount;
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

  /// Load dealer transferred codes
  Future<void> _loadDealerCodes({bool loadMore = false}) async {
    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
      }
    });

    try {
      final result = await _dealerApiService.getMyCodes(
        page: loadMore ? _currentPage + 1 : 1,
        pageSize: 50,
        onlyUnsent: true,
      );

      if (mounted) {
        setState(() {
          if (loadMore) {
            final unifiedCodes = result.items
                .map((dealerCode) => UnifiedCode.fromDealerCode(dealerCode))
                .toList();

            final dealerSponsorCodes = unifiedCodes.map((uc) => SponsorshipCode(
              id: uc.id,
              code: uc.code,
              sponsorId: 0,
              subscriptionTierId: uc.subscriptionTierId,
              sponsorshipPurchaseId: 0,
              isUsed: uc.isUsed,
              createdDate: uc.createdDate,
              expiryDate: uc.expiryDate,
              isActive: uc.isActive,
              linkClickCount: 0,
              linkDelivered: false,
            )).toList();

            _allCodes.addAll(dealerSponsorCodes);
            _currentPage++;
          } else {
            final unifiedCodes = result.items
                .map((dealerCode) => UnifiedCode.fromDealerCode(dealerCode))
                .toList();

            _packages = CodePackage.groupDealerCodesByTier(
              unifiedCodes,
              totalCodesCount: result.totalCount,
            );

            _allCodes = unifiedCodes.map((uc) => SponsorshipCode(
              id: uc.id,
              code: uc.code,
              sponsorId: 0,
              subscriptionTierId: uc.subscriptionTierId,
              sponsorshipPurchaseId: 0,
              isUsed: uc.isUsed,
              createdDate: uc.createdDate,
              expiryDate: uc.expiryDate,
              isActive: uc.isActive,
              linkClickCount: 0,
              linkDelivered: false,
            )).toList();

            _currentPage = result.page;

            if (_packages.isNotEmpty && _selectedPackage == null) {
              _selectedPackage = _packages.first;
            }
          }

          _hasMoreCodes = result.hasNextPage;
          _totalCodesAvailable = result.totalCount;
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
        title: const Text('Çiftçilere Davetiye Gönder'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Yeni Kodlar (Purchased New)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentMode != FarmerInvitationMode.purchasedNew) {
                        setState(() {
                          _currentMode = FarmerInvitationMode.purchasedNew;
                          _packageRecipients.clear();
                          _selectedPackage = null;
                        });
                        _loadCodes();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentMode == FarmerInvitationMode.purchasedNew
                            ? const Color(0xFF10B981)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: const Color(0xFF10B981),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fiber_new,
                            size: 16,
                            color: _currentMode == FarmerInvitationMode.purchasedNew
                                ? Colors.white
                                : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Yeni',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _currentMode == FarmerInvitationMode.purchasedNew
                                  ? Colors.white
                                  : const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Süresi Dolmuş (Purchased Expired)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentMode != FarmerInvitationMode.purchasedExpired) {
                        setState(() {
                          _currentMode = FarmerInvitationMode.purchasedExpired;
                          _packageRecipients.clear();
                          _selectedPackage = null;
                        });
                        _loadCodes();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentMode == FarmerInvitationMode.purchasedExpired
                            ? const Color(0xFFF59E0B)
                            : Colors.transparent,
                        border: Border.all(
                          color: const Color(0xFFF59E0B),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restore,
                            size: 16,
                            color: _currentMode == FarmerInvitationMode.purchasedExpired
                                ? Colors.white
                                : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Dolmuş',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _currentMode == FarmerInvitationMode.purchasedExpired
                                  ? Colors.white
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Bayi Kodları (Dealer Transferred)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_currentMode != FarmerInvitationMode.dealerTransferred) {
                        setState(() {
                          _currentMode = FarmerInvitationMode.dealerTransferred;
                          _packageRecipients.clear();
                          _selectedPackage = null;
                        });
                        _loadCodes();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _currentMode == FarmerInvitationMode.dealerTransferred
                            ? const Color(0xFF6366F1)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                        border: Border.all(
                          color: const Color(0xFF6366F1),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store,
                            size: 16,
                            color: _currentMode == FarmerInvitationMode.dealerTransferred
                                ? Colors.white
                                : const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Bayi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _currentMode == FarmerInvitationMode.dealerTransferred
                                  ? Colors.white
                                  : const Color(0xFF6366F1),
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
              onPressed: _loadCodes,
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
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF3B82F6), width: 1),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Her çiftçiye tam 1 kod gönderilir. Çiftçi deep link ile daveti kabul eder.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1E40AF),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Package Selection
          const Text(
            'Paket Seçimi',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedPackage?.purchaseId,
                isExpanded: true,
                items: _packages.map((package) {
                  return DropdownMenuItem<int>(
                    value: package.purchaseId,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.card_giftcard,
                          size: 20,
                          color: Color(0xFF10B981),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${package.displayName} - ${package.unusedCount}/${package.totalCount} kod',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (purchaseId) {
                  setState(() {
                    _selectedPackage = _packages.firstWhere(
                      (p) => p.purchaseId == purchaseId,
                    );
                  });
                },
              ),
            ),
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

          // Recipients List for selected package
          if (_selectedPackage != null && _packageRecipients[_selectedPackage!.purchaseId] != null)
            ..._packageRecipients[_selectedPackage!.purchaseId]!.map((recipient) {
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

          // Summary Card
          if (_selectedPackage != null && _packageRecipients[_selectedPackage!.purchaseId] != null && _packageRecipients[_selectedPackage!.purchaseId]!.isNotEmpty)
            _buildSummaryCard(),
          const SizedBox(height: 16),

          // Send Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSend() ? _sendInvitations : null,
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
                        Icon(Icons.send, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Davetiye Gönder',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Kullanılabilir kod yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentMode == FarmerInvitationMode.purchasedNew
                  ? 'Yeni paket satın alarak kod edinebilirsiniz'
                  : _currentMode == FarmerInvitationMode.purchasedExpired
                      ? 'Süresi dolmuş kod bulunmuyor'
                      : 'Bayi kodunuz bulunmuyor',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final recipientCount = _packageRecipients[_selectedPackage!.purchaseId]?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.summarize, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text(
                'Özet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF065F46),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Alıcı Sayısı', '$recipientCount çiftçi'),
          _buildSummaryRow('Kod Sayısı', '$recipientCount kod (her çiftçiye 1 kod)'),
          _buildSummaryRow('Kanal', _selectedChannel == MessageChannel.sms ? 'SMS' : 'WhatsApp'),
          _buildSummaryRow('Paket', _selectedPackage!.displayName),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF065F46),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF065F46),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSend() {
    if (_selectedPackage == null) return false;
    final recipients = _packageRecipients[_selectedPackage!.purchaseId];
    return recipients != null && recipients.isNotEmpty && !_isSending;
  }

  void _removeRecipient(CodeRecipient recipient) {
    if (_selectedPackage == null) return;

    setState(() {
      _packageRecipients[_selectedPackage!.purchaseId]?.remove(recipient);
      if (_packageRecipients[_selectedPackage!.purchaseId]?.isEmpty ?? false) {
        _packageRecipients.remove(_selectedPackage!.purchaseId);
      }
    });
  }

  Future<void> _pickContactsFromPhone() async {
    if (_selectedPackage == null) {
      _showMessage('Lütfen önce paket seçin', isError: true);
      return;
    }

    if (!await _permissionService.requestContactsPermission()) {
      _showMessage('Rehber izni gerekli', isError: true);
      return;
    }

    try {
      final contacts = await FlutterContacts.getContacts(withProperties: true);
      if (!mounted) return;

      final selectedContacts = await showDialog<List<Contact>>(
        context: context,
        builder: (context) => _buildContactPickerDialog(contacts),
      );

      if (selectedContacts != null && selectedContacts.isNotEmpty) {
        setState(() {
          final currentRecipients = _packageRecipients[_selectedPackage!.purchaseId] ?? [];

          for (var contact in selectedContacts) {
            if (contact.phones.isNotEmpty) {
              final phone = contact.phones.first.number.replaceAll(RegExp(r'\s+'), '');

              if (!currentRecipients.any((r) => r.phone == phone)) {
                currentRecipients.add(CodeRecipient(
                  name: contact.displayName,
                  phone: phone,
                ));
              }
            }
          }

          _packageRecipients[_selectedPackage!.purchaseId] = currentRecipients;
        });
      }
    } catch (e) {
      _showMessage('Rehber okuma hatası: $e', isError: true);
    }
  }

  Widget _buildContactPickerDialog(List<Contact> contacts) {
    final List<Contact> selectedContacts = [];

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Rehberden Seç'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final isSelected = selectedContacts.contains(contact);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        selectedContacts.add(contact);
                      } else {
                        selectedContacts.remove(contact);
                      }
                    });
                  },
                  title: Text(contact.displayName),
                  subtitle: Text(
                    contact.phones.isNotEmpty
                        ? contact.phones.first.number
                        : 'Telefon yok',
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedContacts),
              child: Text('Seç (${selectedContacts.length})'),
            ),
          ],
        );
      },
    );
  }

  void _showAddRecipientDialog() {
    if (_selectedPackage == null) {
      _showMessage('Lütfen önce paket seçin', isError: true);
      return;
    }

    showDialog<CodeRecipient>(
      context: context,
      builder: (context) => const AddRecipientDialog(),
    ).then((recipient) {
      if (recipient != null) {
        setState(() {
          final currentRecipients = _packageRecipients[_selectedPackage!.purchaseId] ?? [];

          if (!currentRecipients.any((r) => r.phone == recipient.phone)) {
            currentRecipients.add(recipient);
            _packageRecipients[_selectedPackage!.purchaseId] = currentRecipients;
          }
        });
      }
    });
  }

  Future<void> _sendInvitations() async {
    if (!_canSend()) return;

    final recipients = _packageRecipients[_selectedPackage!.purchaseId]!;

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Davetiye Gönder'),
        content: Text(
          '${recipients.length} çiftçiye davetiye göndermek istediğinizden emin misiniz?\n\n'
          'Her çiftçiye 1 kod tahsis edilecek ve deep link SMS/WhatsApp ile gönderilecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSending = true);

    try {
      int successCount = 0;
      int failCount = 0;

      for (var recipient in recipients) {
        try {
          // Normalize phone number to Turkish format with +90 prefix
          String normalizedPhone = recipient.phone.replaceAll(RegExp(r'\s+'), '');
          if (normalizedPhone.startsWith('0')) {
            normalizedPhone = '+90${normalizedPhone.substring(1)}';
          } else if (!normalizedPhone.startsWith('+')) {
            normalizedPhone = '+90$normalizedPhone';
          }

          await _farmerInvitationService.createInvitation(
            CreateFarmerInvitationRequest(
              recipientPhone: normalizedPhone,
              codeCount: 1, // Always 1 code per farmer
              sendViaSms: _selectedChannel == MessageChannel.sms,
            ),
          );
          successCount++;
        } catch (e) {
          print('Failed to send invitation to ${recipient.phone}: $e');
          failCount++;
        }
      }

      if (mounted) {
        setState(() => _isSending = false);

        // Show result
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  successCount > 0 ? Icons.check_circle : Icons.error,
                  color: successCount > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                const Text('Gönderim Tamamlandı'),
              ],
            ),
            content: Text(
              'Başarılı: $successCount\n'
              'Başarısız: $failCount\n\n'
              'Çiftçiler deep link ile davetiyeyi kabul edecek.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Return to dashboard
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );

        // Clear recipients
        if (_selectedPackage != null) {
          setState(() {
            _packageRecipients.remove(_selectedPackage!.purchaseId);
          });
        }

        // Reload codes
        _loadCodes();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        _showMessage('Gönderim hatası: $e', isError: true);
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
