import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/referral_bloc.dart';
import '../bloc/referral_event.dart';
import '../bloc/referral_state.dart';
import 'referral_link_generation_screen.dart';

class ReferralDashboardScreen extends StatefulWidget {
  const ReferralDashboardScreen({super.key});

  @override
  State<ReferralDashboardScreen> createState() => _ReferralDashboardScreenState();
}

class _ReferralDashboardScreenState extends State<ReferralDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch all referral data on load
    context.read<ReferralBloc>().add(const FetchAllReferralDataRequested());
  }

  void _navigateToLinkGeneration() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ReferralBloc>(),
          child: const ReferralLinkGenerationScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arkadaşını Davet Et'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ReferralBloc>().add(const FetchAllReferralDataRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<ReferralBloc, ReferralState>(
        builder: (context, state) {
          if (state is ReferralLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is ReferralError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<ReferralBloc>().add(const FetchAllReferralDataRequested());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (state is ReferralDataLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<ReferralBloc>().add(const FetchAllReferralDataRequested());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Credits Summary Card
                    if (state.credits != null)
                      _buildCreditsCard(context, state.credits!),

                    const SizedBox(height: 16),

                    // Referral Stats Card
                    if (state.stats != null)
                      _buildStatsCard(context, state.stats!),

                    const SizedBox(height: 16),

                    // Generate Link Button
                    ElevatedButton.icon(
                      onPressed: _navigateToLinkGeneration,
                      icon: const Icon(Icons.share),
                      label: const Text('Yeni Davet Linki Oluştur'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Rewards History
                    if (state.rewards != null && state.rewards!.isNotEmpty) ...[
                      Text(
                        'Kazanç Geçmişi',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...state.rewards!.map((reward) => _buildRewardCard(context, reward)),
                    ] else ...[
                      const SizedBox(height: 32),
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.card_giftcard_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz kazanç yok',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Arkadaşlarınızı davet edin ve kredi kazanın!',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          // Initial state
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Arkadaşlarını davet et, kredi kazan!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _navigateToLinkGeneration,
                  icon: const Icon(Icons.share),
                  label: const Text('Davet Linki Oluştur'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreditsCard(BuildContext context, dynamic credits) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Kredi Bakiyesi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCreditStat(
                  context,
                  'Toplam Kazanılan',
                  credits.totalEarned.toString(),
                  Icons.trending_up,
                  Colors.green,
                ),
                _buildCreditStat(
                  context,
                  'Kullanılan',
                  credits.totalUsed.toString(),
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                _buildCreditStat(
                  context,
                  'Bakiye',
                  credits.currentBalance.toString(),
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, dynamic stats) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Davet İstatistikleri',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Toplam Davet', stats.totalReferrals.toString()),
            const Divider(),
            _buildStatRow('Başarılı', stats.successfulReferrals.toString(), color: Colors.green),
            const Divider(),
            _buildStatRow('Bekleyen', stats.pendingReferrals.toString(), color: Colors.orange),
            const Divider(),
            _buildStatRow('Toplam Kredi', stats.totalCreditsEarned.toString(), color: Colors.blue),
            const SizedBox(height: 16),
            // Conversion rates
            if (stats.referralBreakdown != null) ...[
              Text(
                'Dönüşüm Oranları',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatRow(
                'Tıklama → Kayıt',
                '${stats.clickToRegisterRate.toStringAsFixed(1)}%',
              ),
              _buildStatRow(
                'Kayıt → Ödül',
                '${stats.registerToRewardRate.toStringAsFixed(1)}%',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(BuildContext context, dynamic reward) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Icon(
            Icons.card_giftcard,
            color: Colors.green[700],
          ),
        ),
        title: Text(
          reward.refereeUserName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(reward.formattedDate),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '+${reward.creditAmount}',
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'kredi',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
