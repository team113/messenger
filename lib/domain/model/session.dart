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

import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/model_type_id.dart';
import '/util/new_type.dart';
import 'avatar.dart';
import 'crop_area.dart';
import 'file.dart';
import 'mute_duration.dart';
import 'precise_date_time/precise_date_time.dart';
import 'user_call_cover.dart';

part 'session.g.dart';

/// Session of a [MyUser] being signed-in.
@HiveType(typeId: ModelTypeId.session)
class Session {
  const Session({
    required this.id,
    required this.userAgent,
    this.isCurrent = true,
    required this.lastActivatedAt,
  });

  /// Unique ID of this [Session].
  @HiveField(0)
  final SessionId id;

  /// [UserAgent] of the device, that used this [Session] last time.
  @HiveField(1)
  final UserAgent userAgent;

  /// Indicator whether this [Session] is [MyUser]'s current [Session].
  @HiveField(2)
  final bool isCurrent;

  /// [DateTime] when this [Session] was activated last time (either created or
  /// refreshed).
  @HiveField(3)
  final PreciseDateTime lastActivatedAt;
}

/// Type of [Session]'s ID.
@HiveType(typeId: ModelTypeId.sessionId)
class SessionId extends NewType<String> {
  const SessionId(super.val);
}

/// Type of [MyUser]'s user agent.
///
/// Its values are always considered to be non-empty, and meet the following
/// requirements:
/// - consist only from ASCII characters;
/// - contain at least one non-space-like character.
@HiveType(typeId: ModelTypeId.userAgent)
class UserAgent extends NewType<String> {
  const UserAgent(super.val);
}

/// Token used for authenticating a [Session].
@HiveType(typeId: ModelTypeId.accessToken)
class AccessToken {
  const AccessToken(this.secret, this.expireAt);

  /// Secret part of this [AccessToken].
  ///
  /// This one should be used as a [Bearer authentication token][1].
  ///
  /// [1]: https://tools.ietf.org/html/rfc6750#section-2.1
  @HiveField(0)
  final AccessTokenSecret secret;

  /// [DateTime] of this [AccessToken] expiration.
  ///
  /// Once expired, it's not usable anymore and the [Session] should be
  /// refreshed to get a new [AccessToken].
  ///
  /// Client applications are supposed to use this field for tracking
  /// [AccessToken]'s expiration and refresh the [Session] before an
  /// authentication error occurs.
  @HiveField(1)
  final PreciseDateTime expireAt;
}

/// Type of [AccessToken]'s secret.
@HiveType(typeId: ModelTypeId.accessTokenSecret)
class AccessTokenSecret extends NewType<String> {
  const AccessTokenSecret(super.val);
}

/// Token used for refreshing a [Session].
@HiveType(typeId: ModelTypeId.refreshToken)
class RefreshToken {
  const RefreshToken(this.secret, this.expireAt);

  /// Secret part of this [RefreshToken].
  ///
  /// This one should be used for refreshing the [Session] renewal and is
  /// **NOT** usable as a [Bearer authentication token][1].
  ///
  /// [1]: https://tools.ietf.org/html/rfc6750#section-2.1
  @HiveField(0)
  final RefreshTokenSecret secret;

  /// [DateTime] of this [RefreshToken] expiration.
  ///
  /// Once expired, it's not usable anymore and a new [Session] should be
  /// renewed to get a new [RefreshToken].
  ///
  /// Client applications are supposed to use this field for tracking
  /// [RefreshToken]'s expiration and sign out [MyUser]s properly.
  ///
  /// Expiration of a [RefreshToken] is not prolonged on refreshing, and remains
  /// the same for all the [RefreshToken]s obtained.
  @HiveField(1)
  final PreciseDateTime expireAt;
}

/// Type of [RefreshToken]'s secret.
@HiveType(typeId: ModelTypeId.refreshTokenSecret)
class RefreshTokenSecret extends NewType<String> {
  const RefreshTokenSecret(super.val);
}

/// Container of a [AccessToken] and a [RefreshToken] representing the current
/// [MyUser] credentials.
@HiveType(typeId: ModelTypeId.credentials)
class Credentials {
  const Credentials(this.access, this.refresh, this.userId, [this.user]);

  /// Created or refreshed [AccessToken] for authenticating the [Session].
  ///
  /// It will expire in 30 minutes after creation.
  @HiveField(0)
  final AccessToken access;

