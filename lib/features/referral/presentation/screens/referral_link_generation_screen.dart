import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
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
      setState(() {
        _phoneControllers.add(TextEditingController());
      });
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

  void _shareLink(String link, String code) {
    final message = 'ZiraAI\'a katıl ve ücretsiz bitki analizi kazan! 🌱\n\n'
        'Davet Kodum: $code\n'
        'Link: $link\n\n'
        'Kayıt olduğunda ikimiz de kredi kazanıyoruz! 🎁';

    Share.share(message);
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopyalandı'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
            // Show success dialog with link
            _showLinkGeneratedDialog(context, state.linkData);
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
                      TextButton.icon(
                        onPressed: _phoneControllers.length >= 10 ? null : _addPhoneField,
                        icon: const Icon(Icons.add),
                        label: const Text('Ekle'),
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
                  }).toList(),

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

  void _showLinkGeneratedDialog(BuildContext context, dynamic linkData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 32),
            const SizedBox(width: 12),
            const Text('Link Oluşturuldu!'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Referral code
              Text(
                'Davet Kodunuz',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        linkData.referralCode,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(
                        linkData.referralCode,
                        'Davet kodu',
                      ),
                      tooltip: 'Kopyala',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Deep link
              Text(
                'Davet Linki',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        linkData.deepLink,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copyToClipboard(
                        linkData.deepLink,
                        'Link',
                      ),
                      tooltip: 'Kopyala',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Expiration
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Son Kullanma: ${linkData.expiresAt}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Delivery statuses
              if (linkData.deliveryStatuses != null &&
                  linkData.deliveryStatuses.isNotEmpty) ...[
                Text(
                  'Gönderim Durumu',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...linkData.deliveryStatuses.map<Widget>((status) {
                  final isSuccess = status.isSuccess;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          isSuccess ? Icons.check_circle : Icons.error,
                          color: isSuccess ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${status.phoneNumber} - ${status.method}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _shareLink(linkData.deepLink, linkData.referralCode);
              Navigator.of(dialogContext).pop();
            },
            icon: const Icon(Icons.share),
            label: const Text('Paylaş'),
          ),
        ],
      ),
    );
  }
}
