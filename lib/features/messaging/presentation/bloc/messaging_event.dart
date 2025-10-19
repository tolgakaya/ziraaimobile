part of 'messaging_bloc.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessagesEvent extends MessagingEvent {
  final int plantAnalysisId;
  final int farmerId;

  const LoadMessagesEvent(this.plantAnalysisId, this.farmerId);

  @override
  List<Object?> get props => [plantAnalysisId, farmerId];
}

class SendMessageEvent extends MessagingEvent {
  final int plantAnalysisId;
  final int toUserId;
  final String message;
  final String? messageType;
  final String? subject;

  const SendMessageEvent({
    required this.plantAnalysisId,
    required this.toUserId,
    required this.message,
    this.messageType,
    this.subject,
  });

  @override
  List<Object?> get props => [plantAnalysisId, toUserId, message, messageType, subject];
}

class RefreshMessagesEvent extends MessagingEvent {
  final int plantAnalysisId;
  final int farmerId;

  const RefreshMessagesEvent(this.plantAnalysisId, this.farmerId);

  @override
  List<Object?> get props => [plantAnalysisId, farmerId];
}

// ✅ NEW: Event for real-time message updates from SignalR
class NewMessageReceivedEvent extends MessagingEvent {
  final Message message;

  const NewMessageReceivedEvent(this.message);

  @override
  List<Object?> get props => [message];
}
