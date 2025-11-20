import '../../../../core/network/network_client.dart';
import '../models/ticket_dto.dart';

/// API Service for Support Ticket operations
class SupportTicketApiService {
  final NetworkClient _networkClient;

  static const String _baseUrl = '/tickets';

  SupportTicketApiService(this._networkClient);

  /// Get user's tickets with optional filters
  Future<TicketListResponseDto> getTickets({
    String? status,
    String? category,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null) queryParams['status'] = status;
    if (category != null) queryParams['category'] = category;

    final response = await _networkClient.get(
      _baseUrl,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return TicketListResponseDto.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Failed to load tickets');
  }

  /// Get ticket detail with messages
  Future<TicketDetailDto> getTicketDetail(int ticketId) async {
    final response = await _networkClient.get('$_baseUrl/$ticketId');

    final data = response.data;
    if (data['success'] == true && data['data'] != null) {
      return TicketDetailDto.fromJson(data['data']);
    }
    throw Exception(data['message'] ?? 'Ticket not found');
  }

  /// Create a new ticket
  Future<int> createTicket(CreateTicketRequestDto request) async {
    final response = await _networkClient.post(
      _baseUrl,
      data: request.toJson(),
    );

    final data = response.data;
    if (data['success'] == true) {
      return data['data'] as int;
    }
    throw Exception(data['message'] ?? 'Failed to create ticket');
  }

  /// Add message to existing ticket
  Future<void> addMessage(int ticketId, AddMessageRequestDto request) async {
    final response = await _networkClient.post(
      '$_baseUrl/$ticketId/messages',
      data: request.toJson(),
    );

    final data = response.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to send message');
    }
  }

  /// Close ticket
  Future<void> closeTicket(int ticketId) async {
    final response = await _networkClient.post('$_baseUrl/$ticketId/close');

    final data = response.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to close ticket');
    }
  }

  /// Rate ticket resolution
  Future<void> rateTicket(int ticketId, RateTicketRequestDto request) async {
    final response = await _networkClient.post(
      '$_baseUrl/$ticketId/rate',
      data: request.toJson(),
    );

    final data = response.data;
    if (data['success'] != true) {
      throw Exception(data['message'] ?? 'Failed to rate ticket');
    }
  }
}
