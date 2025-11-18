import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// About Screen
/// Displays app and company information
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // App Logo & Version
            _buildAppInfoCard(),
            const SizedBox(height: 16),
            // Company Info
            _buildCompanyInfoCard(),
            const SizedBox(height: 16),
            // Contact Info
            _buildContactCard(context),
            const SizedBox(height: 16),
            // Legal Links
            _buildLegalCard(context),
            const SizedBox(height: 16),
            // Social Media
            _buildSocialMediaCard(context),
            const SizedBox(height: 32),
            // Copyright
            _buildCopyright(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // App Logo
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF059669),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.eco,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ZiraAI',
              style: TextStyle(
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
              child: const Text(
                'Versiyon 1.0.0',
                style: TextStyle(
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

  Widget _buildCompanyInfoCard() {
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
              'ZiraAI, yapay zeka teknolojilerini kullanarak tarım sektörüne '
              'yenilikçi çözümler sunan bir teknoloji şirketidir. Amacımız, '
              'çiftçilerin daha verimli ve sürdürülebilir tarım yapmasına '
              'yardımcı olmaktır.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.location_on,
              'Adres',
              'İstanbul, Türkiye',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
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
            _buildContactItem(
              context,
              Icons.email,
              'E-posta',
              'destek@ziraai.com',
              () => _launchUrl('mailto:destek@ziraai.com'),
            ),
            const Divider(height: 24),
            _buildContactItem(
              context,
              Icons.phone,
              'Telefon',
              '+90 (212) 555 0000',
              () => _launchUrl('tel:+902125550000'),
            ),
            const Divider(height: 24),
            _buildContactItem(
              context,
              Icons.language,
              'Web Sitesi',
              'www.ziraai.com',
              () => _launchUrl('https://www.ziraai.com'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.description, color: Color(0xFF059669)),
            title: const Text('Kullanım Koşulları'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchUrl('https://www.ziraai.com/terms'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip, color: Color(0xFF059669)),
            title: const Text('Gizlilik Politikası'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchUrl('https://www.ziraai.com/privacy'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cookie, color: Color(0xFF059669)),
            title: const Text('Çerez Politikası'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _launchUrl('https://www.ziraai.com/cookies'),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialMediaCard(BuildContext context) {
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
              children: [
                _buildSocialButton(
                  Icons.facebook,
                  'Facebook',
                  Colors.blue.shade700,
                  () => _launchUrl('https://facebook.com/ziraai'),
                ),
                _buildSocialButton(
                  Icons.camera_alt,
                  'Instagram',
                  Colors.pink.shade600,
                  () => _launchUrl('https://instagram.com/ziraai'),
                ),
                _buildSocialButton(
                  Icons.play_circle_fill,
                  'YouTube',
                  Colors.red.shade600,
                  () => _launchUrl('https://youtube.com/@ziraai'),
                ),
              ],
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

  Widget _buildCopyright() {
    return Text(
      '© ${DateTime.now().year} ZiraAI. Tüm hakları saklıdır.',
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey.shade500,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 8),
        Column(
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
            ),
          ],
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
    return InkWell(
      onTap: onTap,
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
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.open_in_new,
            size: 16,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
