import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/config/api_config.dart';
import '../../data/models/sponsored_analysis_summary.dart';
import '../../data/models/sponsored_analyses_list_response.dart';
import '../widgets/sponsored_analysis_card.dart';
import 'sponsored_analysis_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../dashboard/presentation/widgets/sponsor_bottom_navigation.dart';
import '../../../dashboard/presentation/pages/sponsor_dashboard_page.dart';
import '../../../dashboard/presentation/pages/farmer_dashboard_page.dart';
import 'sponsor_profile_screen.dart';
import '../../data/models/sponsor_dashboard_summary.dart';
import '../../data/services/sponsor_service.dart';

/// Sponsored Analyses List Screen
/// Shows paginated list of plant analyses from sponsored farmers
/// Follows farmer dashboard pattern (StatefulWidget + FutureBuilder)
class SponsoredAnalysesListScreen extends StatefulWidget {
  final String? initialFilter; // Optional initial filter: 'all', 'unread'

  const SponsoredAnalysesListScreen({
    super.key,
    this.initialFilter,
  });

  @override
  State<SponsoredAnalysesListScreen> createState() =>
      _SponsoredAnalysesListScreenState();
}

class _SponsoredAnalysesListScreenState
    extends State<SponsoredAnalysesListScreen> {
  final ScrollController _scrollController = ScrollController();
  final SponsorService _sponsorService = GetIt.instance<SponsorService>();

  // Pagination state
  int _currentPage = 1;
  final List<SponsoredAnalysisSummary> _allAnalyses = [];
  bool _isLoadingMore = false;
  bool _hasMorePages = true;
  SponsoredAnalysesListSummary? _summary;

  // Filter & sort state
  String _sortBy = 'date';
  String _sortOrder = 'desc';
  DateTime? _startDate;
  DateTime? _endDate;
  late String _selectedFilter; // all, unread

  // Navigation state
  late int _selectedIndex; // Will be set based on initialFilter
  SponsorDashboardSummary? _dashboardSummary; // For code distribution

  late Future<void> _initialLoadFuture;

  @override
  void initState() {
    super.initState();
    // Initialize filter from widget parameter or default to 'all'
    _selectedFilter = widget.initialFilter ?? 'all';
    // Set selectedIndex based on initialFilter
    // If coming from Mesajlar button (initialFilter='unread'), show Mesajlar tab active
    _selectedIndex = (_selectedFilter == 'unread') ? 2 : 1;
    // Removed scroll listener - using "Load More" button instead
    _initialLoadFuture = _loadAnalyses(refresh: true);
    _loadDashboardSummary(); // Load dashboard summary for code distribution
  }

  /// Load dashboard summary for code distribution
  Future<void> _loadDashboardSummary() async {
    try {
      final summary = await _sponsorService.getDashboardSummary();
      if (mounted) {
        setState(() {
          _dashboardSummary = summary;
        });
      }
    } catch (e) {
      print('⚠️ Failed to load dashboard summary: $e');
      // Don't show error to user, just log it
      // Code distribution button will be disabled if summary is null
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load analyses from API
  Future<void> _loadAnalyses({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _allAnalyses.clear();
        _hasMorePages = true;
      }

      if (!_hasMorePages || _isLoadingMore) return;

      if (mounted) {
        setState(() {
          _isLoadingMore = true;
        });
      }

      print('📊 Loading sponsored analyses - Page: $_currentPage');

      // Get network client and auth token
      final networkClient = GetIt.instance<NetworkClient>();
      final secureStorage = GetIt.instance<SecureStorageService>();
      final token = await secureStorage.getToken();

      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Build query parameters
      final queryParameters = <String, dynamic>{
        'page': _currentPage,
        'pageSize': 10,
        'sortBy': _sortBy,
        'sortOrder': _sortOrder,
      };

      // Add message status filter
      switch (_selectedFilter) {
        case 'unread':
          // Backend now supports hasUnreadForCurrentUser
          // For sponsor: shows analyses where farmer sent unread messages
          queryParameters['hasUnreadForCurrentUser'] = true;
          break;
        case 'all':
        default:
          // No filter - show all
          break;
      }

      if (_startDate != null) {
        queryParameters['startDate'] = _startDate!.toIso8601String();
      }

      if (_endDate != null) {
        queryParameters['endDate'] = _endDate!.toIso8601String();
      }

      // Make API call
      final response = await networkClient.get(
        ApiConfig.sponsoredAnalyses,
        queryParameters: queryParameters,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        // Debug: Print raw data structure
        print('📊 Raw response data keys: ${response.data['data'].keys}');
        print('📊 Items count: ${response.data['data']['items']?.length ?? 0}');
        if (response.data['data']['items'] != null && 
            response.data['data']['items'].isNotEmpty) {
          print('📊 First item full data: ${response.data['data']['items'][0]}');
        print('📊 imageUrl: ${response.data['data']['items'][0]['imageUrl']}');
        }
        print('📊 Has summary: ${response.data['data'].containsKey('summary')}');
        
        final responseData = SponsoredAnalysesListResponse.fromJson(
          response.data['data'],
        );

        if (mounted) {
          setState(() {
            _allAnalyses.addAll(responseData.items);

            // Smart sorting: Sort by urgency score (unread messages priority)
            // This puts analyses with unread messages from farmers at the top
            _allAnalyses.sort((a, b) => b.urgencyScore.compareTo(a.urgencyScore));

            _hasMorePages = responseData.hasNextPage;
            _summary = responseData.summary;
            _isLoadingMore = false;

            if (_hasMorePages) {
              _currentPage++;
            }
          });
        }

        print('✅ Loaded ${responseData.items.length} analyses, total: ${_allAnalyses.length}');
      } else {
        throw Exception(response.data['message'] ?? 'Failed to load analyses');
      }
    } catch (e) {
      print('❌ Error loading analyses: $e');
      
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getErrorMessage(e)),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.response?.statusCode) {
        case 401:
          return 'Oturum süreniz dolmuş. Lütfen tekrar giriş yapın.';
        case 403:
          return 'Bu işlem için yetkiniz bulunmamaktadır.';
        case 404:
          return 'Sponsor profili bulunamadı.';
        default:
          return 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.';
      }
    }
    return 'Beklenmeyen bir hata oluştu.';
  }

  /// Handle bottom navigation item taps
  void _onItemTapped(int index) {
    if (index == 0) {
      // Ana Sayfa - Navigate to Sponsor Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const SponsorDashboardPage(),
        ),
      );
    } else if (index == 1) {
      // Analizler - Reload current screen with all filter
      if (_selectedIndex == 1 && _selectedFilter == 'all') {
        // Already on Analizler with all filter, no need to reload
        return;
      }
      setState(() {
        _selectedFilter = 'all';
        _selectedIndex = 1; // ✅ Show Analizler tab as active
        _currentPage = 1;
        _allAnalyses.clear();
        _hasMorePages = true;
        _initialLoadFuture = _loadAnalyses(refresh: true);
      });
    } else if (index == 2) {
      // Mesajlar - Reload current screen with unread filter
      if (_selectedIndex == 2 && _selectedFilter == 'unread') {
        // Already on Mesajlar with unread filter, no need to reload
        return;
      }
      setState(() {
        _selectedFilter = 'unread';
        _selectedIndex = 2; // ✅ Show Mesajlar tab as active
        _currentPage = 1;
        _allAnalyses.clear();
        _hasMorePages = true;
        _initialLoadFuture = _loadAnalyses(refresh: true);
      });
    } else if (index == 3) {
      // Çiftçi - Navigate to Farmer Dashboard
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const FarmerDashboardPage(),
        ),
      ).then((_) {
        // Reset selection when returning
        setState(() {
          _selectedIndex = 1;
        });
      });
    } else if (index == 4) {
      // Profil - Navigate to Sponsor Profile Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SponsorProfileScreen(),
        ),
      ).then((_) {
        // Reset selection when returning
        setState(() {
          _selectedIndex = 1;
        });
      });
    }
  }

