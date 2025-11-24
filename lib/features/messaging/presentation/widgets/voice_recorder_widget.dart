import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/utils/minimal_service_locator.dart';

/// Voice recorder widget with waveform visualization
/// Allows recording, canceling, and sending voice messages
class VoiceRecorderWidget extends StatefulWidget {
  final Function(String filePath, int duration, List<double> waveform) onSendVoice;
  final VoidCallback onCancel;

  const VoiceRecorderWidget({
    Key? key,
    required this.onSendVoice,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<VoiceRecorderWidget> createState() => _VoiceRecorderWidgetState();
}

class _VoiceRecorderWidgetState extends State<VoiceRecorderWidget> {
  final AudioRecorder _recorder = AudioRecorder();
  final PermissionService _permissionService = getIt<PermissionService>();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  String? _recordingPath;
  final List<double> _waveform = [];

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Use centralized permission service to prevent crashes
      final granted = await _permissionService.requestMicrophonePermission();

      if (!granted) {
        widget.onCancel();
        _showPermissionDeniedDialog();
        return;
      }

      // Small delay to ensure permission callback is processed
      await Future.delayed(const Duration(milliseconds: 200));

      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Start recording
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordingPath = filePath;
      });

      // Start timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        setState(() {
          _recordDuration++;
        });

        // Get amplitude for waveform visualization
        final amplitude = await _recorder.getAmplitude();
        if (amplitude.current > -160.0) {
          // Normalize amplitude to 0.0-1.0 range
          final normalizedAmplitude = (amplitude.current + 160.0) / 160.0;
          setState(() {
            _waveform.add(normalizedAmplitude.clamp(0.0, 1.0));
          });
        }

        // Auto-stop after 5 minutes
        if (_recordDuration >= 300) {
          _stopRecording();
        }
      });
    } catch (e) {
      widget.onCancel();
      _showErrorDialog('Ses kaydı başlatılamadı: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      _timer?.cancel();

      if (path != null && _recordDuration > 0) {
        widget.onSendVoice(path, _recordDuration, _waveform);
      } else {
        widget.onCancel();
      }
    } catch (e) {
      widget.onCancel();
      _showErrorDialog('Ses kaydı durdurulamadı: ${e.toString()}');
    }
  }

  void _cancelRecording() async {
    try {
      await _recorder.stop();
      _timer?.cancel();

      // Delete the recording file
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      widget.onCancel();
    } catch (e) {
      widget.onCancel();
    }
  }

  void _showPermissionDeniedDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Mikrofon İzni Gerekli'),
          content: const Text('Ses kaydı için mikrofon izni vermeniz gerekmektedir.'),
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

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel button
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _cancelRecording,
            ),
            const SizedBox(width: 8),

            // Waveform visualization
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _waveform.isEmpty
                    ? const Center(
                        child: Text(
                          'Kayıt başlatılıyor...',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : CustomPaint(
                        painter: WaveformPainter(
                          waveform: _waveform,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 8),

            // Duration
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fiber_manual_record,
                    color: Colors.red,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDuration(_recordDuration),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            IconButton(
              icon: Icon(
                Icons.send,
                color: Theme.of(context).primaryColor,
              ),
              onPressed: _recordDuration > 0 ? _stopRecording : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final Color color;

  WaveformPainter({
    required this.waveform,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / waveform.length;
    final maxHeight = size.height;

    for (int i = 0; i < waveform.length; i++) {
      final barHeight = waveform[i] * maxHeight * 0.8;
      final x = i * barWidth + barWidth / 2;
      final y1 = (maxHeight - barHeight) / 2;
      final y2 = y1 + barHeight;

      canvas.drawLine(
        Offset(x, y1),
        Offset(x, y2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WaveformPainter oldDelegate) {
    return oldDelegate.waveform != waveform;
  }
}
