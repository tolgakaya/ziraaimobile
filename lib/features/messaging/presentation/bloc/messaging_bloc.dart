import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';

part 'messaging_event.dart';
part 'messaging_state.dart';

@injectable
class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final SendMessageUseCase sendMessageUseCase;
  final GetMessagesUseCase getMessagesUseCase;

  MessagingBloc({
    required this.sendMessageUseCase,
    required this.getMessagesUseCase,
  }) : super(MessagingInitial()) {
    on<LoadMessagesEvent>(_onLoadMessages);
    on<SendMessageEvent>(_onSendMessage);
    on<RefreshMessagesEvent>(_onRefreshMessages);
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
      (messages) => emit(MessagesLoaded(messages: messages)),
    );
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<MessagingState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessagesLoaded) return;

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
      (failure) => emit(MessageSendError(failure.message, currentState.messages)),
      (sentMessage) => emit(MessagesLoaded(messages: [...currentState.messages, sentMessage])),
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
      (messages) => emit(MessagesLoaded(messages: messages)),
    );
  }
}
