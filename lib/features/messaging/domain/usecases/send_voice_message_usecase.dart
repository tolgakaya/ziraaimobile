import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/messaging_repository.dart';

/// Use case for sending voice messages
/// Requires XL tier subscription
@injectable
class SendVoiceMessageUseCase {
  final MessagingRepository _repository;

  SendVoiceMessageUseCase(this._repository);

  Future<Either<Failure, Message>> call(SendVoiceMessageParams params) async {
    return await _repository.sendVoiceMessage(
      toUserId: params.toUserId,
      plantAnalysisId: params.plantAnalysisId,
      voiceFile: params.voiceFile,
      duration: params.duration,
      waveform: params.waveform,
    );
  }
}

class SendVoiceMessageParams extends Equatable {
  final int toUserId;
  final int plantAnalysisId;
  final File voiceFile;
  final int duration; // in seconds
  final List<double>? waveform; // Optional waveform data for visualization

  const SendVoiceMessageParams({
    required this.toUserId,
    required this.plantAnalysisId,
    required this.voiceFile,
    required this.duration,
    this.waveform,
  });

  @override
  List<Object?> get props => [toUserId, plantAnalysisId, voiceFile, duration, waveform];
}
