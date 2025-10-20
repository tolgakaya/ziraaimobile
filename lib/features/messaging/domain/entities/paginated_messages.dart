import 'package:equatable/equatable.dart';
import 'message.dart';

class PaginatedMessages extends Equatable {
  final List<Message> messages;
  final int pageNumber;
  final int pageSize;
  final int totalRecords;
  final int totalPages;

  const PaginatedMessages({
    required this.messages,
    required this.pageNumber,
    required this.pageSize,
    required this.totalRecords,
    required this.totalPages,
  });

  /// Check if there are more pages to load
  bool get hasMorePages => pageNumber < totalPages;

  /// Check if this is the last page
  bool get isLastPage => pageNumber >= totalPages;

  /// Check if this is the first page
  bool get isFirstPage => pageNumber == 1;

  @override
  List<Object?> get props => [messages, pageNumber, pageSize, totalRecords, totalPages];
}
