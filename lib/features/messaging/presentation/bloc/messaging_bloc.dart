import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';
import '../../domain/usecases/check_can_reply_usecase.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

@injectable
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetMessagesUseCase getMessagesUseCase;
  final CheckCanReplyUseCase checkCanReplyUseCase;

  MessagingBloc({
    required this.sendMessageUseCase,
    required this.getMessagesUseCase,
    required this.checkCanReplyUseCase,
  }) : super(MessagingInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<RefreshMessagesEvent>(_onRefreshMessages);
    on<NewMessageReceivedEvent>(_onNewMessageReceived);
  }

  Future<void> _onLoadMessages(
    LoadMessagesEvent event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    final result = await getMessagesUseCase(
      plantAnalysisId: event.plantAnalysisId,
      farmerId: event.farmerId,
    );
    result.fold(
      (failure) => emit(MessagingError(failure.message)),
      (messages) {
        // ✅ BUSINESS RULE: Check if farmer can reply
        final canReply = checkCanReplyUseCase(messages);
        emit(MessagesLoaded(
          messages: messages,
          canReply: canReply,
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
          canReply: true, // Farmer can now reply after sending
          isSending: false,
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
      farmerId: event.farmerId,
    );
    result.fold(
      (failure) => null, // Keep current state on refresh error
      (messages) {
        final canReply = checkCanReplyUseCase(messages);
        emit(MessagesLoaded(
          messages: messages,
          canReply: canReply,
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
      canReply: checkCanReplyUseCase(updatedMessages),
    ));
  }
}
