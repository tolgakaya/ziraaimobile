import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/services/sponsor_service.dart';
import '../../data/models/sponsor_profile.dart';
import '../../data/models/update_sponsor_profile_request.dart';

/// Sponsor profil düzenleme ekranı
/// Bölümler: Temel bilgiler, Sosyal medya, İşletme bilgileri
class EditSponsorProfileScreen extends StatefulWidget {
  final SponsorProfile profile;

  const EditSponsorProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  State<EditSponsorProfileScreen> createState() => _EditSponsorProfileScreenState();
}

class _EditSponsorProfileScreenState extends State<EditSponsorProfileScreen> {
  final SponsorService _sponsorService = GetIt.instance<SponsorService>();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Basic info controllers
  late TextEditingController _companyNameController;
  late TextEditingController _companyDescriptionController;
  late TextEditingController _contactEmailController;
  late TextEditingController _contactPhoneController;

  // Social media controllers
  late TextEditingController _linkedInController;
  late TextEditingController _twitterController;
  late TextEditingController _facebookController;
  late TextEditingController _instagramController;

  // Business info controllers
  late TextEditingController _taxNumberController;
  late TextEditingController _tradeRegistryController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _countryController;
  late TextEditingController _postalCodeController;

  // Password change
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _changePassword = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Basic info
    _companyNameController = TextEditingController(text: widget.profile.companyName);
    _companyDescriptionController = TextEditingController(text: widget.profile.companyDescription ?? '');
    _contactEmailController = TextEditingController(text: widget.profile.contactEmail ?? '');
    _contactPhoneController = TextEditingController(text: widget.profile.contactPhone ?? '');

    // Social media
    _linkedInController = TextEditingController(text: widget.profile.linkedInUrl ?? '');
    _twitterController = TextEditingController(text: widget.profile.twitterUrl ?? '');
    _facebookController = TextEditingController(text: widget.profile.facebookUrl ?? '');
    _instagramController = TextEditingController(text: widget.profile.instagramUrl ?? '');

    // Business info
    _taxNumberController = TextEditingController(text: widget.profile.taxNumber ?? '');
    _tradeRegistryController = TextEditingController(text: widget.profile.tradeRegistryNumber ?? '');
    _addressController = TextEditingController(text: widget.profile.address ?? '');
    _cityController = TextEditingController(text: widget.profile.city ?? '');
    _countryController = TextEditingController(text: widget.profile.country ?? '');
    _postalCodeController = TextEditingController(text: widget.profile.postalCode ?? '');

