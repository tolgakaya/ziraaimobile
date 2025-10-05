import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
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
    bool isValid = RegExp(r'^\+90[1-9]\d{9}$').hasMatch(cleanPhone) ||
                   RegExp(r'^05\d{9}$').hasMatch(cleanPhone);

    if (!isValid) {
      return 'Geçersiz format';
    }
    return null;
  }

  void _generateLink() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get non-empty phone numbers
    final phoneNumbers = _phoneControllers
        .map((c) => c.text.trim())
        .where((phone) => phone.isNotEmpty)
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
            String phone = contact.phones.first.number.replaceAll(RegExp(r'[\s\-\(\)]'), '');

            setState(() {
              _addPhoneField();
              _phoneControllers.last.text = phone;
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
      appBar: AppBar(
        title: const Text('Davet Linki Oluştur'),
        centerTitle: true,
      ),
      body: BlocConsumer<ReferralBloc, ReferralState>(
        listener: (context, state) {
          if (state is ReferralLinkGenerated) {
            // Show success message and navigate back
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Davet linki oluşturuldu ve ${state.linkData.deliveryStatuses.length} kişiye gönderildi'),
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
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Arkadaşlarınıza davet linki gönderin. Kayıt olduklarında ikimiz de kredi kazanın!',
                              style: TextStyle(color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Delivery method selection
                  Text(
                    'Gönderim Yöntemi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                      Text(
                        'Telefon Numaraları',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
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
                            child: TextFormField(
                              controller: controller,
                              keyboardType: TextInputType.phone,
                              enabled: !isLoading,
                              decoration: InputDecoration(
                                labelText: 'Telefon ${index + 1}',
                                hintText: '+90 5XX XXX XX XX',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                  TextFormField(
                    controller: _messageController,
                    maxLines: 3,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'Özel Mesaj (İsteğe Bağlı)',
                      hintText: 'Arkadaşlarınıza özel bir mesaj ekleyin...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Bu mesaj gönderilen davetlere eklenecek',
                    ),
                    maxLength: 200,
                  ),

                  const SizedBox(height: 32),

                  // Generate button
                  ElevatedButton.icon(
                    onPressed: isLoading ? null : _generateLink,
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(isLoading ? 'Gönderiliyor...' : 'Oluştur ve Gönder'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
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
                Text(
                  'Kişi Seç',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
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
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_selectedContacts.length} kişi seçildi',
                  style: TextStyle(
                    color: Colors.green[700],
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
                ElevatedButton(
                  onPressed: _selectedContacts.isEmpty
                      ? null
                      : () {
                          Navigator.of(context).pop(_selectedContacts.toList());
                        },
                  child: Text('Ekle (${_selectedContacts.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
