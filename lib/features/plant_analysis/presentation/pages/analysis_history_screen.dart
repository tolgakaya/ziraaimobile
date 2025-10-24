import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/models/analysis_list_response.dart';
import '../../../../core/utils/minimal_service_locator.dart';
import '../../../../core/network/network_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/config/api_config.dart';
import '../screens/analysis_detail_screen.dart';
import '../../../dashboard/presentation/widgets/farmer_analysis_card.dart';
import '../../../dashboard/presentation/widgets/notification_bell_icon.dart';

/// Full analysis history screen with pagination and filtering
/// Accessed from Farmer Dashboard "Geçmiş" button
class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen> {
  final ScrollController _scrollController = ScrollController();
  
  List<AnalysisSummary> _analyses = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _pageSize = 20;
  
  String _selectedFilter = 'all'; // all, active, idle, unread
  String _selectedSort = 'date_desc'; // date_desc, date_asc, urgency

  @override
  void initState() {
    super.initState();
    _loadAnalyses();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMoreData) {
        _loadMoreAnalyses();
      }
    }
  }

  Future<void> _loadAnalyses({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _analyses = [];
        _hasMoreData = true;
      });
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final networkClient = getIt<NetworkClient>();
      final secureStorage = getIt<SecureStorageService>();
      final token = await secureStorage.getToken();

      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Build query parameters based on selected filter and sort
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'pageSize': _pageSize,
      };

      // Add backend filter parameters
      switch (_selectedFilter) {
        case 'active':
          queryParams['filterByMessageStatus'] = 'active';
          break;
        case 'idle':
          queryParams['filterByMessageStatus'] = 'idle';
          break;
        case 'unread':
          queryParams['hasUnreadMessages'] = true;
          break;
        case 'all':
        default:
          // No filter - backend returns all
          break;
      }

      // Add backend sort parameters
      switch (_selectedSort) {
        case 'urgency':
          queryParams['sortBy'] = 'unreadCount';
          queryParams['sortOrder'] = 'desc';
          break;
        case 'date_desc':
          queryParams['sortBy'] = 'date';
          queryParams['sortOrder'] = 'desc';
          break;
        case 'date_asc':
          queryParams['sortBy'] = 'date';
          queryParams['sortOrder'] = 'asc';
          break;
      }

      print('🔍 Loading analyses with params: $queryParams');

      final response = await networkClient.get(
        ApiConfig.plantAnalysesList,
        queryParameters: queryParams,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );

      if (response.data['success'] == true && response.data['data'] != null) {
        final analysisListResponse = AnalysisListResponse.fromJson(response.data);

        if (analysisListResponse.data != null) {
          final newAnalyses = analysisListResponse.data!.analyses;

          print('✅ Loaded ${newAnalyses.length} analyses from backend (already filtered & sorted)');

          setState(() {
            if (refresh) {
              _analyses = newAnalyses;
            } else {
              _analyses.addAll(newAnalyses);
            }
            _hasMoreData = newAnalyses.length >= _pageSize;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading analyses: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreAnalyses() async {
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    await _loadAnalyses();

    setState(() {
      _isLoadingMore = false;
    });
  }

  /// Reload data when filter or sort changes
  /// Backend handles all filtering and sorting now
  void _reloadWithNewFilters() {
    _loadAnalyses(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Column(
        children: [
          // Header with Logo, Bell Icon, and Back Button
          Container(
            decoration: const BoxDecoration(
              color: Color(0x80FFFFFF), // bg-white/80
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Logo (left side, like dashboard) - Clickable to go back to dashboard
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () {
                            // Pop until we reach the dashboard (first route)
                            Navigator.popUntil(context, (route) => route.isFirst);
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
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // Right side icons (Bell + Back Button)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Notification Bell Icon
                        const NotificationBellIcon(),
                        const SizedBox(width: 8),
                        // Back Button (where logout is on dashboard)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFF111827),
                              size: 24,
                            ),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Geri',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Filter and Sort Section
          _buildFilterSection(),
          
          // Analysis List
          Expanded(
            child: _isLoading && _analyses.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _analyses.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => _loadAnalyses(refresh: true),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _analyses.length + (_isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            if (index >= _analyses.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final analysis = _analyses[index];
                            return FarmerAnalysisCard(
                              analysis: analysis,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnalysisDetailScreen(
                                      analysisId: analysis.id,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Chips
          const Text(
            'Filtrele',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tümü', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Aktif Konuşmalar', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Pasif', 'idle'),
                const SizedBox(width: 8),
                _buildFilterChip('Okunmamış Mesajlar', 'unread'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Sort Dropdown
          Row(
            children: [
              const Text(
                'Sırala',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSort,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                      items: const [
                        DropdownMenuItem(
                          value: 'urgency',
                          child: Text('Öncelik (Okunmamış)'),
                        ),
                        DropdownMenuItem(
                          value: 'date_desc',
                          child: Text('En Yeni'),
                        ),
                        DropdownMenuItem(
                          value: 'date_asc',
                          child: Text('En Eski'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedSort = value;
                          });
                          _reloadWithNewFilters();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
        _reloadWithNewFilters();
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz analiz geçmişi yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk bitki analizinizi yaparak başlayın',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
