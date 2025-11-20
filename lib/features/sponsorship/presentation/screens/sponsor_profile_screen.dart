import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/services/sponsor_service.dart';
import '../../data/models/sponsor_profile.dart';
import 'edit_sponsor_profile_screen.dart';
import '../../../support/presentation/screens/support_ticket_list_screen.dart';
import '../../../support/presentation/screens/about_screen.dart';
import '../../../authentication/presentation/bloc/auth_bloc.dart';
import '../../../authentication/presentation/bloc/auth_event.dart';
import '../../../authentication/presentation/screens/login_screen.dart';
import '../../../../core/utils/minimal_service_locator.dart';

/// Sponsor profil görüntüleme ekranı
/// Tüm profil bilgilerini gösterir (basic, social media, business info)
class SponsorProfileScreen extends StatefulWidget {
  const SponsorProfileScreen({super.key});

  @override
  State<SponsorProfileScreen> createState() => _SponsorProfileScreenState();
}

class _SponsorProfileScreenState extends State<SponsorProfileScreen> {
  final SponsorService _sponsorService = GetIt.instance<SponsorService>();
  SponsorProfile? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profile = await _sponsorService.getProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToEdit() async {
    if (_profile == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSponsorProfileScreen(profile: _profile!),
      ),
    );

    // If profile was updated, reload
    if (result == true) {
      _loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (_profile != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _navigateToEdit,
              tooltip: 'Profili Düzenle',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Dene'),
            ),
          ],
        ),
      );
    }

    if (_profile == null) {
      return const Center(
        child: Text('Profil bulunamadı'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(),
            const SizedBox(height: 24),
            if (_profile!.hasSocialMedia) ...[
              _buildSocialMediaSection(),
              const SizedBox(height: 24),
            ],
            if (_profile!.hasBusinessInfo) ...[
              _buildBusinessInfoSection(),
              const SizedBox(height: 24),
            ],
            // Destek ve Bilgi Section
            _buildSupportAndInfoSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportAndInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Destek ve Bilgi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Destek Talepleri
              _buildMenuTile(
                icon: Icons.support_agent,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFF16A34A).withOpacity(0.1),
                title: 'Destek Talepleri',
                subtitle: 'Yardım alın ve taleplerinizi takip edin',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SupportTicketListScreen(),
                    ),
                  );
                },
              ),
              Divider(height: 1, indent: 72, color: Colors.grey.shade200),
              // Hakkımızda
              _buildMenuTile(
                icon: Icons.info_outline,
                iconColor: Colors.blue,
                iconBgColor: Colors.blue.withOpacity(0.1),
                title: 'Hakkımızda',
                subtitle: 'Uygulama ve şirket bilgileri',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                },
              ),
              Divider(height: 1, indent: 72, color: Colors.grey.shade200),
              // Çıkış Yap
              _buildMenuTile(
                icon: Icons.logout,
                iconColor: Colors.red,
                iconBgColor: Colors.red.withOpacity(0.1),
                title: 'Çıkış Yap',
                subtitle: null,
                showArrow: false,
                onTap: () {
                  _showLogoutConfirmation();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: title == 'Çıkış Yap' ? Colors.red : const Color(0xFF111827),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 22),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.eco,
                color: Color(0xFF16A34A),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text('ZiraAI'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yapay zeka destekli tarımsal analiz platformu',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _buildAboutRow('Versiyon', '1.0.0'),
            const SizedBox(height: 8),
            _buildAboutRow('Geliştirici', 'ZiraAI Team'),
            const SizedBox(height: 8),
            _buildAboutRow('İletişim', 'destek@ziraai.com'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Perform logout
              final authBloc = getIt<AuthBloc>();
              authBloc.add(const AuthLogoutRequested());
              // Navigate to login screen
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
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
              children: [
                const Icon(Icons.business, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                const Text(
                  'Temel Bilgiler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_profile!.isVerifiedCompany)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified, size: 16, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text(
                          'Doğrulanmış',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Şirket Adı', _profile!.companyName),
            if (_profile!.companyDescription != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Açıklama', _profile!.companyDescription!),
            ],
            if (_profile!.contactEmail != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('E-posta', _profile!.contactEmail!, icon: Icons.email),
            ],
            if (_profile!.contactPhone != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Telefon', _profile!.contactPhone!, icon: Icons.phone),
            ],
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_profile!.linkedInUrl != null)
              _buildSocialMediaLink('LinkedIn', _profile!.linkedInUrl!, Icons.link),
            if (_profile!.twitterUrl != null) ...[
              const SizedBox(height: 12),
              _buildSocialMediaLink('Twitter', _profile!.twitterUrl!, Icons.link),
            ],
            if (_profile!.facebookUrl != null) ...[
              const SizedBox(height: 12),
              _buildSocialMediaLink('Facebook', _profile!.facebookUrl!, Icons.link),
            ],
            if (_profile!.instagramUrl != null) ...[
              const SizedBox(height: 12),
              _buildSocialMediaLink('Instagram', _profile!.instagramUrl!, Icons.link),
            ],
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (_profile!.taxNumber != null)
              _buildInfoRow('Vergi No', _profile!.taxNumber!),
            if (_profile!.tradeRegistryNumber != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Ticaret Sicil No', _profile!.tradeRegistryNumber!),
            ],
            if (_profile!.address != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Adres', _profile!.address!, icon: Icons.location_on),
            ],
            if (_profile!.city != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Şehir', _profile!.city!),
            ],
            if (_profile!.country != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Ülke', _profile!.country!),
            ],
            if (_profile!.postalCode != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Posta Kodu', _profile!.postalCode!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaLink(String platform, String url, IconData icon) {
    return InkWell(
      onTap: () {
        // TODO: Open URL in browser
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$platform: $url')),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF16A34A)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    platform,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    url,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16A34A),
                      decoration: TextDecoration.underline,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
