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

import '/api/backend/schema.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/provider/hive/blocklist.dart';
import '/provider/hive/my_user.dart';
import '/store/model/my_user.dart';
import 'user.dart';

/// Extension adding models construction from a [MyUserMixin].
extension MyUserConversion on MyUserMixin {
  /// Constructs a new [MyUser] from this [MyUserMixin].
  MyUser toModel() => MyUser(
        id: id,
        num: this.num,
        online: online.$$typename == 'UserOnline',
        login: login,
        name: name,
        bio: bio,
        hasPassword: hasPassword,
        unreadChatsCount: unreadChatsCount,
        chatDirectLink: chatDirectLink != null
            ? ChatDirectLink(
                slug: chatDirectLink!.slug,
                usageCount: chatDirectLink!.usageCount,
              )
            : null,
        avatar: avatar?.toModel(),
        status: status,
        presenceIndex: presence.index,
        emails: MyUserEmails(
          confirmed: emails.confirmed,
          unconfirmed: emails.unconfirmed,
        ),
        phones: MyUserPhones(
          confirmed: phones.confirmed,
          unconfirmed: phones.unconfirmed,
        ),
        muted: muted != null
            ? muted!.$$typename == 'MuteForeverDuration'
                ? MuteDuration.forever()
                : MuteDuration.until(
                    (muted! as MyUserMixin$Muted$MuteUntilDuration).until)
            : null,
        lastSeenAt: online.$$typename == 'UserOffline'
            ? (online as MyUserMixin$Online$UserOffline).lastSeenAt
            : null,
      );

  /// Constructs a new [HiveMyUser] from this [MyUserMixin].
  HiveMyUser toHive() => HiveMyUser(toModel(), ver);
}

/// Extension adding models construction from a
/// [MyUserEvents$Subscription$MyUserEvents$MyUser].
extension MyUserEventsMyUserConversion
    on MyUserEvents$Subscription$MyUserEvents$MyUser {
  /// Constructs a new [HiveMyUser] from this
  /// [MyUserEvents$Subscription$MyUserEvents$MyUser].
  HiveMyUser toHive() =>
      HiveMyUser(toModel()..blocklistCount = blocklist.totalCount, ver);
}

/// Extension adding models construction from a [BlocklistRecordMixin].
extension BlocklistRecordConversion on BlocklistRecordMixin {
  /// Constructs a new [BlocklistRecord] from this [BlocklistRecordMixin].
  BlocklistRecord toModel() => BlocklistRecord(
        userId: user.id,
        reason: reason,
        at: at,
      );

  /// Constructs a new [HiveBlocklistRecord] from this [BlocklistRecordMixin].
  HiveBlocklistRecord toHive({BlocklistCursor? cursor}) =>
      HiveBlocklistRecord(toModel(), cursor);
}
