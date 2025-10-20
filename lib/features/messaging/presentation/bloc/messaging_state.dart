part of 'messaging_bloc.dart';

abstract class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {}

class MessagingLoading extends MessagingState {}

class MessagesLoaded extends MessagingState {
  final List<Message> messages;
  final bool canReply; // ✅ Farmer reply permission
  final bool isSending;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final bool isLoadingMore;

  const MessagesLoaded({
    required this.messages,
    required this.canReply,
    this.isSending = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalRecords = 0,
    this.isLoadingMore = false,
  });

  bool get hasMorePages => currentPage < totalPages;

  @override
  List<Object?> get props => [messages, canReply, isSending, currentPage, totalPages, totalRecords, isLoadingMore];

  MessagesLoaded copyWith({
    List<Message>? messages,
    bool? canReply,
    bool? isSending,
    int? currentPage,
    int? totalPages,
    int? totalRecords,
    bool? isLoadingMore,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      canReply: canReply ?? this.canReply,
      isSending: isSending ?? this.isSending,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalRecords: totalRecords ?? this.totalRecords,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class MessagingError extends MessagingState {
  final String message;

  const MessagingError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessageSendError extends MessagingState {
  final String message;
  final List<Message> currentMessages;

  const MessageSendError(this.message, this.currentMessages);

  @override
  List<Object?> get props => [message, currentMessages];
}
