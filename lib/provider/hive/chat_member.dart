// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:hive/hive.dart';

import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/model/user_call_cover.dart';
import '/domain/model_type_id.dart';
import '/store/model/chat.dart';
import '/util/log.dart';
import 'base.dart';

part 'chat_member.g.dart';

/// [Hive] storage for [ChatMember]s.
class ChatMemberHiveProvider extends HiveLazyProvider<HiveChatMember>
    implements IterableHiveProvider<HiveChatMember, UserId> {
  ChatMemberHiveProvider(this.id);

  /// ID of a [Chat] this provider is bound to.
  final ChatId id;

  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'members_$id';

  @override
  void registerAdapters() {
    Log.debug('registerAdapters($id)', '$runtimeType');

    Hive.maybeRegisterAdapter(BlocklistReasonAdapter());
    Hive.maybeRegisterAdapter(BlocklistRecordAdapter());
    Hive.maybeRegisterAdapter(ChatMembersCursorAdapter());
    Hive.maybeRegisterAdapter(HiveChatMemberAdapter());
    Hive.maybeRegisterAdapter(PreciseDateTimeAdapter());
    Hive.maybeRegisterAdapter(UserAdapter());
    Hive.maybeRegisterAdapter(UserAvatarAdapter());
    Hive.maybeRegisterAdapter(UserCallCoverAdapter());
    Hive.maybeRegisterAdapter(UserIdAdapter());
    Hive.maybeRegisterAdapter(UserNameAdapter());
    Hive.maybeRegisterAdapter(UserNumAdapter());
    Hive.maybeRegisterAdapter(UserTextStatusAdapter());
  }

  @override
  Iterable<UserId> get keys => keysSafe.map((e) => UserId(e));

  @override
  Future<Iterable<HiveChatMember>> get values => valuesSafe;

  @override
  Future<void> put(HiveChatMember member) async {
    Log.trace('put($member)', '$runtimeType');
    await putSafe(member.value.user.id.val, member);
  }

  @override
  Future<HiveChatMember?> get(UserId id) {
    Log.trace('get($id)', '$runtimeType');
    return getSafe(id.val);
  }

  @override
  Future<void> remove(UserId id) async {
    Log.trace('remove($id)', '$runtimeType');
    await deleteSafe(id.val);
  }
}

/// Persisted in [Hive] storage [ChatMember]'s [value].
@HiveType(typeId: ModelTypeId.hiveChatMember)
class HiveChatMember extends HiveObject {
  HiveChatMember(this.value, this.cursor);

  /// Persisted [ChatMember] model.
  @HiveField(0)
  ChatMember value;

  /// Cursor of the [value].
  @HiveField(1)
  ChatMembersCursor? cursor;

  @override
  String toString() => '$runtimeType($value, $cursor)';
}
