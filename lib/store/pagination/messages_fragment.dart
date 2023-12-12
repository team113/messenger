import 'dart:async';

import 'package:get/get.dart';
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/domain/model/chat_item_quote.dart';
import 'package:messenger/provider/hive/chat_item.dart';
import 'package:messenger/store/chat_rx.dart';
import 'package:messenger/store/model/chat_item.dart';
import 'package:messenger/util/log.dart';
import 'package:messenger/util/obs/obs.dart';
import 'package:messenger/util/platform_utils.dart';

import '../pagination.dart';

class MessagesFragment {
  MessagesFragment({
    required this.pagination,
    required this.initialCursor,
    this.initialKey,
    this.onDispose,
  });

  ChatItemsCursor initialCursor;
  ChatItemKey? initialKey;

  Pagination<HiveChatItem, ChatItemsCursor, ChatItemKey> pagination;

  final RxObsList<Rx<ChatItem>> messages = RxObsList<Rx<ChatItem>>();

  StreamSubscription? _paginationSubscription;


  RxBool get hasNext => pagination.hasNext;


  RxBool get nextLoading => pagination.nextLoading;


  RxBool get hasPrevious => pagination.hasPrevious;


  RxBool get previousLoading => pagination.previousLoading;

  /// Callback, called when the state of this [MessagesFragment] is disposed.
  final void Function()? onDispose;

  Future<void> init() async {
    _paginationSubscription = pagination.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
        case OperationKind.updated:
          _add(event.value!.value);
          break;

        case OperationKind.removed:
          messages.removeWhere((e) => e.value.id == event.value?.value.id);
          break;
      }
    });

    await pagination.around(cursor: initialCursor, key: initialKey);
  }

  void dispose() {
    onDispose?.call();
    _paginationSubscription?.cancel();
    pagination.dispose();
  }

  Future<void> next() async {
    await pagination.next();
  }

  Future<void> previous() async {
    await pagination.previous();
  }

  Future<void> put(HiveChatItem item) async {
    Log.debug('put($item)', '$runtimeType()');
    await pagination.put(item);
  }

  /// Adds the provided [ChatItem] to the [messages] list, initializing the
  /// [FileAttachment]s, if any.
  void _add(ChatItem item) {
    Log.debug('_add($item)', '$runtimeType');

    if (!PlatformUtils.isWeb) {
      if (item is ChatMessage) {
        for (var a in item.attachments.whereType<FileAttachment>()) {
          a.init();
        }
      } else if (item is ChatForward) {
        ChatItemQuote nested = item.quote;
        if (nested is ChatMessageQuote) {
          for (var a in nested.attachments.whereType<FileAttachment>()) {
            a.init();
          }
        }
      }
    }

    final int i = messages.indexWhere((e) => e.value.id == item.id);
    if (i == -1) {
      messages.insertAfter(
        Rx(item),
        (e) => item.key.compareTo(e.value.key) == 1,
      );
    } else {
      messages[i].value = item;
    }
  }
}
