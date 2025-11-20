import '../entities/support_ticket.dart';

/// Repository interface for Support Ticket operations
abstract class SupportTicketRepository {
  /// Get all support tickets for the current user
  Future<List<SupportTicket>> getTickets({
    SupportTicketStatus? status,
    SupportTicketCategory? category,
  });

  /// Get a specific support ticket by ID
  Future<SupportTicket> getTicketById(int ticketId);

  /// Create a new support ticket
  Future<int> createTicket({
    required String subject,
    required String description,
    required SupportTicketCategory category,
    SupportTicketPriority priority = SupportTicketPriority.normal,
  });

  /// Add a message to an existing ticket
  Future<void> addMessage({
    required int ticketId,
    required String content,
  });

  /// Close a support ticket
  Future<void> closeTicket(int ticketId);

  /// Rate a resolved/closed ticket
  Future<void> rateTicket({
    required int ticketId,
    required int rating,
    String? feedback,
  });
}
