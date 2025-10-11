import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../data/models/sponsorship_code.dart';
import '../../data/models/code_package.dart';
import '../../data/models/code_recipient.dart';
import '../../data/models/send_link_response.dart';
import '../../data/services/sponsor_service.dart';
import '../widgets/package_selector_widget.dart';
import '../widgets/recipient_list_item.dart';
import '../widgets/add_recipient_dialog.dart';
import '../widgets/channel_selector_widget.dart';
import 'code_distribution_success_screen.dart';

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
  MessageChannel _selectedChannel = MessageChannel.sms; // SMS default

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
          // Set first package as default selection
          if (_packages.isNotEmpty) {
            _selectedPackage = _packages.first;
          }
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
        // Convert selected contacts to CodeRecipient
        final newRecipients = <CodeRecipient>[];

        for (final contact in selectedContacts) {
          if (contact.phones.isNotEmpty) {
            final phone = contact.phones.first.number;
            final name = contact.displayName;

            // Check if contact already added
            final exists = _recipients.any((r) =>
              CodeRecipient.normalizePhone(r.phone) == CodeRecipient.normalizePhone(phone)
            );

            if (!exists) {
              newRecipients.add(CodeRecipient(
                name: name,
                phone: phone,
              ));
            }
          }
        }

        if (newRecipients.isNotEmpty) {
          setState(() {
            _recipients.addAll(newRecipients);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${newRecipients.length} kişi eklendi'),
                backgroundColor: const Color(0xFF10B981),
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
