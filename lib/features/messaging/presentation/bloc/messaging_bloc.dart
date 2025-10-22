import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/messaging_features.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/send_message_with_attachments_usecase.dart';
import '../../domain/usecases/send_voice_message_usecase.dart';
import '../../domain/usecases/get_messaging_features_usecase.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

@injectable
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageWithAttachmentsUseCase sendMessageWithAttachmentsUseCase;
  final SendVoiceMessageUseCase sendVoiceMessageUseCase;
  final GetMessagingFeaturesUseCase getMessagingFeaturesUseCase;

  // Cache features to include in MessagesLoaded state
  MessagingFeatures? _cachedFeatures;

  MessagingBloc({
    required this.sendMessageUseCase,
    required this.getMessagesUseCase,
    required this.sendMessageWithAttachmentsUseCase,
    required this.sendVoiceMessageUseCase,
    required this.getMessagingFeaturesUseCase,
  }) : super(MessagingInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<SendMessageWithAttachmentsEvent>(_onSendMessageWithAttachments);
    on<RefreshMessagesEvent>(_onRefreshMessages);
    on<NewMessageReceivedEvent>(_onNewMessageReceived);
    on<LoadMoreMessagesEvent>(_onLoadMoreMessages);
    on<SendVoiceMessageEvent>(_onSendVoiceMessage);
    on<LoadMessagingFeaturesEvent>(_onLoadMessagingFeatures);
  }

  /// Expose cached features for UI access (even when state is not MessagesLoaded yet)
  MessagingFeatures? get cachedFeatures => _cachedFeatures;

  /// Business rule: Farmer can reply only if sponsor has sent at least one message
  bool _canFarmerReply(List<Message> messages) {
    return messages.any((msg) => msg.senderRole == 'Sponsor');
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    final result = await getMessagesUseCase(
      plantAnalysisId: event.plantAnalysisId,
      otherUserId: event.otherUserId,
      page: 1,
      pageSize: 20,
    );
    result.fold(
      (failure) => emit(MessagingError(failure.message)),
      (paginatedMessages) {
        // ✅ BUSINESS RULE: Check if farmer can reply
        final canReply = _canFarmerReply(paginatedMessages.messages);
        emit(MessagesLoaded(
          messages: paginatedMessages.messages,
          canReply: canReply,
          currentPage: paginatedMessages.pageNumber,
          totalPages: paginatedMessages.totalPages,
          totalRecords: paginatedMessages.totalRecords,
          features: _cachedFeatures, // Include cached features
        ));
      },
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    // Optimistic UI update
    emit(currentState.copyWith(isSending: true));

    final result = await sendMessageUseCase(
      SendMessageParams(
        plantAnalysisId: event.plantAnalysisId,
        toUserId: event.toUserId,
        message: event.message,
        messageType: event.messageType,
        subject: event.subject,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isSending: false));
        emit(MessageSendError(failure.message, currentState.messages));
      },
      (sentMessage) {
        final updatedMessages = [...currentState.messages, sentMessage];
        emit(MessagesLoaded(
          messages: updatedMessages,
          canReply: _canFarmerReply(updatedMessages),
          isSending: false,
          features: _cachedFeatures, // Preserve cached features
        ));
      },
    );
  }

  Future<void> _onRefreshMessages(
    RefreshMessagesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final result = await getMessagesUseCase(
      plantAnalysisId: event.plantAnalysisId,
      otherUserId: event.otherUserId,
      page: 1,
      pageSize: 20,
    );
    result.fold(
      (failure) => null, // Keep current state on refresh error
      (paginatedMessages) {
        final canReply = _canFarmerReply(paginatedMessages.messages);
        emit(MessagesLoaded(
          messages: paginatedMessages.messages,
          canReply: canReply,
          currentPage: paginatedMessages.pageNumber,
          totalPages: paginatedMessages.totalPages,
          totalRecords: paginatedMessages.totalRecords,
          features: _cachedFeatures, // Include cached features
        ));
      },
    );
  }

  Future<void> _onSendMessageWithAttachments(
    SendMessageWithAttachmentsEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    // Optimistic UI update - show uploading state
    emit(currentState.copyWith(isSending: true));

    final result = await sendMessageWithAttachmentsUseCase(
      plantAnalysisId: event.plantAnalysisId,
      toUserId: event.toUserId,
      message: event.message,
      attachmentPaths: event.attachmentPaths,
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isSending: false));
        emit(MessageSendError(failure.message, currentState.messages));
      },
      (sentMessage) {
        final updatedMessages = [...currentState.messages, sentMessage];
        emit(MessagesLoaded(
          messages: updatedMessages,
          canReply: _canFarmerReply(updatedMessages),
          isSending: false,
          features: _cachedFeatures, // Preserve cached features
        ));
      },
    );
  }

  // ✅ NEW: Handle real-time messages from SignalR
  void _onNewMessageReceived(
    NewMessageReceivedEvent event,
    Emitter<MessagingState> emit,
  ) {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    // Prevent duplicates
    if (currentState.messages.any((msg) => msg.id == event.message.id)) {
      return;
    }

    final updatedMessages = [...currentState.messages, event.message];

    emit(MessagesLoaded(
      messages: updatedMessages,
      canReply: _canFarmerReply(updatedMessages),
      features: _cachedFeatures, // Preserve cached features
    ));
  }

  // ✅ NEW: Handle load more messages (pagination)
  Future<void> _onLoadMoreMessages(
    LoadMoreMessagesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    // Don't load if already loading or no more pages
    if (currentState.isLoadingMore || !currentState.hasMorePages) {
      return;
    }

    // Set loading more state
    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;
    final result = await getMessagesUseCase(
      plantAnalysisId: event.plantAnalysisId,
      otherUserId: event.otherUserId,
      page: nextPage,
      pageSize: 20,
    );

    result.fold(
      (failure) {
        // On error, revert loading state
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (paginatedMessages) {
        // Append new messages to existing ones
        final updatedMessages = [
          ...currentState.messages,
          ...paginatedMessages.messages,
        ];

        emit(MessagesLoaded(
          messages: updatedMessages,
          canReply: _canFarmerReply(updatedMessages),
          currentPage: paginatedMessages.pageNumber,
          totalPages: paginatedMessages.totalPages,
          totalRecords: paginatedMessages.totalRecords,
          isLoadingMore: false,
          features: _cachedFeatures, // Preserve cached features
        ));
      },
    );
  }

  // ✅ NEW: Handle sending voice message
  Future<void> _onSendVoiceMessage(
    SendVoiceMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

    // Optimistic UI update - show sending state
    emit(currentState.copyWith(isSending: true));

    final result = await sendVoiceMessageUseCase(
      SendVoiceMessageParams(
        plantAnalysisId: event.plantAnalysisId,
        toUserId: event.toUserId,
        voiceFile: File(event.voiceFilePath),
        duration: event.duration,
        waveform: event.waveform,
      ),
    );

    result.fold(
      (failure) {
        emit(currentState.copyWith(isSending: false));
        emit(MessageSendError(failure.message, currentState.messages));
      },
      (sentMessage) {
        final updatedMessages = [...currentState.messages, sentMessage];
        emit(MessagesLoaded(
          messages: updatedMessages,
          canReply: _canFarmerReply(updatedMessages),
          isSending: false,
          features: _cachedFeatures, // Preserve cached features
        ));
      },
    );
  }

  // ✅ NEW: Load messaging features (tier-based)
  // ⚠️ BREAKING CHANGE: Now requires plantAnalysisId to get features for specific analysis
  Future<void> _onLoadMessagingFeatures(
    LoadMessagingFeaturesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final currentState = state;

    // Load features for this specific analysis
    final result = await getMessagingFeaturesUseCase(plantAnalysisId: event.plantAnalysisId);

    result.fold(
      (failure) {
        // Silent failure - features stay null, UI will use defaults
        print('⚠️ Failed to load messaging features for analysis ${event.plantAnalysisId}: ${failure.message}');
      },
      (features) {
        // Cache features for future state emissions
        _cachedFeatures = features;
        print('✅ MessagingFeatures loaded for analysis ${event.plantAnalysisId}: imageAttachments.available=${features.imageAttachments.available}, fileAttachments.available=${features.fileAttachments.available}, voiceMessages.available=${features.voiceMessages.available}');

        // Update state with features ONLY if we're already in MessagesLoaded state
        // ⚠️ DO NOT emit empty MessagesLoaded here - it will clear messages from UI!
        if (currentState is MessagesLoaded) {
          emit(currentState.copyWith(features: features));
        }
        // If not MessagesLoaded yet, features will be picked up from _cachedFeatures
        // when LoadMessagesEvent completes and emits MessagesLoaded
      },
    );
  }
}
