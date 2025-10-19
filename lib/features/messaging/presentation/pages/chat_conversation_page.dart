import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import '../../../../core/utils/service_locator.dart';
import '../bloc/messaging_bloc.dart';
import '../adapters/chat_message_adapter.dart';

class ChatConversationPage extends StatefulWidget {
  final int plantAnalysisId;
  final int farmerId;
  final int sponsorUserId;
  final String? analysisImageUrl;
  final String? analysisSummary;

  const ChatConversationPage({
    Key? key,
    required this.plantAnalysisId,
    required this.farmerId,
    required this.sponsorUserId,
    this.analysisImageUrl,
    this.analysisSummary,
  }) : super(key: key);

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  late final chat_ui.User _currentUser;

  @override
  void initState() {
    super.initState();

    // Current user (Farmer)
    _currentUser = chat_ui.User(
      id: widget.farmerId.toString(),
      firstName: 'Ben',
    );

    // Load conversation
    context.read<MessagingBloc>().add(
          LoadMessagesEvent(
            widget.plantAnalysisId,
            widget.farmerId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocConsumer<MessagingBloc, MessagingState>(
        listener: _handleBlocListener,
        builder: _buildBlocContent,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analiz Mesajları'),
          Text(
            'Analiz #${widget.plantAnalysisId}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _handleBlocListener(BuildContext context, MessagingState state) {
    if (state is MessagingError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Tamam',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Widget _buildBlocContent(BuildContext context, MessagingState state) {
    if (state is MessagingLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (state is MessagesLoaded) {
      return _buildChatInterface(context, state);
    }

    if (state is MessagingError) {
      return _buildErrorState(context, state);
    }

    return const Center(
      child: Text('Bir hata oluştu'),
    );
  }

  Widget _buildChatInterface(BuildContext context, MessagesLoaded state) {
    // Convert domain messages to flutter_chat_ui format
    final chatMessages = ChatMessageAdapter.toFlutterChatMessages(
      state.messages,
      widget.farmerId,
    );

    return Column(
      children: [
        // Analysis context card (if image/summary available)
        if (widget.analysisImageUrl != null || widget.analysisSummary != null)
          _buildAnalysisContextCard(),

        // Chat UI
        Expanded(
          child: chat_ui.Chat(
            messages: chatMessages.reversed.toList(), // flutter_chat_ui wants newest first
            onSendPressed: state.canReply ? _handleSendPressed : null,
            user: _currentUser,
            theme: _buildChatTheme(),
            showUserAvatars: true,
            showUserNames: true,
            dateHeaderBuilder: _buildDateHeader,
            customBottomWidget: !state.canReply ? _buildCannotReplyMessage() : null,
            emptyState: _buildEmptyState(state.canReply),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisContextCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          if (widget.analysisImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                widget.analysisImageUrl!,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
                loadingBuilder: (_, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analiz Hakkında',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (widget.analysisSummary != null)
                  Text(
                    widget.analysisSummary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCannotReplyMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.orange[50],
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sponsor size mesaj gönderdiğinde yanıt verebilirsiniz.',
              style: TextStyle(
                color: Colors.orange[900],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool canReply) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              canReply
                  ? 'Henüz mesaj yok'
                  : 'Sponsor mesaj gönderdiğinde burada görünecek',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, MessagingError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<MessagingBloc>().add(
                      LoadMessagesEvent(
                        widget.plantAnalysisId,
                        widget.farmerId,
                      ),
                    );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Yeniden Dene'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSendPressed(chat_ui.PartialText message) {
    context.read<MessagingBloc>().add(
          SendMessageEvent(
            plantAnalysisId: widget.plantAnalysisId,
            toUserId: widget.sponsorUserId,
            message: message.text,
          ),
        );
  }

  chat_ui.DefaultChatTheme _buildChatTheme() {
    return const chat_ui.DefaultChatTheme(
      primaryColor: Color(0xFF4CAF50), // ZiraAI green
      backgroundColor: Colors.white,
      inputBackgroundColor: Color(0xFFF5F5F5),
      inputTextColor: Colors.black87,
      receivedMessageBodyTextStyle: TextStyle(
        color: Colors.black87,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      sentMessageBodyTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildDateHeader(chat_ui.DateHeader header) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            header.text,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
