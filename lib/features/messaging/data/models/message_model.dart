import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
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
  final bool? isApproved;  // ✅ Changed to optional - API doesn't always return this
  final DateTime sentDate;
  final DateTime? readDate;
  final DateTime? approvedDate;

  MessageModel({
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
    this.isApproved,  // ✅ Now optional
    required this.sentDate,
    this.readDate,
    this.approvedDate,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);
}
