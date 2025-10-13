import '/util/new_type.dart';
import 'chat.dart';
import 'user.dart';

/// Represents the saved scroll position within a chat.
class SavedAnchor {
  /// The unique key identifying the chat.
  final ChatKey chatKey;

  /// The offset from the bottom of the chat list.
  final OffsetFromBottom offsetFromBottom;

  const SavedAnchor(this.chatKey, this.offsetFromBottom);

  @override
  String toString() =>
      'SavedAnchor(key=${chatKey.val}, off=${offsetFromBottom.val})';
}

/// Strongly typed unique chat key (instead of a raw String).
class ChatKey extends NewType<String> {
  const ChatKey(super.val);

  /// Creates a [ChatKey] from a JSON value.
  factory ChatKey.fromJson(String val) = ChatKey;

  /// Converts this [ChatKey] to a JSON value.
  String toJson() => val;
}

/// Strongly typed scroll offset (instead of a raw double).
class OffsetFromBottom extends NewType<double> {
  const OffsetFromBottom(super.val);

  /// Creates an [OffsetFromBottom] from a JSON value.
  factory OffsetFromBottom.fromJson(double val) = OffsetFromBottom;

  /// Converts this [OffsetFromBottom] to a JSON value.
  double toJson() => val;
}

class ScrollKey {
  final UserId userId;
  final ChatId chatId;
  const ScrollKey(this.userId, this.chatId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollKey &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          chatId == other.chatId;

  @override
  int get hashCode => Object.hash(userId, chatId);
}
