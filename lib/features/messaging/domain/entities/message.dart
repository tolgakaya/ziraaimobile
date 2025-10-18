import 'package:equatable/equatable.dart';
import '../../data/models/message_model.dart';

class Message extends Equatable {
  final int id;
  final int plantAnalysisId;
  final int fromUserId;
  final int toUserId;
  final String message;
  final String senderRole;
  final String? messageType;
  final String? subject;
  final String? senderName;
  final String? senderCompany;
  final String? priority;
  final String? category;
  final bool isRead;
  final bool? isApproved;  // ✅ Optional - API doesn't always return this
  final DateTime sentDate;
  final DateTime? readDate;
  final DateTime? approvedDate;

  const Message({
    required this.id,
    required this.plantAnalysisId,
    required this.fromUserId,
    required this.toUserId,
    required this.message,
    required this.senderRole,
    this.messageType,
    this.subject,
    this.senderName,
    this.senderCompany,
    this.priority,
    this.category,
    required this.isRead,
    this.isApproved,  // ✅ Optional
    required this.sentDate,
    this.readDate,
    this.approvedDate,
  });

  factory Message.fromModel(MessageModel model) {
    return Message(
      id: model.id,
      plantAnalysisId: model.plantAnalysisId,
      fromUserId: model.fromUserId,
      toUserId: model.toUserId,
      message: model.message,
      senderRole: model.senderRole,
      messageType: model.messageType,
      subject: model.subject,
      senderName: model.senderName,
      senderCompany: model.senderCompany,
      priority: model.priority,
      category: model.category,
      isRead: model.isRead,
      isApproved: model.isApproved,
      sentDate: model.sentDate,
      readDate: model.readDate,
      approvedDate: model.approvedDate,
    );
  }

  @override
  List<Object?> get props => [
        id,
        plantAnalysisId,
        fromUserId,
        toUserId,
        message,
        senderRole,
        messageType,
        subject,
        senderName,
        senderCompany,
        priority,
        category,
        isRead,
        isApproved,
        sentDate,
        readDate,
        approvedDate,
      ];
}
