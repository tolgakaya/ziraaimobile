import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/support_ticket.dart';
import '../bloc/support_ticket_bloc.dart';
import '../bloc/support_ticket_event.dart';
import '../bloc/support_ticket_state.dart';

/// Support Ticket Detail Screen
/// Shows ticket details and conversation
class SupportTicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const SupportTicketDetailScreen({
    super.key,
    required this.ticketId,
  });

  @override
  State<SupportTicketDetailScreen> createState() =>
      _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<SupportTicketBloc>()
        ..add(LoadSupportTicketDetail(widget.ticketId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text('Destek Talebi'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
          actions: [
            BlocBuilder<SupportTicketBloc, SupportTicketState>(
              builder: (context, state) {
                if (state is SupportTicketDetailLoaded && state.ticket.isOpen) {
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'close') {
                        _showCloseConfirmDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'close',
                        child: Row(
                          children: [
                            Icon(Icons.close, size: 20),
                            SizedBox(width: 8),
                            Text('Talebi Kapat'),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<SupportTicketBloc, SupportTicketState>(
          listener: (context, state) {
            if (state is SupportTicketMessageAdded) {
              _messageController.clear();
              WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
            } else if (state is SupportTicketClosed) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Destek talebi kapatıldı'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.pop(context);
            } else if (state is SupportTicketRated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Değerlendirmeniz kaydedildi'),
                  backgroundColor: Colors.green,
                ),
              );
              // Reload ticket to update UI
              context.read<SupportTicketBloc>().add(LoadSupportTicketDetail(widget.ticketId));
            } else if (state is SupportTicketError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SupportTicketLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            SupportTicket? ticket;
            if (state is SupportTicketDetailLoaded) {
              ticket = state.ticket;
            } else if (state is SupportTicketMessageAdded) {
              ticket = state.ticket;
            }

            if (ticket == null) {
              return const Center(child: Text('Destek talebi bulunamadı'));
            }

            return Column(
              children: [
                // Ticket Info Header
                _buildTicketHeader(ticket),
                // Rating section (for resolved/closed tickets without rating)
                if (ticket.canRate) _buildRatingSection(context, ticket),
                // Messages List
                Expanded(
                  child: _buildMessagesList(ticket),
                ),
                // Message Input (only if ticket is open)
                if (ticket.isOpen) _buildMessageInput(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTicketHeader(SupportTicket ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              _buildStatusChip(ticket.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPriorityIndicator(ticket.priority),
              const SizedBox(width: 16),
              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd/MM/yyyy HH:mm').format(ticket.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, SupportTicket ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 1),
      color: Colors.amber.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Hizmetimizi Değerlendirin',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => _showRatingDialog(context, index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.star_border,
                    color: Colors.amber.shade600,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, int initialRating) {
    int selectedRating = initialRating;
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Değerlendirme'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Destek hizmetimizi nasıl buldunuz?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedRating = index + 1;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            index < selectedRating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Geri bildirim (opsiyonel)',
                      hintText: 'Görüşlerinizi paylaşın...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.read<SupportTicketBloc>().add(
                          RateSupportTicket(
                            ticketId: widget.ticketId,
                            rating: selectedRating,
                            feedback: feedbackController.text.trim().isEmpty
                                ? null
                                : feedbackController.text.trim(),
                          ),
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                  ),
                  child: const Text('Gönder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessagesList(SupportTicket ticket) {
    if (ticket.messages.isEmpty) {
      return Center(
        child: Text(
          'Henüz mesaj yok',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: ticket.messages.length,
      itemBuilder: (context, index) {
        final message = ticket.messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(SupportTicketMessage message) {
    final isFromSupport = message.isAdminResponse;

    return Align(
      alignment: isFromSupport ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isFromSupport ? Colors.white : const Color(0xFF059669),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isFromSupport ? 4 : 16),
            bottomRight: Radius.circular(isFromSupport ? 16 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isFromSupport)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.support_agent,
                        size: 14,
                        color: const Color(0xFF059669),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Destek Ekibi',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(
                  fontSize: 14,
                  color: isFromSupport ? const Color(0xFF111827) : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isFromSupport
                      ? Colors.grey.shade500
                      : Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: () {
                  final message = _messageController.text.trim();
                  if (message.isNotEmpty) {
                    context.read<SupportTicketBloc>().add(
                          AddTicketMessage(
                            ticketId: widget.ticketId,
                            content: message,
                          ),
                        );
                  }
                },
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(SupportTicketStatus status) {
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case SupportTicketStatus.open:
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        break;
      case SupportTicketStatus.inProgress:
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        break;
      case SupportTicketStatus.resolved:
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        break;
      case SupportTicketStatus.closed:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPriorityIndicator(SupportTicketPriority priority) {
    Color color;
    switch (priority) {
      case SupportTicketPriority.low:
        color = Colors.grey;
        break;
      case SupportTicketPriority.normal:
        color = Colors.blue;
        break;
      case SupportTicketPriority.high:
        color = Colors.orange;
        break;
    }

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          priority.displayName,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  void _showCloseConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Talebi Kapat'),
          content: const Text(
            'Bu destek talebini kapatmak istediğinize emin misiniz? '
            'Kapatılan taleplere mesaj gönderemezsiniz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<SupportTicketBloc>().add(
                      CloseSupportTicket(widget.ticketId),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }
}
