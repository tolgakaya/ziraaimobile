import '../../domain/entities/support_ticket.dart';

/// DTO for ticket list item from API
class TicketListItemDto {
  final int id;
  final String subject;
  final String category;
  final String priority;
  final String status;
  final DateTime createdDate;
  final DateTime? lastResponseDate;
  final bool hasUnreadMessages;

  TicketListItemDto({
    required this.id,
    required this.subject,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdDate,
    this.lastResponseDate,
    this.hasUnreadMessages = false,
  });

  factory TicketListItemDto.fromJson(Map<String, dynamic> json) {
    return TicketListItemDto(
      id: json['id'] as int,
      subject: json['subject'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      lastResponseDate: json['lastResponseDate'] != null
          ? DateTime.parse(json['lastResponseDate'] as String)
          : null,
      hasUnreadMessages: json['hasUnreadMessages'] as bool? ?? false,
    );
  }

  SupportTicket toEntity() {
    return SupportTicket(
      id: id,
      subject: subject,
      description: '', // Not available in list response
      status: SupportTicketStatusExtension.fromApiString(status),
      priority: SupportTicketPriorityExtension.fromApiString(priority),
      category: SupportTicketCategoryExtension.fromApiString(category),
      createdAt: createdDate,
      lastResponseDate: lastResponseDate,
      hasUnreadMessages: hasUnreadMessages,
    );
  }
}

/// DTO for ticket detail from API
class TicketDetailDto {
  final int id;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final DateTime createdDate;
  final DateTime? updatedDate;
  final DateTime? resolvedDate;
  final DateTime? closedDate;
  final String? resolutionNotes;
  final int? satisfactionRating;
  final String? satisfactionFeedback;
  final List<TicketMessageDto> messages;

  TicketDetailDto({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdDate,
    this.updatedDate,
    this.resolvedDate,
    this.closedDate,
    this.resolutionNotes,
    this.satisfactionRating,
    this.satisfactionFeedback,
    this.messages = const [],
  });

  factory TicketDetailDto.fromJson(Map<String, dynamic> json) {
    return TicketDetailDto(
      id: json['id'] as int,
      subject: json['subject'] as String,
      description: json['description'] as String,
      category: json['category'] as String,
      priority: json['priority'] as String,
      status: json['status'] as String,
      createdDate: DateTime.parse(json['createdDate'] as String),
      updatedDate: json['updatedDate'] != null
          ? DateTime.parse(json['updatedDate'] as String)
          : null,
      resolvedDate: json['resolvedDate'] != null
          ? DateTime.parse(json['resolvedDate'] as String)
          : null,
      closedDate: json['closedDate'] != null
          ? DateTime.parse(json['closedDate'] as String)
          : null,
      resolutionNotes: json['resolutionNotes'] as String?,
      satisfactionRating: json['satisfactionRating'] as int?,
      satisfactionFeedback: json['satisfactionFeedback'] as String?,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => TicketMessageDto.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  SupportTicket toEntity() {
    return SupportTicket(
      id: id,
      subject: subject,
      description: description,
      status: SupportTicketStatusExtension.fromApiString(status),
      priority: SupportTicketPriorityExtension.fromApiString(priority),
      category: SupportTicketCategoryExtension.fromApiString(category),
      createdAt: createdDate,
      updatedAt: updatedDate,
      resolvedAt: resolvedDate,
      closedAt: closedDate,
      resolutionNotes: resolutionNotes,
      satisfactionRating: satisfactionRating,
      satisfactionFeedback: satisfactionFeedback,
      messages: messages.map((m) => m.toEntity()).toList(),
    );
  }
}

/// DTO for ticket message from API
class TicketMessageDto {
  final int id;
  final String message;
  final bool isAdminResponse;
  final DateTime createdDate;

  TicketMessageDto({
    required this.id,
    required this.message,
    required this.isAdminResponse,
    required this.createdDate,
  });

  factory TicketMessageDto.fromJson(Map<String, dynamic> json) {
    return TicketMessageDto(
      id: json['id'] as int,
      message: json['message'] as String,
      isAdminResponse: json['isAdminResponse'] as bool,
      createdDate: DateTime.parse(json['createdDate'] as String),
    );
  }

  SupportTicketMessage toEntity() {
    return SupportTicketMessage(
      id: id,
      content: message,
      isAdminResponse: isAdminResponse,
      createdAt: createdDate,
    );
  }
}

/// DTO for ticket list response
class TicketListResponseDto {
  final List<TicketListItemDto> tickets;
  final int totalCount;

  TicketListResponseDto({
    required this.tickets,
    required this.totalCount,
  });

  factory TicketListResponseDto.fromJson(Map<String, dynamic> json) {
    return TicketListResponseDto(
      tickets: (json['tickets'] as List<dynamic>)
          .map((e) => TicketListItemDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCount: json['totalCount'] as int,
    );
  }
}

/// Request DTO for creating a ticket
class CreateTicketRequestDto {
  final String subject;
  final String description;
  final String category;
  final String priority;

  CreateTicketRequestDto({
    required this.subject,
    required this.description,
    required this.category,
    this.priority = 'Normal',
  });

  Map<String, dynamic> toJson() {
    return {
      'subject': subject,
      'description': description,
      'category': category,
      'priority': priority,
    };
  }
}

/// Request DTO for adding a message
class AddMessageRequestDto {
  final String message;

  AddMessageRequestDto({required this.message});

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}

/// Request DTO for rating a ticket
class RateTicketRequestDto {
  final int rating;
  final String? feedback;

  RateTicketRequestDto({
    required this.rating,
    this.feedback,
  });

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (feedback != null) 'feedback': feedback,
    };
  }
}
