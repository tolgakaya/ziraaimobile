import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Voice message player widget with playback controls
/// Displays waveform and allows playing/pausing voice messages
///
/// ⚠️ SECURITY: Requires JWT authentication for secure file access
/// Voice messages are accessed via secure API endpoints
class VoiceMessagePlayer extends StatefulWidget {
  final String voiceUrl;
  final int duration; // in seconds
  final List<double>? waveform;
  final bool isFromCurrentUser;
  final String jwtToken; // JWT token for secure file access

  const VoiceMessagePlayer({
    Key? key,
    required this.voiceUrl,
    required this.duration,
    required this.jwtToken,
    this.waveform,
    this.isFromCurrentUser = false,
  }) : super(key: key);

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _totalDuration = Duration(seconds: widget.duration);
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initAudioPlayer() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading;
        });
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    // Listen to completion
    _audioPlayer.processingStateStream.listen((state) {
      if (mounted && state == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        if (_currentPosition == Duration.zero) {
          setState(() => _isLoading = true);

          // 🔍 DEBUG: Log the URL being played
          print('🎵 VoiceMessagePlayer: Attempting to play URL: ${widget.voiceUrl}');
          print('🔑 VoiceMessagePlayer: JWT token present: ${widget.jwtToken.isNotEmpty}');
          print('🔑 VoiceMessagePlayer: JWT token (first 50 chars): ${widget.jwtToken.substring(0, widget.jwtToken.length > 50 ? 50 : widget.jwtToken.length)}...');
          print('📋 VoiceMessagePlayer: Full headers: ${{'Authorization': 'Bearer ${widget.jwtToken}'}}');

          // ✅ SECURITY: Set audio source with JWT authentication header
          await _audioPlayer.setAudioSource(
            AudioSource.uri(
              Uri.parse(widget.voiceUrl),
              headers: {
                'Authorization': 'Bearer ${widget.jwtToken}',
              },
            ),
          );

          await _audioPlayer.play();
          setState(() => _isLoading = false);
        } else {
          await _audioPlayer.play();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);

      // 🔍 DEBUG: Log the error
      print('❌ VoiceMessagePlayer ERROR: ${e.toString()}');

      // Enhanced error handling for different HTTP status codes
      final errorMessage = e.toString();
      if (errorMessage.contains('401')) {
        _showErrorDialog('Oturum süreniz doldu. Lütfen tekrar giriş yapın.');
      } else if (errorMessage.contains('403')) {
        _showErrorDialog('Bu ses mesajına erişim yetkiniz yok.');
      } else if (errorMessage.contains('404')) {
        _showErrorDialog('Ses mesajı bulunamadı.');
      } else {
        _showErrorDialog('Ses çalınamadı: ${e.toString()}');
      }
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Hata'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _totalDuration.inSeconds > 0
        ? _currentPosition.inSeconds / _totalDuration.inSeconds
        : 0.0;

    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isFromCurrentUser
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: widget.isFromCurrentUser
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                  ),
            onPressed: _isLoading ? null : _togglePlayPause,
          ),

          // Waveform or progress bar
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                // Seek to position when tapping on waveform
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localPosition = box.globalToLocal(details.globalPosition);
                final seekProgress = (localPosition.dx - 48) / (box.size.width - 96);
                final seekPosition = Duration(
                  seconds: (_totalDuration.inSeconds * seekProgress).round(),
                );
                _audioPlayer.seek(seekPosition);
              },
              child: widget.waveform != null && widget.waveform!.isNotEmpty
                  ? CustomPaint(
                      painter: WaveformProgressPainter(
                        waveform: widget.waveform!,
                        progress: progress,
                        color: widget.isFromCurrentUser
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                      size: const Size(double.infinity, 32),
                    )
                  : LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isFromCurrentUser
                            ? Theme.of(context).primaryColor
                            : Colors.black87,
                      ),
                    ),
            ),
          ),

          const SizedBox(width: 8),

          // Duration
          Text(
            _isPlaying || _currentPosition.inSeconds > 0
                ? _formatDuration(_currentPosition)
                : _formatDuration(_totalDuration),
            style: TextStyle(
              fontSize: 12,
              color: widget.isFromCurrentUser
                  ? Theme.of(context).primaryColor
                  : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for waveform with progress indicator
class WaveformProgressPainter extends CustomPainter {
  final List<double> waveform;
  final double progress;
  final Color color;

  WaveformProgressPainter({
    required this.waveform,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final playedPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final unplayedPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / waveform.length;
    final maxHeight = size.height;
    final playedWidth = size.width * progress;

    for (int i = 0; i < waveform.length; i++) {
      final barHeight = waveform[i] * maxHeight * 0.8;
      final x = i * barWidth + barWidth / 2;
      final y1 = (maxHeight - barHeight) / 2;
      final y2 = y1 + barHeight;

      // Use played paint for bars before progress, unplayed paint for rest
      final paint = x <= playedWidth ? playedPaint : unplayedPaint;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.waveform != waveform;
  }
}