    // Password
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Add listeners to track changes
    _companyNameController.addListener(_onFieldChanged);
    _companyDescriptionController.addListener(_onFieldChanged);
    _contactEmailController.addListener(_onFieldChanged);
    _contactPhoneController.addListener(_onFieldChanged);
    _linkedInController.addListener(_onFieldChanged);
    _twitterController.addListener(_onFieldChanged);
    _facebookController.addListener(_onFieldChanged);
    _instagramController.addListener(_onFieldChanged);
    _taxNumberController.addListener(_onFieldChanged);
    _tradeRegistryController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _countryController.addListener(_onFieldChanged);
    _postalCodeController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyDescriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _linkedInController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _taxNumberController.dispose();
    _tradeRegistryController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if password fields match if changing password
    if (_changePassword) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Şifreler eşleşmiyor'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build update request with only changed fields
      final request = UpdateSponsorProfileRequest(
        companyName: _companyNameController.text != widget.profile.companyName
            ? _companyNameController.text
            : null,
        companyDescription: _companyDescriptionController.text != (widget.profile.companyDescription ?? '')
            ? (_companyDescriptionController.text.isEmpty ? null : _companyDescriptionController.text)
            : null,
        contactEmail: _contactEmailController.text != (widget.profile.contactEmail ?? '')
            ? (_contactEmailController.text.isEmpty ? null : _contactEmailController.text)
            : null,
        contactPhone: _contactPhoneController.text != (widget.profile.contactPhone ?? '')
            ? (_contactPhoneController.text.isEmpty ? null : _contactPhoneController.text)
            : null,
        linkedInUrl: _linkedInController.text != (widget.profile.linkedInUrl ?? '')
            ? (_linkedInController.text.isEmpty ? null : _linkedInController.text)
            : null,
        twitterUrl: _twitterController.text != (widget.profile.twitterUrl ?? '')
            ? (_twitterController.text.isEmpty ? null : _twitterController.text)
            : null,
        facebookUrl: _facebookController.text != (widget.profile.facebookUrl ?? '')
            ? (_facebookController.text.isEmpty ? null : _facebookController.text)
            : null,
        instagramUrl: _instagramController.text != (widget.profile.instagramUrl ?? '')
            ? (_instagramController.text.isEmpty ? null : _instagramController.text)
            : null,
        taxNumber: _taxNumberController.text != (widget.profile.taxNumber ?? '')
            ? (_taxNumberController.text.isEmpty ? null : _taxNumberController.text)
            : null,
        tradeRegistryNumber: _tradeRegistryController.text != (widget.profile.tradeRegistryNumber ?? '')
            ? (_tradeRegistryController.text.isEmpty ? null : _tradeRegistryController.text)
            : null,
        address: _addressController.text != (widget.profile.address ?? '')
            ? (_addressController.text.isEmpty ? null : _addressController.text)
            : null,
        city: _cityController.text != (widget.profile.city ?? '')
            ? (_cityController.text.isEmpty ? null : _cityController.text)
            : null,
        country: _countryController.text != (widget.profile.country ?? '')
            ? (_countryController.text.isEmpty ? null : _countryController.text)
            : null,
        postalCode: _postalCodeController.text != (widget.profile.postalCode ?? '')
            ? (_postalCodeController.text.isEmpty ? null : _postalCodeController.text)
            : null,
        password: _changePassword && _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      // Check if there are any changes
      if (request.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hiçbir değişiklik yapılmadı'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Update profile
      await _sponsorService.updateProfile(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profili Düzenle'),
        actions: [
          if (_hasChanges || _changePassword)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Kaydet',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 24),
              _buildSocialMediaSection(),
              const SizedBox(height: 24),
              _buildBusinessInfoSection(),
              const SizedBox(height: 24),
              _buildPasswordSection(),
              const SizedBox(height: 32),
              if (_hasChanges || _changePassword)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Değişiklikleri Kaydet',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.business, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text(
                  'Temel Bilgiler',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            TextFormField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: 'Şirket Adı *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Şirket adı gereklidir';
                }
                if (value.length < 2) {
                  return 'Şirket adı en az 2 karakter olmalıdır';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Şirket Açıklaması',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactEmailController,
              decoration: const InputDecoration(
                labelText: 'İletişim E-postası',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Geçerli bir e-posta adresi giriniz';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(
                labelText: 'İletişim Telefonu',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.share, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text(
                  'Sosyal Medya',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            TextFormField(
              controller: _linkedInController,
              decoration: const InputDecoration(
                labelText: 'LinkedIn URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: _urlValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _twitterController,
              decoration: const InputDecoration(
                labelText: 'Twitter URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: _urlValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _facebookController,
              decoration: const InputDecoration(
                labelText: 'Facebook URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: _urlValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _instagramController,
              decoration: const InputDecoration(
                labelText: 'Instagram URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              validator: _urlValidator,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.apartment, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text(
                  'İşletme Bilgileri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            TextFormField(
              controller: _taxNumberController,
              decoration: const InputDecoration(
                labelText: 'Vergi No',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tradeRegistryController,
              decoration: const InputDecoration(
                labelText: 'Ticaret Sicil No',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Adres',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Şehir',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _countryController,
              decoration: const InputDecoration(
                labelText: 'Ülke',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _postalCodeController,
              decoration: const InputDecoration(
                labelText: 'Posta Kodu',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                const Text(
                  'Şifre Değiştir',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _changePassword,
                  onChanged: (value) {
                    setState(() {
                      _changePassword = value;
                      if (!value) {
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                      }
                    });
                  },
                  activeColor: const Color(0xFF16A34A),
                ),
              ],
            ),
            if (_changePassword) ...[
              const Divider(height: 24),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (_changePassword && (value == null || value.isEmpty)) {
                    return 'Yeni şifre gereklidir';
                  }
                  if (value != null && value.length < 8) {
                    return 'Şifre en az 8 karakter olmalıdır';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (_changePassword && value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _urlValidator(String? value) {
    if (value != null && value.isNotEmpty) {
      final urlRegex = RegExp(
        r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
      );
      if (!urlRegex.hasMatch(value)) {
        return 'Geçerli bir URL giriniz (http:// veya https:// ile başlamalı)';
      }
    }
    return null;
  }
}
