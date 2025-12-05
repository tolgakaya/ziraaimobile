part of 'messaging_bloc.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessagesEvent extends MessagingEvent {
  final int fromUserId;
  final int toUserId;
  final int plantAnalysisId;

  const LoadMessagesEvent(this.fromUserId, this.toUserId, this.plantAnalysisId);

  @override
  List<Object?> get props => [fromUserId, toUserId, plantAnalysisId];
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
  final int fromUserId;
  final int toUserId;
  final int plantAnalysisId;

  const RefreshMessagesEvent(this.fromUserId, this.toUserId, this.plantAnalysisId);

  @override
  List<Object?> get props => [fromUserId, toUserId, plantAnalysisId];
}

// ✅ NEW: Event for real-time message updates from SignalR
class NewMessageReceivedEvent extends MessagingEvent {
  final Message message;

  const NewMessageReceivedEvent(this.message);

  @override
  List<Object?> get props => [message];
}

// ✅ NEW: Event for sending message with attachments
// fromUserId is automatically extracted from JWT token by backend
class SendMessageWithAttachmentsEvent extends MessagingEvent {
  final int plantAnalysisId;
  final int toUserId;
  final String message;
  final List<String> attachmentPaths;

  const SendMessageWithAttachmentsEvent({
    required this.plantAnalysisId,
    required this.toUserId,
    required this.message,
    required this.attachmentPaths,
  });

  @override
  List<Object?> get props => [plantAnalysisId, toUserId, message, attachmentPaths];
}

// ✅ NEW: Event for loading more messages (pagination)
class LoadMoreMessagesEvent extends MessagingEvent {
  final int plantAnalysisId;
  final int fromUserId;
  final int toUserId;

  const LoadMoreMessagesEvent({
    required this.plantAnalysisId,
    required this.fromUserId,
    required this.toUserId,
  });

  @override
  List<Object?> get props => [plantAnalysisId, fromUserId, toUserId];
}

// ✅ NEW: Event for sending voice message
class SendVoiceMessageEvent extends MessagingEvent {
  final int plantAnalysisId;
  final int toUserId;
  final String voiceFilePath;
  final int duration;
  final List<double>? waveform;

  const SendVoiceMessageEvent({
    required this.plantAnalysisId,
    required this.toUserId,
    required this.voiceFilePath,
    required this.duration,
    this.waveform,
  });

  @override
  List<Object?> get props => [plantAnalysisId, toUserId, voiceFilePath, duration, waveform];
}

// ✅ NEW: Event for loading messaging features (tier-based)
// ⚠️ BREAKING CHANGE: Now requires plantAnalysisId
class LoadMessagingFeaturesEvent extends MessagingEvent {
  final int plantAnalysisId;

  const LoadMessagingFeaturesEvent({required this.plantAnalysisId});

  @override
  List<Object?> get props => [plantAnalysisId];
}

// ✅ NEW: Event for marking a single message as read
class MarkMessageAsReadEvent extends MessagingEvent {
  final int messageId;

  const MarkMessageAsReadEvent(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

// ✅ NEW: Event for marking multiple messages as read (bulk)
class MarkMessagesAsReadEvent extends MessagingEvent {
  final List<int> messageIds;

  const MarkMessagesAsReadEvent(this.messageIds);

  @override
  List<Object?> get props => [messageIds];
}
