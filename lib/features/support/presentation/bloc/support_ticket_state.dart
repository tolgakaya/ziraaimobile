import '../../domain/entities/support_ticket.dart';

/// Base class for Support Ticket states
abstract class SupportTicketState {
  const SupportTicketState();
}

/// Initial state
class SupportTicketInitial extends SupportTicketState {
  const SupportTicketInitial();
}

/// Loading tickets
class SupportTicketLoading extends SupportTicketState {
  const SupportTicketLoading();
}

/// Tickets loaded successfully
class SupportTicketListLoaded extends SupportTicketState {
  final List<SupportTicket> tickets;
  const SupportTicketListLoaded(this.tickets);
}

/// Single ticket detail loaded
class SupportTicketDetailLoaded extends SupportTicketState {
  final SupportTicket ticket;
  const SupportTicketDetailLoaded(this.ticket);
}

/// Ticket created successfully
class SupportTicketCreated extends SupportTicketState {
  final SupportTicket ticket;
  const SupportTicketCreated(this.ticket);
}

/// Message added successfully
class SupportTicketMessageAdded extends SupportTicketState {
  final SupportTicket ticket;
  final SupportTicketMessage message;
  const SupportTicketMessageAdded(this.ticket, this.message);
}

/// Ticket closed successfully
class SupportTicketClosed extends SupportTicketState {
  final int ticketId;
  const SupportTicketClosed(this.ticketId);
}

/// Error state
class SupportTicketError extends SupportTicketState {
  final String message;
  const SupportTicketError(this.message);
}
