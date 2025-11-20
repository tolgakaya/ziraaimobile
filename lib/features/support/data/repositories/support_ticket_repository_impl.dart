import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_ticket_repository.dart';
import '../services/support_ticket_api_service.dart';
import '../models/ticket_dto.dart';

/// Implementation of SupportTicketRepository using real API
class SupportTicketRepositoryImpl implements SupportTicketRepository {
  final SupportTicketApiService _apiService;

  SupportTicketRepositoryImpl(this._apiService);

  @override
  Future<List<SupportTicket>> getTickets({
    SupportTicketStatus? status,
    SupportTicketCategory? category,
  }) async {
    try {
      final response = await _apiService.getTickets(
        status: status?.apiValue,
        category: category?.apiValue,
      );
      return response.tickets.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      print('❌ SupportTicketRepository: Failed to get tickets: $e');
      rethrow;
    }
  }

  @override
  Future<SupportTicket> getTicketById(int ticketId) async {
    try {
      final dto = await _apiService.getTicketDetail(ticketId);
      return dto.toEntity();
    } catch (e) {
      print('❌ SupportTicketRepository: Failed to get ticket detail: $e');
      rethrow;
    }
  }

  @override
  Future<int> createTicket({
    required String subject,
    required String description,
    required SupportTicketCategory category,
    SupportTicketPriority priority = SupportTicketPriority.normal,
  }) async {
    try {
      final request = CreateTicketRequestDto(
        subject: subject,
        description: description,
        category: category.apiValue,
        priority: priority.apiValue,
      );
      return await _apiService.createTicket(request);
    } catch (e) {
      print('❌ SupportTicketRepository: Failed to create ticket: $e');
      rethrow;
    }
  }

  @override
  Future<void> addMessage({
    required int ticketId,
    required String content,
  }) async {
    try {
      final request = AddMessageRequestDto(message: content);
      await _apiService.addMessage(ticketId, request);
    } catch (e) {
      print('❌ SupportTicketRepository: Failed to add message: $e');
      rethrow;
    }
  }

  @override
  Future<void> closeTicket(int ticketId) async {
    try {
      await _apiService.closeTicket(ticketId);
    } catch (e) {
      print('❌ SupportTicketRepository: Failed to close ticket: $e');
      rethrow;
    }
  }

  @override
  Future<void> rateTicket({
    required int ticketId,
    required int rating,
    String? feedback,
  }) async {
    try {
      final request = RateTicketRequestDto(
        rating: rating,
        feedback: feedback,
      );
      await _apiService.rateTicket(ticketId, request);
    } catch (e) {
      print('❌ SupportTicketRepository: Failed to rate ticket: $e');
      rethrow;
    }
  }
}
