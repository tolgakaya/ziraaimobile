import 'package:json_annotation/json_annotation.dart';
import 'message_model.dart';

part 'paginated_conversation_response.g.dart';

@JsonSerializable()
class PaginatedConversationResponse {
  final List<MessageModel> data;
  final int pageNumber;
  final int pageSize;
  final int totalRecords;
  final int totalPages;
  final bool success;
  final String? message;

  PaginatedConversationResponse({
    required this.data,
    required this.pageNumber,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
    required this.success,
    this.message,
  });

  factory PaginatedConversationResponse.fromJson(Map<String, dynamic> json) {
    return PaginatedConversationResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pageNumber: json['pageNumber'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
      totalRecords: json['totalRecords'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => _$PaginatedConversationResponseToJson(this);

  /// Check if there are more pages to load
  bool get hasMorePages => pageNumber < totalPages;

  /// Check if this is the last page
  bool get isLastPage => pageNumber >= totalPages;

  /// Check if this is the first page
  bool get isFirstPage => pageNumber == 1;
}
