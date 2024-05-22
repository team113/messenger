import 'package:hive/hive.dart';

import '/domain/model_type_id.dart';
import '/domain/model/chat.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import 'chat.dart';
import 'user.dart';

part 'chat_member.g.dart';

/// Persisted in storage [ChatMember].
@HiveType(typeId: ModelTypeId.dtoChatMember)
class DtoChatMember extends HiveObject implements Comparable<DtoChatMember> {
  DtoChatMember(
    this.user,
    this.joinedAt,
    this.cursor, {
    UserId? userId,
  }) : id = userId ?? user!.id;

  /// [UserId] of the [User] this [ChatMember] is about.
  @HiveField(0)
  UserId id;

  /// Persisted [DtoUser] model.
  @HiveField(1)
  User? user;

  /// [PreciseDateTime] when the [User] became a [ChatMember].
  @HiveField(2)
  final PreciseDateTime joinedAt;

  /// Cursor of this [ChatMember].
  @HiveField(3)
  ChatMembersCursor? cursor;

  @override
  String toString() => '$runtimeType($user, $joinedAt, $cursor)';

  @override
  int compareTo(DtoChatMember other) {
    final int result = joinedAt.compareTo(other.joinedAt);
    if (result == 0) {
      return id.compareTo(other.id);
    }

    return result;
  }
}
