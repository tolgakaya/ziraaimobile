import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/code_recipient.dart';

class AddRecipientDialog extends StatefulWidget {
  const AddRecipientDialog({super.key});

  @override
  State<AddRecipientDialog> createState() => _AddRecipientDialogState();
}

class _AddRecipientDialogState extends State<AddRecipientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Alıcı Ekle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'İsim Soyisim',
                  hintText: 'Ahmet Yılmaz',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Lütfen isim giriniz';
                  }
                  if (value.trim().length < 3) {
                    return 'İsim en az 3 karakter olmalı';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefon Numarası',
                  hintText: '5551234567',
                  helperText: 'Örnek: 5551234567 veya 05551234567',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  prefixText: '+90 ',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen telefon numarası giriniz';
                  }

                  final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');

                  if (cleaned.length != 10 && cleaned.length != 11) {
                    return 'Geçerli bir telefon numarası giriniz';
                  }

                  // Must start with 5 (mobile)
                  if (!cleaned.startsWith('5') &&
                      !cleaned.startsWith('05')) {
                    return 'Cep telefonu numarası 5 ile başlamalı';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'İptal',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _addRecipient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Ekle'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addRecipient() {
    if (_formKey.currentState!.validate()) {
      final recipient = CodeRecipient(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      Navigator.pop(context, recipient);
    }
  }
}
