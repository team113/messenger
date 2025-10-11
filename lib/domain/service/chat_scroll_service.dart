import 'package:get/get.dart';

class SavedAnchor {
  final String chatKey;
  final double offsetFromBottom;
  const SavedAnchor(this.chatKey, this.offsetFromBottom);

  @override
  String toString() => 'SavedAnchor(key=$chatKey, off=$offsetFromBottom)';
}

class ChatScrollService extends GetxService {
  final Map<String, SavedAnchor> _anchorByChat = <String, SavedAnchor>{};

  final Map<String, double> _fromBottomByChat = <String, double>{};

  SavedAnchor? getAnchor(String chatId) => _anchorByChat[chatId];

  void setAnchor(String chatId, SavedAnchor anchor) {
    _anchorByChat[chatId] = anchor;
  }

  void clearAnchor(String chatId) {
    _anchorByChat.remove(chatId);
  }

  double? getFromBottom(String chatId) => _fromBottomByChat[chatId];

  void setFromBottom(String chatId, double fromBottom) {
    _fromBottomByChat[chatId] = fromBottom;
  }

  void clearFromBottom(String chatId) {
    _fromBottomByChat.remove(chatId);
  }

  void clearAll(String chatId) {
    _anchorByChat.remove(chatId);
    _fromBottomByChat.remove(chatId);
  }

  void clearEverything() {
    _anchorByChat.clear();
    _fromBottomByChat.clear();
  }
}
