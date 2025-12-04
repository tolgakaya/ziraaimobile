import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get_it/get_it.dart';
import '../../data/services/app_info_api_service.dart';
import '../../data/models/app_info_dto.dart';

/// About Screen
/// Displays app and company information from API
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late Future<AppInfoDto> _appInfoFuture;
  final _appInfoService = GetIt.instance<AppInfoApiService>();

  @override
  void initState() {
    super.initState();
    _appInfoFuture = _appInfoService.getAppInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Hakkımızda'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
      ),
      body: FutureBuilder<AppInfoDto>(
        future: _appInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF059669),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bilgiler yüklenemedi',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _appInfoFuture = _appInfoService.getAppInfo();
                      });
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          final appInfo = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // App Logo & Version
                _buildAppInfoCard(appInfo),
                const SizedBox(height: 16),
                // Company Info
                _buildCompanyInfoCard(appInfo),
                const SizedBox(height: 16),
                // Contact Info
                if (appInfo.hasContactInfo) ...[
                  _buildContactCard(context, appInfo),
                  const SizedBox(height: 16),
                ],
                // Legal Links
                if (appInfo.hasLegalLinks) ...[
                  _buildLegalCard(context, appInfo),
                  const SizedBox(height: 16),
                ],
                // Social Media
                if (appInfo.hasSocialMedia) ...[
                  _buildSocialMediaCard(context, appInfo),
                  const SizedBox(height: 32),
                ],
                // Copyright
                _buildCopyright(appInfo),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppInfoCard(AppInfoDto appInfo) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App Logo
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/logos/ziraai_logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              appInfo.companyName ?? 'ZiraAI',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Yapay Zeka Destekli Tarım Asistanı',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF059669).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Versiyon ${appInfo.appVersion ?? '1.0.0'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard(AppInfoDto appInfo) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.business, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text(
                  'Şirket Bilgileri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              appInfo.companyDescription ??
                  'ZiraAI, yapay zeka teknolojilerini kullanarak tarım sektörüne '
                      'yenilikçi çözümler sunan bir teknoloji şirketidir.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            if (appInfo.address != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.location_on,
                'Adres',
                appInfo.address!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, AppInfoDto appInfo) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.contact_mail, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text(
                  'İletişim',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (appInfo.email != null) ...[
              _buildContactItem(
                context,
                Icons.email,
                'E-posta',
                appInfo.email!,
                () => _launchUrl('mailto:${appInfo.email}'),
              ),
              if (appInfo.phone != null || appInfo.websiteUrl != null)
                const Divider(height: 24),
            ],
            if (appInfo.phone != null) ...[
              _buildContactItem(
                context,
                Icons.phone,
                'Telefon',
                appInfo.phone!,
                () => _launchUrl('tel:${appInfo.phone?.replaceAll(' ', '').replaceAll('(', '').replaceAll(')', '')}'),
              ),
              if (appInfo.websiteUrl != null) const Divider(height: 24),
            ],
            if (appInfo.websiteUrl != null)
              _buildContactItem(
                context,
                Icons.language,
                'Web Sitesi',
                appInfo.websiteUrl!.replaceFirst('https://', '').replaceFirst('http://', ''),
                () => _launchUrl(appInfo.websiteUrl!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context, AppInfoDto appInfo) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          if (appInfo.termsOfServiceUrl != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchUrl(appInfo.termsOfServiceUrl!),
                child: ListTile(
                  leading: const Icon(Icons.description, color: Color(0xFF059669)),
                  title: const Text(
                    'Kullanım Koşulları',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ),
          if (appInfo.termsOfServiceUrl != null &&
              (appInfo.privacyPolicyUrl != null || appInfo.cookiePolicyUrl != null))
            const Divider(height: 1),
          if (appInfo.privacyPolicyUrl != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchUrl(appInfo.privacyPolicyUrl!),
                child: ListTile(
                  leading: const Icon(Icons.privacy_tip, color: Color(0xFF059669)),
                  title: const Text(
                    'Gizlilik Politikası',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ),
          if (appInfo.privacyPolicyUrl != null && appInfo.cookiePolicyUrl != null)
            const Divider(height: 1),
          if (appInfo.cookiePolicyUrl != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchUrl(appInfo.cookiePolicyUrl!),
                child: ListTile(
                  leading: const Icon(Icons.cookie, color: Color(0xFF059669)),
                  title: const Text(
                    'Çerez Politikası',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF059669),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaCard(BuildContext context, AppInfoDto appInfo) {
    final socialButtons = <Widget>[];

    if (appInfo.facebookUrl != null) {
      socialButtons.add(_buildSocialButton(
        Icons.facebook,
        'Facebook',
        Colors.blue.shade700,
        () => _launchUrl(appInfo.facebookUrl!),
      ));
    }
    if (appInfo.instagramUrl != null) {
      socialButtons.add(_buildSocialButton(
        Icons.camera_alt,
        'Instagram',
        Colors.pink.shade600,
        () => _launchUrl(appInfo.instagramUrl!),
      ));
    }
    if (appInfo.youTubeUrl != null) {
      socialButtons.add(_buildSocialButton(
        Icons.play_circle_fill,
        'YouTube',
        Colors.red.shade600,
        () => _launchUrl(appInfo.youTubeUrl!),
      ));
    }
    if (appInfo.twitterUrl != null) {
      socialButtons.add(_buildSocialButton(
        Icons.flutter_dash,
        'Twitter',
        Colors.blue.shade400,
        () => _launchUrl(appInfo.twitterUrl!),
      ));
    }
    if (appInfo.linkedInUrl != null) {
      socialButtons.add(_buildSocialButton(
        Icons.work,
        'LinkedIn',
        Colors.blue.shade800,
        () => _launchUrl(appInfo.linkedInUrl!),
      ));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.share, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text(
                  'Sosyal Medya',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: socialButtons,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyright(AppInfoDto appInfo) {
    return Text(
      '© ${DateTime.now().year} ${appInfo.companyName ?? 'ZiraAI'}. Tüm hakları saklıdır.',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF111827),
                ),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey.shade500),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF3B82F6),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.open_in_new,
                size: 18,
                color: const Color(0xFF3B82F6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      // Check if URL can be launched
      if (!await canLaunchUrl(uri)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bu bağlantı açılamıyor'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Launch URL with appropriate mode based on scheme
      final bool launched = await launchUrl(
        uri,
        mode: uri.scheme == 'tel' || uri.scheme == 'mailto'
            ? LaunchMode.externalApplication // For tel: and mailto:
            : LaunchMode.platformDefault, // For https:
      );

      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı açılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
