import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'support_ticket_detail_screen.dart';
import '../../domain/entities/support_ticket.dart';
import '../bloc/support_ticket_bloc.dart';
import '../bloc/support_ticket_event.dart';
import '../bloc/support_ticket_state.dart';

/// Support Ticket List Screen
/// Displays all support tickets for the user
class SupportTicketListScreen extends StatelessWidget {
  const SupportTicketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GetIt.instance<SupportTicketBloc>()
        ..add(const LoadSupportTickets()),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: const Text('Destek Talepleri'),
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF111827),
              elevation: 0,
            ),
            body: BlocConsumer<SupportTicketBloc, SupportTicketState>(
              listener: (context, state) {
                if (state is SupportTicketCreated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Destek talebi oluşturuldu'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Reload tickets
                  context.read<SupportTicketBloc>().add(const LoadSupportTickets());
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

                if (state is SupportTicketListLoaded) {
                  if (state.tickets.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildTicketList(context, state.tickets);
                }

                if (state is SupportTicketError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        Text(state.message, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<SupportTicketBloc>().add(const LoadSupportTickets());
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showCreateTicketDialog(context),
              backgroundColor: const Color(0xFF059669),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Talep'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.support_agent,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz destek talebiniz yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yardıma ihtiyacınız olduğunda yeni bir talep oluşturabilirsiniz.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList(BuildContext context, List<SupportTicket> tickets) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return _buildTicketCard(context, ticket);
      },
    );
  }

  Widget _buildTicketCard(BuildContext context, SupportTicket ticket) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SupportTicketDetailScreen(ticketId: ticket.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(ticket.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPriorityIndicator(ticket.priority),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const Spacer(),
                  if (ticket.messages.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${ticket.messages.length}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dk önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void _showCreateTicketDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    SupportTicketCategory selectedCategory = SupportTicketCategory.general;
    SupportTicketPriority selectedPriority = SupportTicketPriority.normal;

    // Get bloc from parent context before showing dialog
    final bloc = context.read<SupportTicketBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.support_agent,
                            color: Color(0xFF059669),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Yeni Destek Talebi',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Size en kısa sürede yardımcı olacağız',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: Icon(
                            Icons.close,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Form content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Subject field
                          _buildFormLabel('Konu', Icons.title),
                          const SizedBox(height: 8),
                          TextField(
                            controller: subjectController,
                            decoration: InputDecoration(
                              hintText: 'Sorununuzu kısaca açıklayın',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Description field
                          _buildFormLabel('Açıklama', Icons.description),
                          const SizedBox(height: 8),
                          TextField(
                            controller: descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: 'Sorununuzu detaylı bir şekilde açıklayın...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: const Color(0xFFF9FAFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Category and Priority in row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Kategori', Icons.category),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: DropdownButtonFormField<SupportTicketCategory>(
                                        value: selectedCategory,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                                        items: SupportTicketCategory.values.map((category) {
                                          return DropdownMenuItem(
                                            value: category,
                                            child: Text(
                                              category.displayName,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedCategory = value ?? SupportTicketCategory.general;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildFormLabel('Öncelik', Icons.flag),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: DropdownButtonFormField<SupportTicketPriority>(
                                        value: selectedPriority,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                        ),
                                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                                        items: SupportTicketPriority.values.map((priority) {
                                          return DropdownMenuItem(
                                            value: priority,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color: _getPriorityColor(priority),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  priority.displayName,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedPriority = value ?? SupportTicketPriority.normal;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom action buttons
                  Container(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'İptal',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              if (subjectController.text.trim().isEmpty ||
                                  descriptionController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.warning_amber, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text('Lütfen tüm alanları doldurun'),
                                      ],
                                    ),
                                    backgroundColor: Colors.red.shade400,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                return;
                              }

                              bloc.add(CreateSupportTicket(
                                subject: subjectController.text.trim(),
                                description: descriptionController.text.trim(),
                                category: selectedCategory,
                                priority: selectedPriority,
                              ));

                              Navigator.of(sheetContext).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Talep Oluştur',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFormLabel(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(SupportTicketPriority priority) {
    switch (priority) {
      case SupportTicketPriority.low:
        return Colors.grey;
      case SupportTicketPriority.normal:
        return Colors.blue;
      case SupportTicketPriority.high:
        return Colors.orange;
    }
  }
}
