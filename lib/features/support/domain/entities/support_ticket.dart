/// Support Ticket Entity
/// Represents a support ticket in the domain layer
class SupportTicket {
  final int id;
  final String subject;
  final String description;
  final SupportTicketStatus status;
  final SupportTicketPriority priority;
  final SupportTicketCategory category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final DateTime? lastResponseDate;
  final String? resolutionNotes;
  final int? satisfactionRating;
  final String? satisfactionFeedback;
  final bool hasUnreadMessages;
  final List<SupportTicketMessage> messages;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.closedAt,
    this.lastResponseDate,
    this.resolutionNotes,
    this.satisfactionRating,
    this.satisfactionFeedback,
    this.hasUnreadMessages = false,
    this.messages = const [],
  });

  bool get isOpen => status == SupportTicketStatus.open || status == SupportTicketStatus.inProgress;
  bool get isClosed => status == SupportTicketStatus.closed || status == SupportTicketStatus.resolved;
  bool get canRate => (status == SupportTicketStatus.resolved || status == SupportTicketStatus.closed) && satisfactionRating == null;
}

/// Support Ticket Message
/// Represents a message within a support ticket conversation
class SupportTicketMessage {
  final int id;
  final String content;
  final bool isAdminResponse;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readDate;

  const SupportTicketMessage({
    required this.id,
    required this.content,
    required this.isAdminResponse,
    required this.createdAt,
    this.isRead = false,
    this.readDate,
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
  normal,
  high,
}

/// Support Ticket Category
enum SupportTicketCategory {
  technical,
  billing,
  account,
  general,
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

  String get apiValue {
    switch (this) {
      case SupportTicketStatus.open:
        return 'Open';
      case SupportTicketStatus.inProgress:
        return 'InProgress';
      case SupportTicketStatus.resolved:
        return 'Resolved';
      case SupportTicketStatus.closed:
        return 'Closed';
    }
  }

  static SupportTicketStatus fromApiString(String value) {
    switch (value) {
      case 'Open':
        return SupportTicketStatus.open;
      case 'InProgress':
        return SupportTicketStatus.inProgress;
      case 'Resolved':
        return SupportTicketStatus.resolved;
      case 'Closed':
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
      case SupportTicketPriority.normal:
        return 'Normal';
      case SupportTicketPriority.high:
        return 'Yüksek';
    }
  }

  String get apiValue {
    switch (this) {
      case SupportTicketPriority.low:
        return 'Low';
      case SupportTicketPriority.normal:
        return 'Normal';
      case SupportTicketPriority.high:
        return 'High';
    }
  }

  static SupportTicketPriority fromApiString(String value) {
    switch (value) {
      case 'Low':
        return SupportTicketPriority.low;
      case 'Normal':
        return SupportTicketPriority.normal;
      case 'High':
        return SupportTicketPriority.high;
      default:
        return SupportTicketPriority.normal;
    }
  }
}

/// Extension methods for SupportTicketCategory
extension SupportTicketCategoryExtension on SupportTicketCategory {
  String get displayName {
    switch (this) {
      case SupportTicketCategory.technical:
        return 'Teknik';
      case SupportTicketCategory.billing:
        return 'Fatura';
      case SupportTicketCategory.account:
        return 'Hesap';
      case SupportTicketCategory.general:
        return 'Genel';
    }
  }

  String get apiValue {
    switch (this) {
      case SupportTicketCategory.technical:
        return 'Technical';
      case SupportTicketCategory.billing:
        return 'Billing';
      case SupportTicketCategory.account:
        return 'Account';
      case SupportTicketCategory.general:
        return 'General';
    }
  }

  static SupportTicketCategory fromApiString(String value) {
    switch (value) {
      case 'Technical':
        return SupportTicketCategory.technical;
      case 'Billing':
        return SupportTicketCategory.billing;
      case 'Account':
        return SupportTicketCategory.account;
      case 'General':
        return SupportTicketCategory.general;
      default:
        return SupportTicketCategory.general;
    }
  }
}
