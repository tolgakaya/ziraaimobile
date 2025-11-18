import '../../domain/entities/support_ticket.dart';
import '../../domain/repositories/support_ticket_repository.dart';

/// Mock implementation of SupportTicketRepository
/// TODO: Replace with real API integration when backend endpoints are ready
class SupportTicketRepositoryImpl implements SupportTicketRepository {
  // Mock data storage
  final List<SupportTicket> _mockTickets = [
    SupportTicket(
      id: 1,
      subject: 'Analiz sonuçları yüklenmiyor',
      description: 'Bitki analizini yaptıktan sonra sonuçlar görüntülenmiyor. Lütfen yardımcı olur musunuz?',
      status: SupportTicketStatus.inProgress,
      priority: SupportTicketPriority.high,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      messages: [
        SupportTicketMessage(
          id: 1,
          content: 'Analiz sonuçlarım yüklenmiyor, yardımcı olur musunuz?',
          isFromSupport: false,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        SupportTicketMessage(
          id: 2,
          content: 'Merhaba, sorununuzu inceliyoruz. Hangi cihazı kullanıyorsunuz?',
          isFromSupport: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
        ),
        SupportTicketMessage(
          id: 3,
          content: 'Samsung Galaxy S21 kullanıyorum, Android 13.',
          isFromSupport: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 18)),
        ),
        SupportTicketMessage(
          id: 4,
          content: 'Teşekkürler, bu bilgi çok faydalı oldu. Sorununuzu çözmek için çalışıyoruz.',
          isFromSupport: true,
          createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        ),
      ],
    ),
    SupportTicket(
      id: 2,
      subject: 'Abonelik yenileme sorunu',
      description: 'Aboneliğimi yenilemek istiyorum ama ödeme sayfası açılmıyor.',
      status: SupportTicketStatus.resolved,
      priority: SupportTicketPriority.medium,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      resolvedAt: DateTime.now().subtract(const Duration(days: 5)),
      messages: [
        SupportTicketMessage(
          id: 5,
          content: 'Ödeme sayfası açılmıyor, yardım eder misiniz?',
          isFromSupport: false,
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        SupportTicketMessage(
          id: 6,
          content: 'Merhaba, ödeme sistemimizde geçici bir sorun yaşandı. Şu an düzeltildi, tekrar deneyebilirsiniz.',
          isFromSupport: true,
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ],
    ),
    SupportTicket(
      id: 3,
      subject: 'Yeni özellik talebi',
      description: 'Bitki hastalıklarının tarihçesini görebilmek istiyorum.',
      status: SupportTicketStatus.open,
      priority: SupportTicketPriority.low,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      messages: [
        SupportTicketMessage(
          id: 7,
          content: 'Geçmiş analizlerimi ve hastalık tarihçesini görmek istiyorum. Bu özellik eklenebilir mi?',
          isFromSupport: false,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ],
    ),
  ];

  int _nextTicketId = 4;
  int _nextMessageId = 8;

  @override
  Future<List<SupportTicket>> getTickets() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return sorted by date (newest first)
    final sortedTickets = List<SupportTicket>.from(_mockTickets)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return sortedTickets;
  }

  @override
  Future<SupportTicket> getTicketById(int ticketId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final ticket = _mockTickets.firstWhere(
      (t) => t.id == ticketId,
      orElse: () => throw Exception('Destek talebi bulunamadı'),
    );

    return ticket;
  }

  @override
  Future<SupportTicket> createTicket({
    required String subject,
    required String description,
    SupportTicketPriority priority = SupportTicketPriority.medium,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final newTicket = SupportTicket(
      id: _nextTicketId++,
      subject: subject,
      description: description,
      status: SupportTicketStatus.open,
      priority: priority,
      createdAt: DateTime.now(),
      messages: [
        SupportTicketMessage(
          id: _nextMessageId++,
          content: description,
          isFromSupport: false,
          createdAt: DateTime.now(),
        ),
      ],
    );

    _mockTickets.add(newTicket);
    return newTicket;
  }

  @override
  Future<SupportTicketMessage> addMessage({
    required int ticketId,
    required String content,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final ticketIndex = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) {
      throw Exception('Destek talebi bulunamadı');
    }

    final newMessage = SupportTicketMessage(
      id: _nextMessageId++,
      content: content,
      isFromSupport: false,
      createdAt: DateTime.now(),
    );

    // Create updated ticket with new message
    final oldTicket = _mockTickets[ticketIndex];
    final updatedMessages = [...oldTicket.messages, newMessage];

    _mockTickets[ticketIndex] = SupportTicket(
      id: oldTicket.id,
      subject: oldTicket.subject,
      description: oldTicket.description,
      status: oldTicket.status,
      priority: oldTicket.priority,
      createdAt: oldTicket.createdAt,
      updatedAt: DateTime.now(),
      resolvedAt: oldTicket.resolvedAt,
      messages: updatedMessages,
    );

    return newMessage;
  }

  @override
  Future<void> closeTicket(int ticketId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final ticketIndex = _mockTickets.indexWhere((t) => t.id == ticketId);
    if (ticketIndex == -1) {
      throw Exception('Destek talebi bulunamadı');
    }

    final oldTicket = _mockTickets[ticketIndex];
    _mockTickets[ticketIndex] = SupportTicket(
      id: oldTicket.id,
      subject: oldTicket.subject,
      description: oldTicket.description,
      status: SupportTicketStatus.closed,
      priority: oldTicket.priority,
      createdAt: oldTicket.createdAt,
      updatedAt: DateTime.now(),
      resolvedAt: DateTime.now(),
      messages: oldTicket.messages,
    );
  }
}
