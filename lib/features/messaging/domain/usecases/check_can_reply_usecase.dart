import 'package:injectable/injectable.dart';
import '../entities/message.dart';

@injectable
class CheckCanReplyUseCase {
  /// ✅ BUSINESS RULE: Farmer can only reply AFTER sponsor sends first message
  ///
  /// This ensures that messaging is initiated by sponsors who have permission
  /// based on their tier level (L, XL tiers can message farmers).
  /// Farmers can only respond to sponsor messages, not initiate conversations.
  bool call(List<Message> messages) {
    return messages.any((msg) => msg.isSponsorMessage);
  }
}
