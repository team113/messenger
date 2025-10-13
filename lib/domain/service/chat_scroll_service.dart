import 'package:get/get.dart';

import '../model/chat.dart';
import '../model/saved_chat_anchors.dart';
import '../model/user.dart';

class ChatScrollService extends GetxService {
  final Map<ScrollKey, SavedAnchor> _anchorByKey = <ScrollKey, SavedAnchor>{};
  final Map<ScrollKey, double> _fromBottomByKey = <ScrollKey, double>{};

  // ---- Anchor ----
  SavedAnchor? getAnchor(ChatId chatId, UserId userId) =>
      _anchorByKey[ScrollKey(userId, chatId)];

  void setAnchor(ChatId chatId, SavedAnchor anchor, UserId userId) {
    // debugPrint('ScrollCache setAnchor: ${userId.val} ${chatId.val}');
    _anchorByKey[ScrollKey(userId, chatId)] = anchor;
  }

  void clearAnchor(ChatId chatId, UserId userId) {
    _anchorByKey.remove(ScrollKey(userId, chatId));
  }

  // ---- From-bottom pixels ----
  double? getFromBottom(ChatId chatId, UserId userId) =>
      _fromBottomByKey[ScrollKey(userId, chatId)];

  void setFromBottom(ChatId chatId, double fromBottom, UserId userId) {
    // debugPrint('ScrollCache setFromBottom: ${userId.val} ${chatId.val}');
    _fromBottomByKey[ScrollKey(userId, chatId)] = fromBottom;
  }

  void clearFromBottom(ChatId chatId, UserId userId) {
    _fromBottomByKey.remove(ScrollKey(userId, chatId));
  }

  // ---- Clear helpers ----
  void clearAllForChat(ChatId chatId, UserId userId) {
    final key = ScrollKey(userId, chatId);
    _anchorByKey.remove(key);
    _fromBottomByKey.remove(key);
  }

  /// Wipes all data for a given user (across all chats).
  void clearAllForUser(UserId userId) {
    _anchorByKey.removeWhere((k, _) => k.userId == userId);
    _fromBottomByKey.removeWhere((k, _) => k.userId == userId);
  }

  /// Wipes absolutely everything (all users, all chats).
  void clearEverything() {
    _anchorByKey.clear();
    _fromBottomByKey.clear();
  }
}
