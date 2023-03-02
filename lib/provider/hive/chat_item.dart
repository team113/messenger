// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/native_file.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/sending_status.dart';
import '/domain/model/user.dart';
import '/domain/model_type_id.dart';
import '/store/model/chat_item.dart';
import '/store/pagination.dart';
import 'base.dart';

part 'chat_item.g.dart';

/// [Hive] storage for [ChatItem]s.
class ChatItemHiveProvider extends HiveBaseProvider<HiveChatItem>
    implements PageProvider<HiveChatItem> {
  ChatItemHiveProvider(this.id, {this.initialKey});

  /// ID of a [Chat] this provider is bound to.
  final ChatId id;

  /// Key to get the [initial] items.
  final String? initialKey;

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'messages_$id';

  @override
  Future<void> init({UserId? userId, bool lazy = false}) {
    assert(lazy, 'ChatItemHiveProvider can be only lazy');

    return super.init(userId: userId, lazy: lazy);
  }

  @override
  void registerAdapters() {
    Hive.maybeRegisterAdapter(AttachmentIdAdapter());
    Hive.maybeRegisterAdapter(ChatCallAdapter());
    Hive.maybeRegisterAdapter(ChatCallMemberAdapter());
    Hive.maybeRegisterAdapter(ChatForwardAdapter());
    Hive.maybeRegisterAdapter(ChatIdAdapter());
    Hive.maybeRegisterAdapter(ChatItemIdAdapter());
    Hive.maybeRegisterAdapter(ChatItemVersionAdapter());
    Hive.maybeRegisterAdapter(ChatItemsCursorAdapter());
    Hive.maybeRegisterAdapter(ChatMemberAdapter());
    Hive.maybeRegisterAdapter(ChatMemberInfoAdapter());
    Hive.maybeRegisterAdapter(ChatMessageAdapter());
    Hive.maybeRegisterAdapter(ChatMessageTextAdapter());
    Hive.maybeRegisterAdapter(FileAttachmentAdapter());
    Hive.maybeRegisterAdapter(HiveChatCallAdapter());
    Hive.maybeRegisterAdapter(HiveChatForwardAdapter());
    Hive.maybeRegisterAdapter(HiveChatMemberInfoAdapter());
    Hive.maybeRegisterAdapter(HiveChatMessageAdapter());
    Hive.maybeRegisterAdapter(ImageAttachmentAdapter());
    Hive.maybeRegisterAdapter(LocalAttachmentAdapter());
    Hive.maybeRegisterAdapter(MediaTypeAdapter());
    Hive.maybeRegisterAdapter(NativeFileAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(SendingStatusAdapter());
  }

  /// Returns a list of [ChatItem]s from [Hive].
  Future<Iterable<HiveChatItem>> get messages => lazyValuesSafe;

  /// Puts the provided [ChatItem] to [Hive].
  Future<void> put(HiveChatItem item) => putSafe(item.value.timestamp, item);

  /// Adds the provided [ChatItem] to [Hive].
  Future<void> add(HiveChatItem item) async {
    if (box.keys.isNotEmpty &&
        (box.keys.first as String).compareTo(item.value.timestamp) == 1 &&
        (box.keys.last as String).compareTo(item.value.timestamp) == -1) {
      await put(item);
    }
  }

  /// Returns a [ChatItem] from [Hive] by its [timestamp].
  Future<HiveChatItem?> get(String timestamp) => lazyGetSafe(timestamp);

  /// Removes a [ChatItem] from [Hive] by the provided [timestamp].
  Future<void> remove(String timestamp) => deleteSafe(timestamp);

  @override
  Future<ItemsPage<HiveChatItem>> initial(int count, String? cursor) async {
    final lazyBox = box as LazyBox<HiveChatItem>;

    if (initialKey != null) {
      Iterable<dynamic> keys = lazyBox.keys.toList().reversed;

      int initialIndex = keys.toList().indexOf(initialKey);
      if (initialIndex != -1) {
        print(initialIndex);
        if (initialIndex < (count ~/ 2)) {
          print('initialIndex < (count ~/ 2)');
          keys = keys.take(count - ((count ~/ 2) - initialIndex));
        } else {
          print('initialIndex > (count ~/ 2)');
          keys = keys.skip(initialIndex - (count ~/ 2)).take(count);
        }

        keys = keys.take(count);

        final List<HiveChatItem> items =
            (await Future.wait(keys.map((e) => lazyBox.get(e))))
                .whereNotNull()
                .toList();
        return ItemsPage<HiveChatItem>(
          items,
          PageInfo(
            endCursor:
                items.lastWhereOrNull((e) => e.cursor != null)?.cursor?.val,
            hasNextPage: keys.length > count,
            startCursor:
                items.firstWhereOrNull((e) => e.cursor != null)?.cursor?.val,
            hasPreviousPage: initialIndex - (count ~/ 2) > 0,
          ),
        );
      }
    }

    List<Future<HiveChatItem?>> futures = [];
    for (int i = 1; i <= count && lazyBox.length - i > -1; i++) {
      futures.add(lazyBox.getAt(lazyBox.length - i));
    }

    final List<HiveChatItem> items =
        (await Future.wait(futures)).whereNotNull().toList();
    return ItemsPage<HiveChatItem>(
      items,
      PageInfo(
        endCursor: items.lastWhereOrNull((e) => e.cursor != null)?.cursor?.val,
        hasNextPage: lazyBox.length > count,
        startCursor:
            items.firstWhereOrNull((e) => e.cursor != null)?.cursor?.val,
        hasPreviousPage: false,
      ),
    );
  }

  @override
  Future<ItemsPage<HiveChatItem>> after(
    HiveChatItem after,
    String? cursor,
    int count,
  ) async {
    final lazyBox = box as LazyBox<HiveChatItem>;
    int index = lazyBox.keys.toList().indexOf(after.value.timestamp);
    List<Future<HiveChatItem?>> futures = [];
    if (index != -1) {
      for (int i = 1; i <= count && index - i > -1; i++) {
        futures.add(lazyBox.getAt(index - i));
      }
    }

    final List<HiveChatItem> items =
        (await Future.wait(futures)).whereNotNull().toList();
    return ItemsPage<HiveChatItem>(
      items,
      PageInfo(
        endCursor: items.lastWhereOrNull((e) => e.cursor != null)?.cursor?.val,
        hasNextPage: index > count,
        startCursor:
            items.firstWhereOrNull((e) => e.cursor != null)?.cursor?.val,
        hasPreviousPage: index < lazyBox.length - 1,
      ),
    );
  }

  @override
  Future<ItemsPage<HiveChatItem>> before(
    HiveChatItem before,
    String? cursor,
    int count,
  ) async {
    final lazyBox = box as LazyBox<HiveChatItem>;
    int index = lazyBox.keys.toList().indexOf(before.value.timestamp);
    List<Future<HiveChatItem?>> futures = [];
    if (index != -1) {
      for (int i = 1; i <= count && index + i < lazyBox.length; i++) {
        futures.add(lazyBox.getAt(index + i));
      }
    }

    final List<HiveChatItem> items =
        (await Future.wait(futures)).whereNotNull().toList();
    return ItemsPage<HiveChatItem>(
      items,
      PageInfo(
        endCursor: items.lastWhereOrNull((e) => e.cursor != null)?.cursor?.val,
        hasNextPage: index > 0,
        startCursor:
            items.firstWhereOrNull((e) => e.cursor != null)?.cursor?.val,
        hasPreviousPage: lazyBox.length > count + index + 1,
      ),
    );
  }
}

/// Persisted in [Hive] storage [ChatItem]'s [value].
abstract class HiveChatItem extends HiveObject {
  HiveChatItem(this.value, this.cursor, this.ver);

  /// Persisted [ChatItem] model.
  @HiveField(0)
  ChatItem value;

  /// Cursor of a [ChatItem] this [HiveChatItem] represents.
  @HiveField(1)
  ChatItemsCursor? cursor;

  /// Version of a [ChatItem]'s state.
  ///
  /// It increases monotonically, so may be used (and is intended to) for
  /// tracking state's actuality.
  @HiveField(2)
  final ChatItemVersion ver;
}

/// Persisted in [Hive] storage [ChatMemberInfo]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatMemberInfo)
class HiveChatMemberInfo extends HiveChatItem {
  HiveChatMemberInfo(
    ChatMemberInfo value,
    ChatItemsCursor cursor,
    ChatItemVersion ver,
  ) : super(value, cursor, ver);
}

/// Persisted in [Hive] storage [ChatCall]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatCall)
class HiveChatCall extends HiveChatItem {
  HiveChatCall(
    ChatCall value,
    ChatItemsCursor cursor,
    ChatItemVersion ver,
  ) : super(value, cursor, ver);
}

/// Persisted in [Hive] storage [ChatMessage]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatMessage)
class HiveChatMessage extends HiveChatItem {
  HiveChatMessage(
    ChatMessage value,
    ChatItemsCursor? cursor,
    ChatItemVersion ver,
    this.repliesToCursor,
  ) : super(value, cursor, ver);

  /// Constructs a [HiveChatMessage] in a [SendingStatus.sending] state.
  factory HiveChatMessage.sending({
    required ChatId chatId,
    required UserId me,
    ChatMessageText? text,
    List<ChatItem> repliesTo = const [],
    List<Attachment> attachments = const [],
    ChatItemId? existingId,
    PreciseDateTime? existingDateTime,
  }) =>
      HiveChatMessage(
        ChatMessage(
          existingId ?? ChatItemId.local(),
          chatId,
          me,
          existingDateTime ?? PreciseDateTime.now(),
          text: text,
          repliesTo: repliesTo,
          attachments: attachments,
          status: SendingStatus.sending,
        ),
        null,
        ChatItemVersion('0'),
        [],
      );

  /// Cursors of the [ChatMessage.repliesTo] list.
  @HiveField(3)
  List<ChatItemsCursor>? repliesToCursor;
}

/// Persisted in [Hive] storage [ChatForward]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatForward)
class HiveChatForward extends HiveChatItem {
  HiveChatForward(
    ChatForward value,
    ChatItemsCursor cursor,
    ChatItemVersion ver,
    this.itemCursor,
  ) : super(value, cursor, ver);

  /// Cursor of a [ChatForward.item].
  @HiveField(3)
  ChatItemsCursor itemCursor;
}
