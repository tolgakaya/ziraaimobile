/// Support Ticket Entity
/// Represents a support ticket in the domain layer
class SupportTicket {
  final int id;
  final String subject;
  final String description;
  final SupportTicketStatus status;
  final SupportTicketPriority priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final List<SupportTicketMessage> messages;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.messages = const [],
  });

  bool get isOpen => status == SupportTicketStatus.open || status == SupportTicketStatus.inProgress;
  bool get isClosed => status == SupportTicketStatus.closed || status == SupportTicketStatus.resolved;
}

/// Support Ticket Message
/// Represents a message within a support ticket conversation
class SupportTicketMessage {
  final int id;
  final String content;
  final bool isFromSupport;
  final DateTime createdAt;
  final String? attachmentUrl;

  const SupportTicketMessage({
    required this.id,
    required this.content,
    required this.isFromSupport,
    required this.createdAt,
    this.attachmentUrl,
  });
}

/// Support Ticket Status
enum SupportTicketStatus {
  open,
  inProgress,
  resolved,
  closed,
}

/// Support Ticket Priority
enum SupportTicketPriority {
  low,
  medium,
  high,
  urgent,
}

/// Extension methods for SupportTicketStatus
extension SupportTicketStatusExtension on SupportTicketStatus {
  String get displayName {
    switch (this) {
      case SupportTicketStatus.open:
        return 'Açık';
      case SupportTicketStatus.inProgress:
        return 'İşlemde';
      case SupportTicketStatus.resolved:
        return 'Çözüldü';
      case SupportTicketStatus.closed:
        return 'Kapatıldı';
    }
  }

  String get value {
    switch (this) {
      case SupportTicketStatus.open:
        return 'open';
      case SupportTicketStatus.inProgress:
        return 'in_progress';
      case SupportTicketStatus.resolved:
        return 'resolved';
      case SupportTicketStatus.closed:
        return 'closed';
    }
  }

  static SupportTicketStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'open':
        return SupportTicketStatus.open;
      case 'in_progress':
        return SupportTicketStatus.inProgress;
      case 'resolved':
        return SupportTicketStatus.resolved;
      case 'closed':
        return SupportTicketStatus.closed;
      default:
        return SupportTicketStatus.open;
    }
  }
}

/// Extension methods for SupportTicketPriority
extension SupportTicketPriorityExtension on SupportTicketPriority {
  String get displayName {
    switch (this) {
      case SupportTicketPriority.low:
        return 'Düşük';
      case SupportTicketPriority.medium:
        return 'Orta';
      case SupportTicketPriority.high:
        return 'Yüksek';
      case SupportTicketPriority.urgent:
        return 'Acil';
    }
  }

  String get value {
    switch (this) {
      case SupportTicketPriority.low:
        return 'low';
      case SupportTicketPriority.medium:
        return 'medium';
      case SupportTicketPriority.high:
        return 'high';
      case SupportTicketPriority.urgent:
        return 'urgent';
    }
  }

  static SupportTicketPriority fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
        return SupportTicketPriority.low;
      case 'medium':
        return SupportTicketPriority.medium;
      case 'high':
        return SupportTicketPriority.high;
      case 'urgent':
        return SupportTicketPriority.urgent;
      default:
        return SupportTicketPriority.medium;
    }
  }
}
