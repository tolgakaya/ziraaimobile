import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' as chat_ui;
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/messaging_bloc.dart';

/// Chat conversation page with avatar and status enhancements
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
  final _chatController = chat_core.InMemoryChatController();
  late final String _currentUserId;
  final _imagePicker = ImagePicker();
  final List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.farmerId.toString();

    // Load messages - for farmer, the "other user" is the sponsor
    context.read<MessagingBloc>().add(
      LoadMessagesEvent(widget.plantAnalysisId, widget.sponsorUserId),
    );
  }

  @override
  void dispose() {
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
                    // Attachment button positioned over input area
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: FloatingActionButton.small(
                        onPressed: _showAttachmentOptions,
                        backgroundColor: Colors.blue,
                        child: const Icon(Icons.attach_file, color: Colors.white),
                      ),
                    ),
                  ],
                ),
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
          'hasAttachments': msg.hasAttachments,
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
    
    if (lowerUrl.endsWith('.jpg') || 
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
  void _openImageGallery(List<String> imageUrls, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenImageGallery(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
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
  Widget _buildAttachmentGrid(List<String>? attachmentUrls) {
    if (attachmentUrls == null || attachmentUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: attachmentUrls.length > 4 ? 4 : attachmentUrls.length,
      itemBuilder: (context, index) {
        final url = attachmentUrls[index];
        return GestureDetector(
          onTap: () => _openAttachment(url, attachmentUrls),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),
              // Show count indicator if more than 4 images
              if (index == 3 && attachmentUrls.length > 4)
                Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      '+${attachmentUrls.length - 4}',
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
    final attachmentUrls = message.metadata?['attachmentUrls'] as List<String>?;
    final hasAttachments = attachmentUrls != null && attachmentUrls.isNotEmpty;
    print('🎯 _buildTextMessageWithAvatarStatus: avatarUrl=$avatarUrl, status=$messageStatus, attachments=${attachmentUrls?.length ?? 0}');

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
                      // Attachment grid (if present)
                      if (hasAttachments) ...[
                        SizedBox(
                          width: 200,
                          height: attachmentUrls.length == 1 ? 150 : 200,
                          child: _buildAttachmentGrid(attachmentUrls),
                        ),
                        if (message.text.isNotEmpty) const SizedBox(height: 8),
                      ],
                      
                      // Text message
                      if (message.text.isNotEmpty)
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
}

/// Full-screen image gallery viewer
class _FullScreenImageGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageGallery({
    required this.imageUrls,
    required this.initialIndex,
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
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
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
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

