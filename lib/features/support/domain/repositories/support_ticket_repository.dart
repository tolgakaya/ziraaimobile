import '../entities/support_ticket.dart';

/// Repository interface for Support Ticket operations
abstract class SupportTicketRepository {
  /// Get all support tickets for the current user
  Future<List<SupportTicket>> getTickets();

  /// Get a specific support ticket by ID
  Future<SupportTicket> getTicketById(int ticketId);

  /// Create a new support ticket
  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    SupportTicketPriority priority = SupportTicketPriority.medium,
  });

  /// Add a message to an existing ticket
  Future<SupportTicketMessage> addMessage({
    required int ticketId,
    required String content,
  });

  /// Close a support ticket
  Future<void> closeTicket(int ticketId);
}
