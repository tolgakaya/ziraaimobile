import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/services/sponsor_service.dart';
import '../../data/models/sponsor_profile.dart';
import 'edit_sponsor_profile_screen.dart';

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
            _buildStatsSection(),
          ],
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

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.analytics, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text(
                  'İstatistikler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Toplam Alım',
                    _profile!.totalPurchases.toString(),
                    Icons.shopping_cart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Oluşturulan Kod',
                    _profile!.totalCodesGenerated.toString(),
                    Icons.qr_code,
                  ),
                ),
              ],
            ),
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

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16A34A).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF16A34A).withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: const Color(0xFF16A34A)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
