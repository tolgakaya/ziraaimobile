import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection.dart';
import '../bloc/messaging_bloc.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/get_messages_usecase.dart';

class MessageDetailPage extends StatefulWidget {
  final int plantAnalysisId;
  final int farmerId;
  final String farmerName;
  final bool canMessage;

  const MessageDetailPage({
    super.key,
    required this.plantAnalysisId,
    required this.farmerId,
    required this.farmerName,
    required this.canMessage,
  });

  @override
  State<MessageDetailPage> createState() => _MessageDetailPageState();
}

class _MessageDetailPageState extends State<MessageDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final MessagingBloc _messagingBloc;

  @override
  void initState() {
    super.initState();
    // ✅ SOLUTION: Manuel bloc instantiation - GetIt factory sorununu bypass eder
    _messagingBloc = MessagingBloc(
      sendMessageUseCase: getIt<SendMessageUseCase>(),
      getMessagesUseCase: getIt<GetMessagesUseCase>(),
    )..add(LoadMessagesEvent(widget.plantAnalysisId, widget.farmerId));
  }

  @override
  void dispose() {
    _messagingBloc.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messagingBloc.add(
          SendMessageEvent(
            plantAnalysisId: widget.plantAnalysisId,
            toUserId: widget.farmerId,
            message: message,
          ),
        );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _messagingBloc,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.farmerName),
              Text(
                'Analiz #${widget.plantAnalysisId}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocConsumer<MessagingBloc, MessagingState>(
                listener: (context, state) {
                  if (state is MessageSendError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is MessagingLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is MessagingError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(state.message),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _messagingBloc.add(
                                  LoadMessagesEvent(widget.plantAnalysisId, widget.farmerId),
                                ),
                            child: const Text('Yeniden Dene'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is MessagesLoaded || state is MessageSendError) {
                    final messages = state is MessagesLoaded
                        ? state.messages
                        : (state as MessageSendError).currentMessages;

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz mesaj yok',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.canMessage ? 'Konuşmayı başlatın!' : 'Mesajları görüntüleyin',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.senderRole == 'Sponsor';

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (message.senderCompany != null)
                                  Text(
                                    message.senderCompany!,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                Text(message.message),
                                const SizedBox(height: 4),
                                Text(
                                  message.sentDate.toString().substring(0, 16),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
            if (widget.canMessage)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Mesajınızı yazın...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