  /// [RefreshToken] of these [Credentials].
  @HiveField(1)
  final RefreshToken refresh;

  /// ID of the currently authenticated [MyUser].
  @HiveField(2)
  final UserId userId;

  /// Object of the currently authenticated [MyUser].
  @HiveField(3)
  final MyUser? user;

  /// Constructs [Credentials] from the provided [data].
  factory Credentials.fromJson(Map<dynamic, dynamic> data) {
    return Credentials(
      AccessToken(
        AccessTokenSecret(data['access']['secret']),
        PreciseDateTime.parse(data['access']['expireAt']),
      ),
      RefreshToken(
        RefreshTokenSecret(data['refresh']['secret']),
        PreciseDateTime.parse(data['refresh']['expireAt']),
      ),
      UserId(data['userId']),
      MyUser(
        id: data['user']['id'],
        num: UserNum(data['user']['num']),
        login: UserLogin(data['user']['login']),
        emails: MyUserEmails(
          confirmed: (data['user']['emails']['confirmed'] as List<String>)
              .map((e) => UserEmail(e))
              .toList(),
          unconfirmed: data['user']['emails']['unconfirmed'],
        ),
        phones: MyUserPhones(
          confirmed: (data['user']['phones']['confirmed'] as List<String>)
              .map((e) => UserPhone(e))
              .toList(),
          unconfirmed: data['user']['phones']['unconfirmed'],
        ),
        name: UserName(data['user']['name']),
        bio: UserBio(data['user']['bio']),
        avatar: data['user']['avatar'] != null
            ? UserAvatar(
                crop: data['user']['avatar']['crop'] != null
                    ? CropArea(
                        topLeft: CropPoint(
                            x: data['user']['avatar']['crop']['topLeft']['x'],
                            y: data['user']['avatar']['crop']['topLeft']['y']),
                        bottomRight: CropPoint(
                            x: data['user']['avatar']['crop']['bottomRight']
                                ['x'],
                            y: data['user']['avatar']['crop']['bottomRight']
                                ['y']),
                      )
                    : null,
                full: ImageFile(
                  relativeRef: data['user']['avatar']['full']['relativeRef'],
                  width: data['user']['avatar']['full']['width'],
                  height: data['user']['avatar']['full']['height'],
                  checksum: data['user']['avatar']['full']['checksum'],
                  size: data['user']['avatar']['full']['size'],
                  thumbhash:
                      ThumbHash(data['user']['avatar']['full']['thumbhash']),
                ),
                big: ImageFile(
                  relativeRef: data['user']['avatar']['big']['relativeRef'],
                  width: data['user']['avatar']['big']['width'],
                  height: data['user']['avatar']['big']['height'],
                  checksum: data['user']['avatar']['big']['checksum'],
                  size: data['user']['avatar']['big']['size'],
                  thumbhash:
                      ThumbHash(data['user']['avatar']['big']['thumbhash']),
                ),
                medium: ImageFile(
                  relativeRef: data['user']['avatar']['medium']['relativeRef'],
                  width: data['user']['avatar']['medium']['width'],
                  height: data['user']['avatar']['medium']['height'],
                  checksum: data['user']['avatar']['medium']['checksum'],
                  size: data['user']['avatar']['medium']['size'],
                  thumbhash:
                      ThumbHash(data['user']['avatar']['medium']['thumbhash']),
                ),
                small: ImageFile(
                  relativeRef: data['user']['avatar']['small']['relativeRef'],
                  width: data['user']['avatar']['small']['width'],
                  height: data['user']['avatar']['small']['height'],
                  checksum: data['user']['avatar']['small']['checksum'],
                  size: data['user']['avatar']['small']['size'],
                  thumbhash:
                      ThumbHash(data['user']['avatar']['small']['thumbhash']),
                ),
                original: ImageFile(
                  relativeRef: data['user']['avatar']['original']
                      ['relativeRef'],
                  width: data['user']['avatar']['original']['width'],
                  height: data['user']['avatar']['original']['height'],
                  checksum: data['user']['avatar']['original']['checksum'],
                  size: data['user']['avatar']['original']['size'],
                  thumbhash: ThumbHash(
                      data['user']['avatar']['original']['thumbhash']),
                ),
              )
            : null,
        callCover: data['user']['callCover'] != null
            ? UserCallCover(
                crop: data['user']['callCover']['crop'] != null
                    ? CropArea(
                        topLeft: CropPoint(
                            x: data['user']['callCover']['crop']['topLeft']
                                ['x'],
                            y: data['user']['callCover']['crop']['topLeft']
                                ['y']),
                        bottomRight: CropPoint(
                            x: data['user']['callCover']['crop']['bottomRight']
                                ['x'],
                            y: data['user']['callCover']['crop']['bottomRight']
                                ['y']),
                      )
                    : null,
                full: ImageFile(
                  relativeRef: data['user']['callCover']['full']['relativeRef'],
                  width: data['user']['callCover']['full']['width'],
                  height: data['user']['callCover']['full']['height'],
                  checksum: data['user']['callCover']['full']['checksum'],
                  size: data['user']['callCover']['full']['size'],
                  thumbhash: ThumbHash(
                    data['user']['callCover']['full']['thumbhash'],
                  ),
                ),
                vertical: ImageFile(
                  relativeRef: data['user']['callCover']['vertical']
                      ['relativeRef'],
                  width: data['user']['callCover']['vertical']['width'],
                  height: data['user']['callCover']['vertical']['height'],
                  checksum: data['user']['callCover']['vertical']['checksum'],
                  size: data['user']['callCover']['vertical']['size'],
                  thumbhash: ThumbHash(
                    data['user']['callCover']['big']['thumbhash'],
                  ),
                ),
                square: ImageFile(
                  relativeRef: data['user']['callCover']['original']
                      ['relativeRef'],
                  width: data['user']['callCover']['original']['width'],
                  height: data['user']['callCover']['original']['height'],
                  checksum: data['user']['callCover']['original']['checksum'],
                  size: data['user']['callCover']['original']['size'],
                  thumbhash: ThumbHash(
                    data['user']['callCover']['original']['thumbhash'],
                  ),
                ),
                original: ImageFile(
                  relativeRef: data['user']['callCover']['original']
                      ['relativeRef'],
                  width: data['user']['callCover']['original']['width'],
                  height: data['user']['callCover']['original']['height'],
                  checksum: data['user']['callCover']['original']['checksum'],
                  size: data['user']['callCover']['original']['size'],
                  thumbhash: ThumbHash(
                    data['user']['callCover']['original']['thumbhash'],
                  ),
                ),
              )
            : null,
        presenceIndex: data['user']['presenceIndex'],
        online: data['user']['online'],
        hasPassword: data['user']['hasPassword'],
        chatDirectLink: data['user']['chatDirectLink'] != null
            ? ChatDirectLink(
                slug: data['user']['chatDirectLink']['slug'],
                usageCount: data['user']['chatDirectLink']['usageCount'],
              )
            : null,
        muted: data['user']['muted'] != null
            ? MuteDuration(
                until: data['user']['muted']['until'],
                forever: data['user']['muted']['forever'],
              )
            : null,
        status: UserTextStatus(data['user']['status']),
        unreadChatsCount: data['user']['unreadChatsCount'],
      ),
    );
  }

