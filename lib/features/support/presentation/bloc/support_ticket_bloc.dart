import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/support_ticket_repository.dart';
import 'support_ticket_event.dart';
import 'support_ticket_state.dart';

/// BLoC for managing Support Ticket state
class SupportTicketBloc extends Bloc<SupportTicketEvent, SupportTicketState> {
  final SupportTicketRepository repository;

  SupportTicketBloc({required this.repository})
      : super(const SupportTicketInitial()) {
    on<LoadSupportTickets>(_onLoadTickets);
    on<LoadSupportTicketDetail>(_onLoadTicketDetail);
    on<CreateSupportTicket>(_onCreateTicket);
    on<AddTicketMessage>(_onAddMessage);
    on<CloseSupportTicket>(_onCloseTicket);
  }

  Future<void> _onLoadTickets(
    LoadSupportTickets event,
    Emitter<SupportTicketState> emit,
  ) async {
    emit(const SupportTicketLoading());
    try {
      final tickets = await repository.getTickets();
      emit(SupportTicketListLoaded(tickets));
    } catch (e) {
      emit(SupportTicketError('Destek talepleri yüklenemedi: $e'));
    }
  }

  Future<void> _onLoadTicketDetail(
    LoadSupportTicketDetail event,
    Emitter<SupportTicketState> emit,
  ) async {
    emit(const SupportTicketLoading());
    try {
      final ticket = await repository.getTicketById(event.ticketId);
      emit(SupportTicketDetailLoaded(ticket));
    } catch (e) {
      emit(SupportTicketError('Destek talebi yüklenemedi: $e'));
    }
  }

  Future<void> _onCreateTicket(
    CreateSupportTicket event,
    Emitter<SupportTicketState> emit,
  ) async {
    emit(const SupportTicketLoading());
    try {
      final ticket = await repository.createTicket(
        subject: event.subject,
        description: event.description,
        priority: event.priority,
      );
      emit(SupportTicketCreated(ticket));
    } catch (e) {
      emit(SupportTicketError('Destek talebi oluşturulamadı: $e'));
    }
  }

  Future<void> _onAddMessage(
    AddTicketMessage event,
    Emitter<SupportTicketState> emit,
  ) async {
    try {
      final message = await repository.addMessage(
        ticketId: event.ticketId,
        content: event.content,
      );
      final ticket = await repository.getTicketById(event.ticketId);
      emit(SupportTicketMessageAdded(ticket, message));
    } catch (e) {
      emit(SupportTicketError('Mesaj gönderilemedi: $e'));
    }
  }

  Future<void> _onCloseTicket(
    CloseSupportTicket event,
    Emitter<SupportTicketState> emit,
  ) async {
    try {
      await repository.closeTicket(event.ticketId);
      emit(SupportTicketClosed(event.ticketId));
    } catch (e) {
      emit(SupportTicketError('Destek talebi kapatılamadı: $e'));
    }
  }
}
