import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../bloc/farmer_profile_bloc.dart';
import '../bloc/farmer_profile_event.dart';
import '../bloc/farmer_profile_state.dart';
import '../../domain/entities/farmer_profile.dart';
import '../../../../core/widgets/farmer_bottom_nav.dart';
import 'package:intl/intl.dart';
import '../../../support/presentation/screens/support_ticket_list_screen.dart';
import '../../../support/presentation/screens/about_screen.dart';
import '../../../authentication/presentation/screens/login_screen.dart';

/// Farmer Profile Screen
/// Displays and allows editing of farmer profile information
class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  bool _isEditMode = false;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobilePhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedBirthDate;
  int? _selectedGender;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobilePhoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateForm(FarmerProfile profile) {
    _fullNameController.text = profile.fullName;
    _emailController.text = profile.email;
    _mobilePhoneController.text = profile.mobilePhones;
    _addressController.text = profile.address ?? '';
    _notesController.text = profile.notes ?? '';
    _selectedBirthDate = profile.birthDate;
    _selectedGender = profile.gender;
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
    });
  }

  void _saveProfile(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      // Trigger update event
      context.read<FarmerProfileBloc>().add(
            UpdateFarmerProfile(
              fullName: _fullNameController.text.trim(),
              email: _emailController.text.trim(),
              mobilePhones: _mobilePhoneController.text.trim(),
              birthDate: _selectedBirthDate,
              gender: _selectedGender,
              address: _addressController.text.trim().isEmpty
                  ? null
                  : _addressController.text.trim(),
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
            ),
          );
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('tr', 'TR'),
    );

    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<FarmerProfileBloc>()
        ..add(const LoadFarmerProfile()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Profilim'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
          actions: [
            BlocBuilder<FarmerProfileBloc, FarmerProfileState>(
              builder: (context, state) {
                if (state is FarmerProfileLoaded ||
                    state is FarmerProfileUpdateSuccess) {
                  return IconButton(
                    icon: Icon(_isEditMode ? Icons.close : Icons.edit),
                    onPressed: () {
                      if (_isEditMode) {
                        // Cancel edit - reload profile
                        context
                            .read<FarmerProfileBloc>()
                            .add(const LoadFarmerProfile());
                      }
                      _toggleEditMode();
                    },
                    tooltip: _isEditMode ? 'İptal' : 'Düzenle',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<FarmerProfileBloc, FarmerProfileState>(
          listener: (context, state) {
            if (state is FarmerProfileUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green.shade600,
                ),
              );
              setState(() {
                _isEditMode = false;
              });
            } else if (state is FarmerProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red.shade600,
                ),
              );
            } else if (state is FarmerProfileLoaded) {
              _populateForm(state.profile);
            }
          },
          builder: (context, state) {
            if (state is FarmerProfileLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state is FarmerProfileError && state.currentProfile == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      state.message,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context
                            .read<FarmerProfileBloc>()
                            .add(const LoadFarmerProfile());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              );
            }

            final profile = (state is FarmerProfileLoaded)
                ? state.profile
                : (state is FarmerProfileUpdateSuccess)
                    ? state.profile
                    : (state is FarmerProfileUpdating)
                        ? state.currentProfile
                        : (state is FarmerProfileError)
                            ? state.currentProfile
                            : null;

            if (profile == null) {
              return const Center(child: Text('Profil bilgisi bulunamadı'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Section
                    _buildAvatarSection(profile),
                    const SizedBox(height: 24),

                    // Personal Information
                    _buildSectionTitle('Kişisel Bilgiler'),
                    const SizedBox(height: 12),
                    _buildPersonalInfoCard(profile),

                    const SizedBox(height: 24),

                    // Contact Information
                    _buildSectionTitle('İletişim Bilgileri'),
                    const SizedBox(height: 12),
                    _buildContactInfoCard(profile),

                    const SizedBox(height: 24),

                    // Additional Information
                    _buildSectionTitle('Ek Bilgiler'),
                    const SizedBox(height: 12),
                    _buildAdditionalInfoCard(profile),

                    const SizedBox(height: 24),

                    // Save Button (visible only in edit mode)
                    if (_isEditMode) _buildSaveButton(context, state),

                    const SizedBox(height: 24),

                    // Support and Info Section
                    _buildSectionTitle('Destek ve Bilgi'),
                    const SizedBox(height: 12),
                    _buildSupportInfoCard(context),

                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: const FarmerBottomNav(currentIndex: 0),
      ),
    );
  }

  Widget _buildAvatarSection(FarmerProfile profile) {
    return Center(
      child: Stack(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: const Color(0xFF059669),
            backgroundImage:
                profile.hasAvatar ? NetworkImage(profile.avatarUrl!) : null,
            child: !profile.hasAvatar
                ? Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName[0].toUpperCase()
                        : 'F',
                    style: const TextStyle(fontSize: 48, color: Colors.white),
                  )
                : null,
          ),
          if (_isEditMode)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF059669),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement avatar upload
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Avatar upload coming soon...'),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _buildPersonalInfoCard(FarmerProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
              controller: _fullNameController,
              label: 'Ad Soyad',
              icon: Icons.person,
              enabled: _isEditMode,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ad Soyad gereklidir';
                }
                if (value.trim().length < 2) {
                  return 'Ad Soyad en az 2 karakter olmalıdır';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildDateField(
              label: 'Doğum Tarihi',
              icon: Icons.cake,
              date: _selectedBirthDate,
              onTap: _isEditMode ? () => _selectBirthDate(context) : null,
            ),
            const SizedBox(height: 16),
            _buildGenderField(),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard(FarmerProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
              controller: _emailController,
              label: 'E-posta',
              icon: Icons.email,
              enabled: _isEditMode,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'E-posta gereklidir';
                }
                if (!value.contains('@')) {
                  return 'Geçerli bir e-posta adresi giriniz';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _mobilePhoneController,
              label: 'Telefon',
              icon: Icons.phone,
              enabled: _isEditMode,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Telefon numarası gereklidir';
                }
                if (value.trim().length < 10) {
                  return 'Telefon numarası en az 10 karakter olmalıdır';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _addressController,
              label: 'Adres',
              icon: Icons.location_on,
              enabled: _isEditMode,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard(FarmerProfile profile) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
              controller: _notesController,
              label: 'Notlar',
              icon: Icons.notes,
              enabled: _isEditMode,
              maxLines: 4,
            ),
            if (!_isEditMode) ...[
              const SizedBox(height: 16),
              _buildInfoRow('Kayıt Tarihi',
                  DateFormat('dd/MM/yyyy HH:mm').format(profile.recordDate)),
              if (profile.updateContactDate != null) ...[
                const SizedBox(height: 8),
                _buildInfoRow('Son Güncelleme',
                    DateFormat('dd/MM/yyyy HH:mm').format(profile.updateContactDate!)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF059669)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !enabled,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required DateTime? date,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF059669)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: onTap == null,
          fillColor: onTap != null ? Colors.white : Colors.grey.shade100,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? DateFormat('dd/MM/yyyy').format(date)
                  : 'Belirtilmemiş',
              style: TextStyle(
                color: date != null ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            if (onTap != null)
              const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<int>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Cinsiyet',
        prefixIcon: const Icon(Icons.wc, color: Color(0xFF059669)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: !_isEditMode,
        fillColor: _isEditMode ? Colors.white : Colors.grey.shade100,
      ),
      items: const [
        DropdownMenuItem(value: null, child: Text('Belirtilmemiş')),
        DropdownMenuItem(value: 1, child: Text('Erkek')),
        DropdownMenuItem(value: 2, child: Text('Kadın')),
      ],
      onChanged: _isEditMode
          ? (value) {
              setState(() {
                _selectedGender = value;
              });
            }
          : null,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton(BuildContext context, FarmerProfileState state) {
    final isUpdating = state is FarmerProfileUpdating;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isUpdating ? null : () => _saveProfile(context),
        icon: isUpdating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.save),
        label: Text(isUpdating ? 'Kaydediliyor...' : 'Kaydet'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportInfoCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Support Tickets
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Color(0xFF059669),
              ),
            ),
            title: const Text(
              'Destek Talepleri',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Yardım alın ve taleplerinizi takip edin'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SupportTicketListScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          // About
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Color(0xFF3B82F6),
              ),
            ),
            title: const Text(
              'Hakkımızda',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: const Text('Uygulama ve şirket bilgileri'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          // Logout
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.red,
              ),
            ),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear auth and navigate to login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }
}
