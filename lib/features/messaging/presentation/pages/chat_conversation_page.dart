import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../../core/models/message_notification.dart'; // ✅ Import for SignalR real-time messaging
import '../../../../core/di/injection.dart';
import '../bloc/messaging_bloc.dart';
import '../widgets/voice_recorder_widget.dart';
import '../widgets/voice_message_player.dart';
import '../../domain/entities/message.dart';

/// Chat conversation page with avatar and status enhancements
class ChatConversationPage extends StatefulWidget {
  final int plantAnalysisId;
  final int farmerId;
  final int sponsorUserId;
  final String sponsorshipTier; // NEW: Used sponsorship tier (S, M, L, XL)
  final String? analysisImageUrl;
  final String? analysisSummary;

  const ChatConversationPage({
    Key? key,
    required this.plantAnalysisId,
    required this.farmerId,
    required this.sponsorUserId,
    required this.sponsorshipTier,
    this.analysisImageUrl,
    this.analysisSummary,
  }) : super(key: key);

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final _chatController = chat_core.InMemoryChatController();
  late final String _currentUserId;
  final _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];
  bool _isRecordingVoice = false;

  // JWT token for secure file access
  final AuthService _authService = getIt<AuthService>();
  String? _jwtToken;

  // ✅ SignalR service for real-time message updates
  late final SignalRService _signalRService;
  bool _signalRListenerRegistered = false;

  // Store listener reference for cleanup
  late final Function(MessageNotification) _messageListener;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.farmerId.toString();

    // Get JWT token for secure file access
    _loadJwtToken();

    // Load messages - for farmer, the "other user" is the sponsor
    context.read<MessagingBloc>().add(
      LoadMessagesEvent(widget.plantAnalysisId, widget.sponsorUserId),
    );

    // Load messaging features (tier-based) for this specific analysis
    context.read<MessagingBloc>().add(
      LoadMessagingFeaturesEvent(plantAnalysisId: widget.plantAnalysisId),
    );

    // ✅ Setup SignalR listener for real-time messages
    _setupSignalRListener();
  }

  Future<void> _loadJwtToken() async {
    final token = await _authService.getToken();
    if (mounted) {
      setState(() {
        _jwtToken = token;
      });
    }
  }

  /// Setup SignalR listener for real-time message updates
  void _setupSignalRListener() {
    try {
      // ✅ SignalRService is a singleton, NOT registered in GetIt
      _signalRService = SignalRService();

      if (!_signalRService.isConnected) {
        print('⚠️ FARMER CHAT: SignalR not connected, real-time updates disabled');
        return;
      }

      print('✅ FARMER CHAT: Setting up SignalR listener for analysis ${widget.plantAnalysisId}');

      // ✅ CRITICAL FIX: Create listener and store reference for cleanup
      _messageListener = (messageNotification) {
        print('💬 FARMER CHAT: Real-time message received!');
        print('   From: ${messageNotification.fromUserName} (${messageNotification.senderRole})');
        print('   To Analysis: ${messageNotification.plantAnalysisId}');
        print('   THIS Analysis: ${widget.plantAnalysisId}');

        // CRITICAL: Only process if message is for THIS conversation
        if (messageNotification.plantAnalysisId != widget.plantAnalysisId) {
          print('ℹ️ FARMER CHAT: Message is for different analysis, ignoring');
          return;
        }

        print('✅ FARMER CHAT: Message is for this conversation, updating UI...');

        // Convert MessageNotification to Message entity
        // FARMER CHAT: We're the farmer, so:
        // - fromUserId: sponsor (from notification)
        // - toUserId: farmer (us = widget.farmerId)

        // ✅ SignalR notification now includes FULL attachment data from backend!
        final message = Message(
          id: messageNotification.messageId,
          plantAnalysisId: messageNotification.plantAnalysisId,
          fromUserId: messageNotification.fromUserId,
          toUserId: widget.farmerId, // ✅ We are the farmer (receiver)
          message: messageNotification.message,
          status: MessageStatus.sent,
          sentDate: messageNotification.sentDate,
          senderRole: messageNotification.senderRole,
          senderName: messageNotification.fromUserName,
          senderCompany: messageNotification.fromUserCompany ?? '',
          senderAvatarUrl: messageNotification.senderAvatarUrl, // ✅ Now uses actual avatar URL
          senderAvatarThumbnailUrl: messageNotification.senderAvatarThumbnailUrl, // ✅ Now uses actual thumbnail URL
          isRead: false, // ✅ New message is unread
          hasAttachments: messageNotification.hasAttachments,
          attachmentUrls: messageNotification.attachmentUrls,
          attachmentThumbnails: messageNotification.attachmentThumbnails,
          isVoiceMessage: messageNotification.isVoiceMessage,
          voiceMessageUrl: messageNotification.voiceMessageUrl,
          voiceMessageDuration: messageNotification.voiceMessageDuration,
          voiceMessageWaveform: messageNotification.voiceMessageWaveform?.map((e) => e.toDouble()).toList(),
        );

        // Dispatch event to BLoC to update UI
        if (mounted) {
          context.read<MessagingBloc>().add(
            NewMessageReceivedEvent(message),
          );
          print('✅ FARMER CHAT: NewMessageReceivedEvent dispatched');
          
          // ✅ NEW: Auto-mark as read if message is for us and we're viewing the conversation
          if (message.toUserId == widget.farmerId) {
            print('📬 FARMER CHAT: Auto-marking real-time message as read');
            context.read<MessagingBloc>().add(
              MarkMessageAsReadEvent(message.id),
            );
          }
        }
      };

      // ✅ Add listener to SignalR service (supports multiple listeners now)
      _signalRService.addNewMessageListener(_messageListener);
      _signalRListenerRegistered = true;
      print('✅ FARMER CHAT: SignalR listener registered successfully');
    } catch (e) {
      print('❌ FARMER CHAT: Failed to setup SignalR listener: $e');
    }
  }

  /// Mark unread messages as read when conversation is opened
  /// Uses bulk API for better performance
  void _markUnreadMessagesAsRead(List<Message> messages) {
    // Get unread messages sent TO current user (farmer)
    final unreadMessageIds = messages
        .where((msg) => 
            !msg.isRead && 
            msg.toUserId == widget.farmerId
        )
        .map((msg) => msg.id)
        .toList();

    if (unreadMessageIds.isEmpty) {
      print('✅ FARMER CHAT: No unread messages to mark');
      return;
    }

    print('📬 FARMER CHAT: Marking ${unreadMessageIds.length} messages as read');
    
    // ✅ Trigger bulk mark as read event
    context.read<MessagingBloc>().add(
      MarkMessagesAsReadEvent(unreadMessageIds),
    );
  }

  @override
  void dispose() {
    // ✅ CRITICAL: Remove our listener from SignalR service
    if (_signalRListenerRegistered) {
      print('🧹 FARMER CHAT: Removing SignalR listener');
      _signalRService.removeNewMessageListener(_messageListener);
    }
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analiz #${widget.plantAnalysisId}'),
      ),
      body: BlocConsumer<MessagingBloc, MessagingState>(
        listener: (context, state) {
          if (state is MessagingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is MessagesLoaded) {
            _updateMessages(state.messages);
            
            // ✅ NEW: Mark unread messages as read when conversation opens
            _markUnreadMessagesAsRead(state.messages);
          }
        },
        builder: (context, state) {
          if (state is MessagingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          print('🔧 CREATING Chat WIDGET with custom builders');
          final customBuilders = chat_core.Builders(
            textMessageBuilder: (context, message, index, {
              required bool isSentByMe,
              chat_core.MessageGroupStatus? groupStatus,
            }) {
              print('🎨 BUILDING CUSTOM MESSAGE: isSentByMe=$isSentByMe');
              print('🎨 Message metadata: ${message.metadata}');
              return _buildTextMessageWithAvatarStatus(message, isSentByMe);
            },
          );
          print('🔧 Custom builders created: ${customBuilders.textMessageBuilder != null}');

          return Column(
            children: [
              // Image preview section (if images selected)
              if (_selectedImages.isNotEmpty)
                Container(
                  height: 100,
                  color: Colors.grey[100],
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(_selectedImages[index].path)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 24),
                              onPressed: () => _removeImage(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Load More button (if pagination available)
              if (state is MessagesLoaded && state.hasMorePages)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state.isLoadingMore)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () {
                            context.read<MessagingBloc>().add(
                              LoadMoreMessagesEvent(
                                widget.plantAnalysisId,
                                widget.sponsorUserId,
                              ),
                            );
                          },
                          icon: const Icon(Icons.expand_more, size: 18),
                          label: Text('Daha Fazla Mesaj Yükle (${state.totalRecords - state.messages.length} kaldı)'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                    ],
                  ),
                ),

              // Chat UI
              Expanded(
                child: Stack(
                  children: [
                    chat_ui.Chat(
                      key: ValueKey('farmer_chat_${widget.plantAnalysisId}_${widget.sponsorUserId}'),
                      currentUserId: _currentUserId,
                      chatController: _chatController,
                      resolveUser: (userId) async {
                        return chat_core.User(
                          id: userId,
                          name: userId == _currentUserId ? 'Ben' : 'Sponsor',
                        );
                      },
                      onMessageSend: _sendWithAttachments,
                      builders: customBuilders,
                    ),
                    // Attachment button positioned over input area (only if not recording)
                    if (!_isRecordingVoice)
                      _buildAttachmentButton(state),
                    // Voice recording button (only if not recording and no attachments selected)
                    if (!_isRecordingVoice && _selectedImages.isEmpty)
                      _buildVoiceButton(state),
                  ],
                ),
              ),

              // ✅ NEW: Voice recorder overlay (when recording)
              if (_isRecordingVoice)
                VoiceRecorderWidget(
                  onSendVoice: (filePath, duration, waveform) {
                    // Send voice message
                    context.read<MessagingBloc>().add(
                      SendVoiceMessageEvent(
                        plantAnalysisId: widget.plantAnalysisId,
                        toUserId: widget.sponsorUserId,
                        voiceFilePath: filePath,
                        duration: duration,
                        waveform: waveform,
                      ),
                    );
                    setState(() {
                      _isRecordingVoice = false;
                    });
                  },
                  onCancel: () {
                    setState(() {
                      _isRecordingVoice = false;
                    });
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  void _updateMessages(List messages) {
    print('📝 _updateMessages called with ${messages.length} messages');
    
    // Clear existing messages first to avoid duplicates
    while (_chatController.messages.isNotEmpty) {
      _chatController.removeMessage(_chatController.messages.first);
    }
    print('📝 Cleared all messages from controller');
    
    // Insert all messages in chronological order (oldest to newest)
    // flutter_chat_ui will display them with newest at bottom
    for (var msg in messages) {
      final textMessage = chat_core.TextMessage(
        id: msg.id.toString(),
        authorId: msg.fromUserId.toString(),
        createdAt: msg.sentDate.toUtc(),
        text: msg.message,
        metadata: {
          'messageStatus': msg.status.toString().split('.').last,  // Convert enum to string (e.g., "sent", "delivered", "read")
          'senderAvatarUrl': msg.senderAvatarUrl,
          'senderAvatarThumbnailUrl': msg.senderAvatarThumbnailUrl,
          'attachmentUrls': msg.attachmentUrls,
          'attachmentThumbnails': msg.attachmentThumbnails,  // ✅ NEW: Thumbnail URLs
          'hasAttachments': msg.hasAttachments,
          // ✅ NEW: Voice message metadata
          'isVoiceMessage': msg.isVoiceMessage,
          'voiceMessageUrl': msg.voiceMessageUrl,
          'voiceMessageDuration': msg.voiceMessageDuration,
          'voiceMessageWaveform': msg.voiceMessageWaveform,
        },
      );
      print('📝 Inserting TextMessage: id=${textMessage.id}, authorId=${textMessage.authorId}, metadata=${textMessage.metadata}');
      _chatController.insertMessage(textMessage);
    }
    print('📝 Total messages in controller: ${_chatController.messages.length}');
  }

  /// Build avatar widget for received messages
  Widget _buildMessageAvatar(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) {
      // Default avatar - gray circle with person icon
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          size: 20,
          color: Colors.grey,
        ),
      );
    }

    // Network image with loading and error handling
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: ClipOval(
        child: Image.network(
          avatarUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 32,
              height: 32,
              color: Colors.grey[200],
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 32,
              height: 32,
              color: Colors.grey[300],
              child: const Icon(
                Icons.person,
                size: 20,
                color: Colors.grey,
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build message status checkmarks for sent messages
  Widget _buildMessageStatus(String? messageStatus) {
    final status = messageStatus?.toLowerCase() ?? 'sent';

    if (status.contains('read')) {
      // Read - double checkmark (blue)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.done_all, size: 16, color: Colors.blue),
          SizedBox(width: 2),
          Text('Read', style: TextStyle(fontSize: 10, color: Colors.blue)),
        ],
      );
    } else if (status.contains('delivered')) {
      // Delivered - double checkmark (gray)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 2),
          Text('Delivered', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      );
    } else {
      // Sent - single checkmark (gray)
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 2),
          Text('Sent', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      );
    }
  }

  /// Pick images from gallery
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Resim seçilirken hata oluştu')),
      );
    }
  }

  /// Pick image from camera
  Future<void> _pickFromCamera() async {
    try {
      // Request camera permission explicitly using permission_handler
      // This prevents conflicts with telephony package's permission handling
      final cameraPermission = await Permission.camera.request();
      
      if (!cameraPermission.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kamera izni gerekli')),
        );
        return;
      }

      // Small delay to ensure permission callback is processed
      await Future.delayed(const Duration(milliseconds: 200));

      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _selectedImages.add(photo);
        });
      }
  } catch (e) {
      print('Error taking photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotoğraf çekilirken hata oluştu')),
      );
    }
  }

  /// Remove selected image
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  /// Open attachment in full screen or download
  void _openAttachment(String url, List<String> allUrls) {
    // Check file type from URL
    final lowerUrl = url.toLowerCase();
    
    // ✅ NEW: Check for secure API endpoints (no file extension in URL)
    // Backend's new secure file serving: /api/v1/files/attachments/{id}/{index}
    final isSecureAttachmentEndpoint = lowerUrl.contains('/files/attachments/') || 
                                        lowerUrl.contains('/files/attachment-thumbnails/');
    
    if (isSecureAttachmentEndpoint ||
        lowerUrl.endsWith('.jpg') || 
        lowerUrl.endsWith('.jpeg') || 
        lowerUrl.endsWith('.png') || 
        lowerUrl.endsWith('.gif') ||
        lowerUrl.contains('image')) {
      // Open image in full-screen viewer
      _openImageGallery(allUrls, allUrls.indexOf(url));
    } else if (lowerUrl.endsWith('.pdf')) {
      // Open PDF viewer or download
      _handlePdfAttachment(url);
    } else {
      // Generic file download
      _downloadFile(url);
    }
  }

  /// Open image gallery in full screen
  /// ✅ SECURITY: Passes JWT token for secure file access
  void _openImageGallery(List<String> imageUrls, int initialIndex) {
    if (_jwtToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum gerekli. Lütfen tekrar giriş yapın.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageGallery(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
          jwtToken: _jwtToken!,
        ),
      ),
    );
  }

  /// Handle PDF attachment
  void _handlePdfAttachment(String url) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_browser),
              title: const Text('Tarayıcıda Aç'),
              onTap: () {
                Navigator.pop(context);
                _openInBrowser(url);
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('İndir'),
              onTap: () {
                Navigator.pop(context);
                _downloadFile(url);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Open URL in browser
  void _openInBrowser(String url) {
    // TODO: Use url_launcher package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Açılıyor: $url')),
    );
  }

  /// Download file to device
  void _downloadFile(String url) {
    // TODO: Implement file download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dosya indirme özelliği yakında eklenecek')),
    );
  }

  /// Send message with attachments
  void _sendWithAttachments(String text) {
    print('🔷 _sendWithAttachments called: text="$text", images=${_selectedImages.length}');
    
    if (_selectedImages.isEmpty) {
      print('📤 No attachments, sending regular message');
      // No attachments, send regular message
      context.read<MessagingBloc>().add(
        SendMessageEvent(
          plantAnalysisId: widget.plantAnalysisId,
          toUserId: widget.sponsorUserId,
          message: text,
        ),
      );
    } else {
      // Send with attachments
      print('📎 Sending with ${_selectedImages.length} attachments');
      final attachmentPaths = _selectedImages.map((img) => img.path).toList();
      print('📎 Attachment paths: $attachmentPaths');
      context.read<MessagingBloc>().add(
        SendMessageWithAttachmentsEvent(
          plantAnalysisId: widget.plantAnalysisId,
          toUserId: widget.sponsorUserId,
          message: text.isEmpty ? 'Resim gönderildi' : text,
          attachmentPaths: attachmentPaths,
        ),
      );
      
      // Clear selected images after sending
      setState(() {
        _selectedImages.clear();
      });
    }
  }

  /// Show attachment options (camera or gallery)
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Fotoğraf Çek'),
              onTap: () {
                Navigator.pop(context);
                _pickFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build attachment grid for messages with images
  /// ✅ SECURITY: Uses CachedNetworkImage with JWT authentication headers
  Widget _buildAttachmentGrid({
    required List<String>? thumbnailUrls,
    required List<String>? fullUrls,
  }) {
    if (thumbnailUrls == null || thumbnailUrls.isEmpty) {
      return const SizedBox.shrink();
    }
    
    if (fullUrls == null || fullUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    // If JWT token not available, show authentication required message
    if (_jwtToken == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.lock_outline, color: Colors.red, size: 16),
            SizedBox(width: 8),
            Text(
              'Dosyaları görüntülemek için oturum gerekli',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: thumbnailUrls.length > 4 ? 4 : thumbnailUrls.length,
      itemBuilder: (context, index) {
        final thumbnailUrl = thumbnailUrls[index];
        final fullUrl = fullUrls[index];
        return GestureDetector(
          onTap: () => _openAttachment(fullUrl, fullUrls),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
            children: [
              // ✅ SECURITY: CachedNetworkImage with JWT authentication
              // Display thumbnail for efficiency, click opens full image
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                httpHeaders: {
                  'Authorization': 'Bearer $_jwtToken',
                },
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  print('🖼️ LOADING thumbnail: $url');
                  print('   JWT: ${_jwtToken?.substring(0, 20)}...');
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  print('❌ THUMBNAIL ERROR: $url');
                  print('   Error: $error');
                  return Container(
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image, color: Colors.red, size: 32),
                        Text(
                          'Hata',
                          style: TextStyle(color: Colors.red, fontSize: 10),
                        ),
                      ],
                    ),
                  );
                },
              ),
              // Show count indicator if more than 4 images
              if (index == 3 && thumbnailUrls.length > 4)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+${thumbnailUrls.length - 4}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
          );
      },
    );
  }

  /// Wrapper that adds avatar and status to text messages
  Widget _buildTextMessageWithAvatarStatus(chat_core.TextMessage message, bool isSentByMe) {
    final avatarUrl = message.metadata?['senderAvatarThumbnailUrl'] as String?;
    final messageStatus = message.metadata?['messageStatus'] as String?;

    // ✅ FIXED: Safe casting from List<dynamic> to List<String>
    // Backend sends List<dynamic>, we need List<String>
    final attachmentUrlsDynamic = message.metadata?['attachmentUrls'] as List?;
    final attachmentUrls = attachmentUrlsDynamic?.cast<String>().toList();
    
    // ✅ NEW: Get thumbnail URLs (for efficient display in chat)
    final attachmentThumbnailsDynamic = message.metadata?['attachmentThumbnails'] as List?;
    final attachmentThumbnails = attachmentThumbnailsDynamic?.cast<String>().toList();
    
    final hasAttachments = attachmentUrls != null && attachmentUrls.isNotEmpty;

    // ✅ Voice message support with secure HTTPS API endpoints
    final isVoiceMessage = message.metadata?['isVoiceMessage'] as bool? ?? false;
    var voiceMessageUrl = message.metadata?['voiceMessageUrl'] as String?;

    // ⚠️ HOTFIX: Convert HTTP to HTTPS for backward compatibility
    // Some old messages may still have HTTP URLs cached
    if (voiceMessageUrl != null && voiceMessageUrl.startsWith('http://')) {
      voiceMessageUrl = voiceMessageUrl.replaceFirst('http://', 'https://');
    }

    final voiceMessageDuration = message.metadata?['voiceMessageDuration'] as int? ?? 0;

    // ✅ FIXED: Safe casting from List<dynamic> to List<double>
    final waveformDynamic = message.metadata?['voiceMessageWaveform'] as List?;
    final voiceMessageWaveform = waveformDynamic?.cast<double>().toList();

    print('🎯 _buildTextMessageWithAvatarStatus: avatarUrl=$avatarUrl, status=$messageStatus');
    print('   📎 Attachments: fullUrls=${attachmentUrls?.length ?? 0}, thumbnails=${attachmentThumbnails?.length ?? 0}');
    print('   🎤 Voice: isVoice=$isVoiceMessage, voiceUrl=$voiceMessageUrl');
    if (attachmentUrls != null && attachmentUrls.isNotEmpty) {
      print('   📷 Full URLs: ${attachmentUrls.take(2).join(", ")}${attachmentUrls.length > 2 ? "..." : ""}');
    }
    if (attachmentThumbnails != null && attachmentThumbnails.isNotEmpty) {
      print('   🖼️ Thumbnails: ${attachmentThumbnails.take(2).join(", ")}${attachmentThumbnails.length > 2 ? "..." : ""}');
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isSentByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          // Avatar on left (only for received messages)
          if (!isSentByMe) ...[
            _buildMessageAvatar(avatarUrl),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isSentByMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSentByMe ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✅ Voice message player with JWT authentication
                      if (isVoiceMessage && voiceMessageUrl != null && _jwtToken != null)
                        VoiceMessagePlayer(
                          voiceUrl: voiceMessageUrl,
                          duration: voiceMessageDuration,
                          jwtToken: _jwtToken!,
                          waveform: voiceMessageWaveform,
                          isFromCurrentUser: isSentByMe,
                        )
                      // Show error if voice message but no token
                      else if (isVoiceMessage && voiceMessageUrl != null && _jwtToken == null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.error_outline, color: Colors.red, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Oturum gerekli',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      // Attachment grid (if present and not voice message)
                      else if (hasAttachments) ...[
                        SizedBox(
                          width: 200,
                          height: attachmentUrls.length == 1 ? 150 : 200,
                          child: _buildAttachmentGrid(
                            thumbnailUrls: attachmentThumbnails ?? attachmentUrls,
                            fullUrls: attachmentUrls,
                          ),
                        ),
                        if (message.text.isNotEmpty) const SizedBox(height: 8),
                      ],

                      // Text message (only if not voice message or has text)
                      if (!isVoiceMessage && message.text.isNotEmpty)
                        Text(
                          message.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                    ],
                  ),
                ),

                // Status below message (only for sent messages)
                if (isSentByMe) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildMessageStatus(messageStatus),
                  ),
                ],
              ],
            ),
          ),

          // Spacer on right (balance the avatar on sent messages)
          if (isSentByMe) const SizedBox(width: 40),
        ],
      ),
    );
  }

  /// Build attachment button with feature check
  Widget _buildAttachmentButton(MessagingState state) {
    // Get features from state OR from BLoC's cached features
    // This ensures features are available even before messages are loaded
    final bloc = context.read<MessagingBloc>();
    final features = (state is MessagesLoaded ? state.features : null) ?? bloc.cachedFeatures;
    final imageFeature = features?.imageAttachments;
    final fileFeature = features?.fileAttachments;
    final videoFeature = features?.videoAttachments;

    // ✅ Check if current tier meets any attachment feature requirement
    // Note: We only check tier, not API's "available" field, because API checks user's subscription tier,
    // but we need to check this specific analysis's sponsorship tier
    final canUseImageAttachment = imageFeature != null && _isTierSufficient(imageFeature.requiredTier);
    final canUseFileAttachment = fileFeature != null && _isTierSufficient(fileFeature.requiredTier);
    final canUseVideoAttachment = videoFeature != null && _isTierSufficient(videoFeature.requiredTier);

    final hasAnyAttachmentFeature = canUseImageAttachment || canUseFileAttachment || canUseVideoAttachment;

    // 🔍 DEBUG
    print('📎 ATTACHMENT DEBUG:');
    print('   Current Tier: ${widget.sponsorshipTier}');
    print('   Image Feature - enabled: ${imageFeature?.enabled}, requiredTier: ${imageFeature?.requiredTier}, canUse: $canUseImageAttachment');
    print('   File Feature - enabled: ${fileFeature?.enabled}, requiredTier: ${fileFeature?.requiredTier}, canUse: $canUseFileAttachment');
    print('   Video Feature - enabled: ${videoFeature?.enabled}, requiredTier: ${videoFeature?.requiredTier}, canUse: $canUseVideoAttachment');
    print('   hasAnyAttachmentFeature: $hasAnyAttachmentFeature');

    return Positioned(
      bottom: 16,
      left: 16,
      child: FloatingActionButton.small(
        onPressed: () {
          if (hasAnyAttachmentFeature) {
            _showAttachmentOptions();
          } else {
            _showTierUpgradeDialog(
              featureName: 'Dosya Ekleme',
              requiredTier: imageFeature?.requiredTier ?? 'L',
              unavailableReason: 'Bu analiz ${widget.sponsorshipTier} tier ile yapıldı. Dosya ekleme için en az ${imageFeature?.requiredTier ?? "L"} tier gereklidir.',
            );
          }
        },
        backgroundColor: hasAnyAttachmentFeature ? Colors.blue : Colors.grey,
        child: const Icon(Icons.attach_file, color: Colors.white),
      ),
    );
  }

  /// Build voice button with feature check
  Widget _buildVoiceButton(MessagingState state) {
    // Get features from state OR from BLoC's cached features
    // This ensures features are available even before messages are loaded
    final bloc = context.read<MessagingBloc>();
    final features = (state is MessagesLoaded ? state.features : null) ?? bloc.cachedFeatures;
    final voiceFeature = features?.voiceMessages;

    // ✅ Check if current tier meets voice message requirement
    // Note: We only check tier, not API's "available" field, because API checks user's subscription tier,
    // but we need to check this specific analysis's sponsorship tier
    final isAvailable = voiceFeature != null && _isTierSufficient(voiceFeature.requiredTier);

    return Positioned(
      bottom: 16,
      right: 80,
      child: FloatingActionButton.small(
        onPressed: () {
          if (isAvailable) {
            setState(() {
              _isRecordingVoice = true;
            });
          } else {
            _showTierUpgradeDialog(
              featureName: 'Sesli Mesaj',
              requiredTier: voiceFeature?.requiredTier ?? 'XL',
              unavailableReason: 'Bu analiz ${widget.sponsorshipTier} tier ile yapıldı. Sesli mesaj için en az ${voiceFeature?.requiredTier ?? "XL"} tier gereklidir.',
            );
          }
        },
        backgroundColor: isAvailable ? Colors.red : Colors.grey,
        child: const Icon(Icons.mic, color: Colors.white, size: 24),
      ),
    );
  }

  /// Helper: Check if current sponsorship tier meets required tier
  /// Tier hierarchy: S < M < L < XL
  bool _isTierSufficient(String requiredTier) {
    const tierHierarchy = {'S': 1, 'M': 2, 'L': 3, 'XL': 4};

    final currentTierValue = tierHierarchy[widget.sponsorshipTier.toUpperCase()] ?? 0;
    final requiredTierValue = tierHierarchy[requiredTier.toUpperCase()] ?? 0;

    return currentTierValue >= requiredTierValue;
  }

  /// Show tier upgrade dialog when feature is not available
  void _showTierUpgradeDialog({
    required String featureName,
    required String requiredTier,
    String? unavailableReason,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$featureName Özelliği Kullanılamıyor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              unavailableReason ?? '$featureName özelliği için $requiredTier tier paketi gereklidir.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Gerekli Tier: $requiredTier',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to subscription upgrade page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Paket yükseltme sayfası yakında eklenecek'),
                ),
              );
            },
            child: const Text('Paketi Yükselt'),
          ),
        ],
      ),
    );
  }
}

/// Full-screen image gallery viewer
/// Full-screen image gallery with secure file access
/// ✅ SECURITY: Requires JWT authentication for viewing attachments
class _FullScreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String jwtToken;

  const _FullScreenImageGallery({
    required this.imageUrls,
    required this.initialIndex,
    required this.jwtToken,
  });

  @override
  State<_FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<_FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Implement download
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('İndirme özelliği yakında eklenecek')),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              // ✅ SECURITY: CachedNetworkImage with JWT authentication
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                httpHeaders: {
                  'Authorization': 'Bearer ${widget.jwtToken}',
                },
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, color: Colors.white, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Resim yüklenemedi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