  /// Returns a [Map] containing data of these [Credentials].
  Map<String, dynamic> toJson() {
    return {
      'access': {
        'secret': access.secret.val,
        'expireAt': access.expireAt.toString(),
      },
      'refresh': {
        'secret': refresh.secret.val,
        'expireAt': refresh.expireAt.toString(),
      },
      'userId': userId.val,
      'user': user != null ? {
        'id': user!.id.val,
        'num': user!.num.val,
        'login': user!.login?.val,
        'emails': {
          'confirmed': user!.emails.confirmed.map((e) => e.val).toList(),
          'unconfirmed': user!.emails.unconfirmed?.val,
        },
        'phones': {
          'confirmed': user!.phones.confirmed.map((e) => e.val).toList(),
          'unconfirmed': user!.phones.unconfirmed?.val
        },
        'name': user!.name?.val,
        'bio': user!.bio?.val,
        'avatar': user!.avatar != null
            ? {
                'crop': user!.avatar?.crop != null
                    ? {
                        'topLeft': {
                          'x': user!.avatar?.crop?.topLeft.x,
                          'y': user!.avatar?.crop?.topLeft.y,
                        },
                        'bottomRight': {
                          'x': user!.avatar?.crop?.bottomRight.x,
                          'y': user!.avatar?.crop?.bottomRight.y,
                        },
                        'angle': user!.avatar?.crop?.angle?.name,
                      }
                    : null,
                'original': {
                  'relativeRef': user!.avatar?.original.relativeRef,
                  'width': user!.avatar?.original.width,
                  'height': user!.avatar?.original.height,
                  'checksum': user!.avatar?.original.checksum,
                  'size': user!.avatar?.original.size,
                  'thumbhash': user!.avatar?.original.thumbhash?.val,
                },
                'full': {
                  'relativeRef': user!.avatar?.full.relativeRef,
                  'width': user!.avatar?.full.width,
                  'height': user!.avatar?.full.height,
                  'checksum': user!.avatar?.full.checksum,
                  'size': user!.avatar?.full.size,
                  'thumbhash': user!.avatar?.full.thumbhash?.val,
                },
                'big': {
                  'relativeRef': user!.avatar?.big.relativeRef,
                  'width': user!.avatar?.big.width,
                  'height': user!.avatar?.big.height,
                  'checksum': user!.avatar?.big.checksum,
                  'size': user!.avatar?.big.size,
                  'thumbhash': user!.avatar?.big.thumbhash?.val,
                },
                'medium': {
                  'relativeRef': user!.avatar?.medium.relativeRef,
                  'width': user!.avatar?.medium.width,
                  'height': user!.avatar?.medium.height,
                  'checksum': user!.avatar?.medium.checksum,
                  'size': user!.avatar?.medium.size,
                  'thumbhash': user!.avatar?.medium.thumbhash?.val,
                },
                'small': {
                  'relativeRef': user!.avatar?.small.relativeRef,
                  'width': user!.avatar?.small.width,
                  'height': user!.avatar?.small.height,
                  'checksum': user!.avatar?.small.checksum,
                  'size': user!.avatar?.small.size,
                  'thumbhash': user!.avatar?.small.thumbhash?.val,
                }
              }
            : null,
        'callCover': user!.callCover != null
            ? {
                'crop': user!.callCover?.crop != null
                    ? {
                        'topLeft': {
                          'x': user!.callCover?.crop?.topLeft.x,
                          'y': user!.callCover?.crop?.topLeft.y,
                        },
                        'bottomRight': {
                          'x': user!.callCover?.crop?.bottomRight.x,
                          'y': user!.callCover?.crop?.bottomRight.y,
                        },
                        'angle': user!.callCover?.crop?.angle?.name,
                      }
                    : null,
                'original': {
                  'relativeRef': user!.callCover?.original.relativeRef,
                  'width': user!.callCover?.original.width,
                  'height': user!.callCover?.original.height,
                  'checksum': user!.callCover?.original.checksum,
                  'size': user!.callCover?.original.size,
                  'thumbhash': user!.callCover?.original.thumbhash?.val
                },
                'full': {
                  'relativeRef': user!.callCover?.full.relativeRef,
                  'width': user!.callCover?.full.width,
                  'height': user!.callCover?.full.height,
                  'checksum': user!.callCover?.full.checksum,
                  'size': user!.callCover?.full.size,
                  'thumbhash': user!.callCover?.full.thumbhash?.val
                },
                'vertical': {
                  'relativeRef': user!.callCover?.vertical.relativeRef,
                  'width': user!.callCover?.vertical.width,
                  'height': user!.callCover?.vertical.height,
                  'checksum': user!.callCover?.vertical.checksum,
                  'size': user!.callCover?.vertical.size,
                  'thumbhash': user!.callCover?.vertical.thumbhash?.val
                },
                'square': {
                  'relativeRef': user!.callCover?.square.relativeRef,
                  'width': user!.callCover?.square.width,
                  'height': user!.callCover?.square.height,
                  'checksum': user!.callCover?.square.checksum,
                  'size': user!.callCover?.square.size,
                  'thumbhash': user!.callCover?.square.thumbhash?.val
                }
              }
            : null,
        'hasPassword': user!.hasPassword,
        'muted': user!.muted != null
            ? {
                'until': user!.muted?.until?.val,
                'forever': user!.muted?.forever,
              }
            : null,
        'online': user!.online,
        'chatDirectLink': user!.chatDirectLink != null
            ? {
                'slug': user!.chatDirectLink!.slug.val,
                'usageCount': user!.chatDirectLink!.usageCount,
              }
            : null,
        'presenceIndex': user!.presenceIndex,
        'status': user!.status?.val,
        'unreadChatsCount': user!.unreadChatsCount,
      } : null,
    };
  }
}
