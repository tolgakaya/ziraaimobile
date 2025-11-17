import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/widgets/farmer_bottom_nav.dart';
import '../bloc/referral_bloc.dart';
import '../bloc/referral_event.dart';
import '../bloc/referral_state.dart';
import '../../data/models/referral_generate_request.dart';

class ReferralLinkGenerationScreen extends StatefulWidget {
  const ReferralLinkGenerationScreen({super.key});

  @override
  State<ReferralLinkGenerationScreen> createState() => _ReferralLinkGenerationScreenState();
}

class _ReferralLinkGenerationScreenState extends State<ReferralLinkGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _phoneControllers = [TextEditingController()];
  final _messageController = TextEditingController();

  DeliveryMethod _selectedMethod = DeliveryMethod.both;

  @override
  void dispose() {
    for (var controller in _phoneControllers) {
      controller.dispose();
    }
    _messageController.dispose();
    super.dispose();
  }

  void _addPhoneField() {
    if (_phoneControllers.length < 10) {
      // Son textbox boş değilse yeni ekle
      if (_phoneControllers.isEmpty || _phoneControllers.last.text.trim().isNotEmpty) {
        setState(() {
          _phoneControllers.add(TextEditingController());
        });
      } else {
        // Son textbox boşsa uyar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lütfen önce mevcut telefon numarasını doldurun'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _removePhoneField(int index) {
    if (_phoneControllers.length > 1) {
      setState(() {
        _phoneControllers[index].dispose();
        _phoneControllers.removeAt(index);
      });
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final cleanPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Accept three formats:
    // 1. +905XXXXXXXXX (with country code)
    // 2. 05XXXXXXXXX (with leading 0)
    // 3. 5XXXXXXXXX (without leading 0)
    bool isValid = RegExp(r'^\+90[5]\d{9}$').hasMatch(cleanPhone) ||
                   RegExp(r'^0[5]\d{9}$').hasMatch(cleanPhone) ||
                   RegExp(r'^[5]\d{9}$').hasMatch(cleanPhone);

    if (!isValid) {
      return 'Geçersiz format';
    }
    return null;
  }

  /// Normalize phone number to 05XXXXXXXXX format for API
  String _normalizePhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // If starts with +90, remove it and ensure it starts with 0
    if (cleanPhone.startsWith('+90')) {
      final withoutCountryCode = cleanPhone.substring(3);
      return withoutCountryCode.startsWith('0') ? withoutCountryCode : '0$withoutCountryCode';
    }

    // If starts with 0, keep as is
    if (cleanPhone.startsWith('0')) {
      return cleanPhone;
    }

    // If starts with 5, add 0 prefix
    return '0$cleanPhone';
  }

  void _generateLink() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get non-empty phone numbers and normalize them to 05XXXXXXXXX format
    final phoneNumbers = _phoneControllers
        .map((c) => c.text.trim())
        .where((phone) => phone.isNotEmpty)
        .map((phone) => _normalizePhone(phone))
        .toList();

    if (phoneNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('En az bir telefon numarası girin'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    context.read<ReferralBloc>().add(
      GenerateReferralLinkRequested(
        phoneNumbers: phoneNumbers,
        deliveryMethod: _selectedMethod.value,
        customMessage: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      ),
    );
  }

  Future<void> _pickContactsFromPhone() async {
    final permissionStatus = await Permission.contacts.status;

    if (permissionStatus.isDenied) {
      final result = await Permission.contacts.request();
      if (!result.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rehber erişimi için izin gerekli'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      final contactsWithPhones = contacts.where((contact) => contact.phones.isNotEmpty).toList();

      if (!mounted) return;

      final selectedContacts = await showDialog<List<Contact>>(
        context: context,
        builder: (context) => _ContactSelectionDialog(contacts: contactsWithPhones),
      );

      if (selectedContacts != null && selectedContacts.isNotEmpty) {
        for (var contact in selectedContacts) {
          if (contact.phones.isNotEmpty) {
            // Clean phone number and normalize to 05XXXXXXXXX format
            String phone = contact.phones.first.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');
            String normalizedPhone = _normalizePhone(phone);

            setState(() {
              _addPhoneField();
              _phoneControllers.last.text = normalizedPhone;
            });
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${selectedContacts.length} kişi eklendi'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rehber erişim hatası: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Davet Et Kredi Kazan',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ReferralBloc, ReferralState>(
        listener: (context, state) {
          if (state is ReferralLinkGenerated) {
            // Calculate unique phone numbers (since both SMS + WhatsApp creates 2 statuses per phone)
            final uniquePhones = state.linkData.deliveryStatuses
                .map((d) => d.phoneNumber)
                .toSet()
                .length;

            // Show success message and navigate back
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Davet gönderildi! $uniquePhones kişiye ulaştı'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.of(context).pop();
          } else if (state is ReferralError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ReferralLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info card
                  Card(
                    color: const Color(0xFFF0FDF4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF17CF17)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Arkadaşlarınıza davet linki gönderin. Kayıt olduklarında ikimiz de kredi kazanın!',
                              style: const TextStyle(color: Color(0xFF111827)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delivery method selection
                  const Text(
                    'Gönderim Yöntemi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),

                  SegmentedButton<DeliveryMethod>(
                    segments: const [
                      ButtonSegment(
                        value: DeliveryMethod.sms,
                        label: Text('SMS'),
                        icon: Icon(Icons.message),
                      ),
                      ButtonSegment(
                        value: DeliveryMethod.whatsApp,
                        label: Text('WhatsApp'),
                        icon: Icon(Icons.chat),
                      ),
                      ButtonSegment(
                        value: DeliveryMethod.both,
                        label: Text('İkisi'),
                        icon: Icon(Icons.all_inclusive),
                      ),
                    ],
                    selected: {_selectedMethod},
                    onSelectionChanged: (Set<DeliveryMethod> selected) {
                      setState(() {
                        _selectedMethod = selected.first;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Phone numbers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Telefon Numaraları',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: isLoading ? null : _pickContactsFromPhone,
                            icon: const Icon(Icons.contacts),
                            label: const Text('Rehber'),
                          ),
                          TextButton.icon(
                            onPressed: _phoneControllers.length >= 10 ? null : _addPhoneField,
                            icon: const Icon(Icons.add),
                            label: const Text('Ekle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  ..._phoneControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: TextFormField(
                                controller: controller,
                                keyboardType: TextInputType.phone,
                                enabled: !isLoading,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFF111827),
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Telefon ${index + 1}',
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                  hintText: '05XX XXX XX XX',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF6B7280),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.phone,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: _validatePhone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9+\s\-\(\)]'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_phoneControllers.length > 1) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: isLoading ? null : () => _removePhoneField(index),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: Colors.red,
                            ),
                          ],
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Custom message (optional)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextFormField(
                      controller: _messageController,
                      maxLines: 3,
                      enabled: !isLoading,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Özel Mesaj (İsteğe Bağlı)',
                        labelStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                        hintText: 'Arkadaşlarınıza özel bir mesaj ekleyin...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        helperText: 'Bu mesaj gönderilen davetlere eklenecek',
                        helperStyle: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      maxLength: 200,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Generate button
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF17CF17),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF17CF17).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: isLoading ? null : _generateLink,
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                const Icon(Icons.send, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                isLoading ? 'Gönderiliyor...' : 'Davet Gönder',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const FarmerBottomNav(currentIndex: 2), // Davet Et sekmesi
    );
  }

}

// Contact Selection Dialog Widget
class _ContactSelectionDialog extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactSelectionDialog({required this.contacts});

  @override
  State<_ContactSelectionDialog> createState() => _ContactSelectionDialogState();
}

class _ContactSelectionDialogState extends State<_ContactSelectionDialog> {
  final Set<Contact> _selectedContacts = {};
  String _searchQuery = '';

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) return widget.contacts;
    
    return widget.contacts.where((contact) {
      final name = contact.displayName.toLowerCase();
      final phones = contact.phones.map((p) => p.number).join(' ');
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phones.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredContacts = _filteredContacts;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            if (_selectedContacts.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedContacts.length} kişi seçildi',
                  style: const TextStyle(
                    color: Color(0xFF17CF17),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: filteredContacts.isEmpty
                  ? const Center(child: Text('Kişi bulunamadı'))
                  : ListView.builder(
                      itemCount: filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = filteredContacts[index];
                        final isSelected = _selectedContacts.contains(contact);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                _selectedContacts.add(contact);
                              } else {
                                _selectedContacts.remove(contact);
                              }
                            });
                          },
                          title: Text(contact.displayName),
                          subtitle: contact.phones.isNotEmpty
                              ? Text(contact.phones.first.number)
                              : null,
                          secondary: CircleAvatar(
                            child: Text(
                              contact.displayName.isNotEmpty
                                  ? contact.displayName[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _selectedContacts.isEmpty
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF17CF17),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _selectedContacts.isEmpty
                          ? null
                          : () {
                              Navigator.of(context).pop(_selectedContacts.toList());
                            },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Ekle (${_selectedContacts.length})',
                            style: TextStyle(
                              color: _selectedContacts.isEmpty
                                  ? const Color(0xFF9CA3AF)
                                  : Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
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