/// Show filter dialog with date range
  void _showFilterDialog() {
    // Store temporary dates to update UI in dialog
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Tarih Aralığı',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempStartDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('tr', 'TR'),
                    helpText: 'Başlangıç Tarihi Seçin',
                    cancelText: 'İptal',
                    confirmText: 'Seç',
                  );
                  if (picked != null) {
                    setDialogState(() => tempStartDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                           size: 20,
                           color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Başlangıç Tarihi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tempStartDate != null
                                  ? DateFormat('d MMMM yyyy', 'tr_TR').format(tempStartDate!)
                                  : 'Seçiniz',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (tempStartDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setDialogState(() => tempStartDate = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // End date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: tempEndDate ?? DateTime.now(),
                    firstDate: tempStartDate ?? DateTime(2020),
                    lastDate: DateTime.now(),
                    locale: const Locale('tr', 'TR'),
                    helpText: 'Bitiş Tarihi Seçin',
                    cancelText: 'İptal',
                    confirmText: 'Seç',
                  );
                  if (picked != null) {
                    setDialogState(() => tempEndDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today,
                           size: 20,
                           color: Colors.grey.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bitiş Tarihi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tempEndDate != null
                                  ? DateFormat('d MMMM yyyy', 'tr_TR').format(tempEndDate!)
                                  : 'Seçiniz',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (tempEndDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setDialogState(() => tempEndDate = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _startDate = tempStartDate;
                  _endDate = tempEndDate;
                  _initialLoadFuture = _loadAnalyses(refresh: true);
                });
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  /// Show sort dialog with modern UI
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.sort, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text(
              'Sıralama',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption(
              icon: Icons.priority_high,
              title: 'Önceliğe Göre (Okunmamış Mesajlar Üstte)',
              isSelected: _sortBy == 'urgency',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _sortBy = 'urgency';
                  _sortOrder = 'desc';
                  _initialLoadFuture = _loadAnalyses(refresh: true);
                });
              },
            ),
            const Divider(height: 1),
            _buildSortOption(
              icon: Icons.access_time,
              title: 'Tarihe Göre (Yeni → Eski)',
              isSelected: _sortBy == 'date' && _sortOrder == 'desc',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _sortBy = 'date';
                  _sortOrder = 'desc';
                  _initialLoadFuture = _loadAnalyses(refresh: true);
                });
              },
            ),
            _buildSortOption(
              icon: Icons.history,
              title: 'Tarihe Göre (Eski → Yeni)',
              isSelected: _sortBy == 'date' && _sortOrder == 'asc',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _sortBy = 'date';
                  _sortOrder = 'asc';
                  _initialLoadFuture = _loadAnalyses(refresh: true);
                });
              },
            ),
            const Divider(height: 1),
            _buildSortOption(
              icon: Icons.trending_up,
              title: 'Sağlık Skoru (Yüksek → Düşük)',
              isSelected: _sortBy == 'healthScore' && _sortOrder == 'desc',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _sortBy = 'healthScore';
                  _sortOrder = 'desc';
                  _initialLoadFuture = _loadAnalyses(refresh: true);
                });
              },
            ),
            _buildSortOption(
              icon: Icons.trending_down,
              title: 'Sağlık Skoru (Düşük → Yüksek)',
              isSelected: _sortBy == 'healthScore' && _sortOrder == 'asc',
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _sortBy = 'healthScore';
                  _sortOrder = 'asc';
                  _initialLoadFuture = _loadAnalyses(refresh: true);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build sort option with icon and selection indicator
  Widget _buildSortOption({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade600,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade800,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  /// Build filter chip widget
  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        setState(() {
          _initialLoadFuture = _loadAnalyses(refresh: true);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header with ZiraAI Logo (matches dashboard)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  // ZiraAI Logo (clickable - navigates to dashboard)
                  GestureDetector(
                    onTap: () {
                      // Navigate to Sponsor Dashboard
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SponsorDashboardPage(),
                        ),
                      );
                    },
                    child: Image.asset(
                      'assets/logos/ziraai_logo.png',
                      height: 90,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'ZiraAI',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            // Filter chips and actions section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('Tümü', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Okunmamış Mesajlar', 'unread'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Date range filter button
                  IconButton(
                    icon: const Icon(Icons.date_range),
                    onPressed: _showFilterDialog,
                    tooltip: 'Tarih Aralığı',
                    color: const Color(0xFF6B7280),
                  ),
                  // Sort button
                  IconButton(
                    icon: const Icon(Icons.sort),
                    onPressed: _showSortDialog,
                    tooltip: 'Sırala',
                    color: const Color(0xFF6B7280),
                  ),
                ],
              ),
            ),
            
            // Body content
            Expanded(
              child: FutureBuilder<void>(
        future: _initialLoadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _allAnalyses.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError && _allAnalyses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Bir hata oluştu',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(_getErrorMessage(snapshot.error)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _initialLoadFuture = _loadAnalyses(refresh: true);
                      });
                    },
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            );
          }

          if (_allAnalyses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz sponsorlu analiz yok',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Çiftçilere kod dağıttığınızda\nanalizler burada görünecek',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _loadAnalyses(refresh: true),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _allAnalyses.length + 1, // +1 for "Load More" button
              itemBuilder: (context, index) {
                // "Load More" button at bottom
                if (index == _allAnalyses.length) {
                  if (!_hasMorePages) {
                    return const Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          'Tüm analizler yüklendi',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: _isLoadingMore
                          ? const CircularProgressIndicator()
                          : FilledButton.icon(
                              onPressed: () => _loadAnalyses(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Daha Fazla Yükle'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                    ),
                  );
                }

                // Analysis card
                final analysis = _allAnalyses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SponsoredAnalysisCard(
                    analysis: analysis,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SponsoredAnalysisDetailScreen(
                            analysisId: analysis.analysisId,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
        ),
      ],
    ),
  ),
      bottomNavigationBar: SponsorBottomNavigation(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
