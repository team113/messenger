import '/api/backend/schema.dart' show ChatItemQuoteInput;
import 'attachment.dart';
import 'chat_item.dart';

/// Quotes of the [ChatItem]s to be forwarded.
class ChatItemQuote {
  ChatItemQuote({
    required this.item,
    required this.withText,
    required this.attachments,
  });

  /// ID of the [ChatItem] to be forwarded.
  final ChatItem item;

  /// Indicator whether a forward should contain the full [ChatMessageText] of
  /// the original [ChatItem] (if it contains any).
  final bool withText;

  /// IDs of the [ChatItem]'s [Attachment]s to be forwarded.
  ///
  /// If no [Attachment]s are provided, then [ChatForward] will only contain a
  /// [ChatMessageText].
  final List<AttachmentId> attachments;

  /// Returns the generated [ChatItemQuoteInput] from this [ChatItemQuote].
  ChatItemQuoteInput get quote => ChatItemQuoteInput(
        id: item.id,
        attachments: attachments,
        withText: withText,
      );
}
