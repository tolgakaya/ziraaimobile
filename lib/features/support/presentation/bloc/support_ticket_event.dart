import '../../domain/entities/support_ticket.dart';

/// Base class for Support Ticket events
abstract class SupportTicketEvent {
  const SupportTicketEvent();
}

/// Load all support tickets
class LoadSupportTickets extends SupportTicketEvent {
  const LoadSupportTickets();
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
  final SupportTicketPriority priority;

  const CreateSupportTicket({
    required this.subject,
    required this.description,
    this.priority = SupportTicketPriority.medium,
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
