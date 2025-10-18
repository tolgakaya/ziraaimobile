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
  final bool isSending;

  const MessagesLoaded({
    required this.messages,
    this.isSending = false,
  });

  @override
  List<Object?> get props => [messages, isSending];

  MessagesLoaded copyWith({
    List<Message>? messages,
    bool? isSending,
  }) {
    return MessagesLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
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
