// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/model/welcome_message.dart';
import '/store/model/blocklist.dart';
import '/store/model/my_user.dart';
import 'chat.dart';
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
            createdAt: chatDirectLink!.createdAt,
          )
        : null,
    avatar: avatar?.toModel(),
    status: status,
    presenceIndex: presence.index,
    emails: MyUserEmails(
      confirmed: emails.confirmed,
      unconfirmed: emails.unconfirmed,
    ),
    phones: MyUserPhones(confirmed: []),
    muted: muted != null
        ? muted!.$$typename == 'MuteForeverDuration'
              ? MuteDuration.forever()
              : MuteDuration.until(
                  (muted! as MyUserMixin$Muted$MuteUntilDuration).until,
                )
        : null,
    lastSeenAt: online.$$typename == 'UserOffline'
        ? (online as MyUserMixin$Online$UserOffline).lastSeenAt
        : null,
    welcomeMessage: welcomeMessage?.toModel(),
  );

  /// Constructs a new [DtoMyUser] from this [MyUserMixin].
  DtoMyUser toDto() => DtoMyUser(toModel(), ver);
}

/// Extension adding models construction from a
/// [MyUserEvents$Subscription$MyUserEvents$MyUser].
extension MyUserEventsMyUserConversion
    on MyUserEvents$Subscription$MyUserEvents$MyUser {
  /// Constructs a new [DtoMyUser] from this
  /// [MyUserEvents$Subscription$MyUserEvents$MyUser].
  DtoMyUser toDto() => DtoMyUser(toModel(), ver);
}

/// Extension adding models construction from a [BlocklistRecordMixin].
extension BlocklistRecordConversion on BlocklistRecordMixin {
  /// Constructs a new [BlocklistRecord] from this [BlocklistRecordMixin].
  BlocklistRecord toModel() =>
      BlocklistRecord(userId: user.id, reason: reason, at: at);

  /// Constructs a new [DtoBlocklistRecord] from this [BlocklistRecordMixin].
  DtoBlocklistRecord toDto({BlocklistCursor? cursor}) =>
      DtoBlocklistRecord(toModel(), cursor);
}

/// Extension adding [Session] model construction from a [SessionMixin].
extension SessionExtension on SessionMixin {
  /// Constructs a new [Session] from this [SessionMixin].
  Session toModel() {
    return Session(
      id: id,
      ip: ip,
      lastActivatedAt: lastActivatedAt,
      userAgent: userAgent,
    );
  }
}

/// Extension adding [WelcomeMessage] model construction from a
/// [WelcomeMessageMixin].
extension WelcomeMessageExtension on WelcomeMessageMixin {
  /// Constructs a new [WelcomeMessage] from this [WelcomeMessageMixin].
  WelcomeMessage toModel() {
    return WelcomeMessage(
      text: text,
      attachments: attachments.map((e) => e.toModel()).toList(),
      at: at,
    );
  }
}
