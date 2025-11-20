import '../../domain/entities/support_ticket.dart';

/// Base class for Support Ticket events
abstract class SupportTicketEvent {
  const SupportTicketEvent();
}

/// Load all support tickets with optional filters
class LoadSupportTickets extends SupportTicketEvent {
  final SupportTicketStatus? status;
  final SupportTicketCategory? category;

  const LoadSupportTickets({
    this.status,
    this.category,
  });
}

/// Load a specific ticket by ID
class LoadSupportTicketDetail extends SupportTicketEvent {
  final int ticketId;
  const LoadSupportTicketDetail(this.ticketId);
}

/// Create a new support ticket
class CreateSupportTicket extends SupportTicketEvent {
  final String subject;
  final String description;
  final SupportTicketCategory category;
  final SupportTicketPriority priority;

  const CreateSupportTicket({
    required this.subject,
    required this.description,
    required this.category,
    this.priority = SupportTicketPriority.normal,
  });
}

/// Add a message to a ticket
class AddTicketMessage extends SupportTicketEvent {
  final int ticketId;
  final String content;

  const AddTicketMessage({
    required this.ticketId,
    required this.content,
  });
}

/// Close a support ticket
class CloseSupportTicket extends SupportTicketEvent {
  final int ticketId;
  const CloseSupportTicket(this.ticketId);
}

/// Rate a resolved/closed ticket
class RateSupportTicket extends SupportTicketEvent {
  final int ticketId;
  final int rating;
  final String? feedback;

  const RateSupportTicket({
    required this.ticketId,
    required this.rating,
    this.feedback,
  });
}
