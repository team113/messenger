// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/chat.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';

export 'non_web.dart' if (dart.library.html) 'web.dart';

/// Event happening in the browser's storage.
class WebStorageEvent {
  const WebStorageEvent({
    this.key,
    this.newValue,
    this.oldValue,
  });

  /// Key changed.
  ///
  /// `null`, if the `clear` method was invoked.
  final String? key;

  /// Value of the [key].
  ///
  /// `null`, if the `clear` method was invoked or the [key] was deleted.
  final String? newValue;

  /// Original previous value of the [key].
  ///
  /// `null`, if a [newValue] was just added.
  final String? oldValue;
}

/// Model of an [OngoingCall] stored in the browser's storage.
class WebStoredCall {
  const WebStoredCall({
    required this.chatId,
    this.call,
    this.creds,
    this.deviceId,
    this.state = OngoingCallState.local,
  });

  /// [ChatCall] of this [WebStoredCall].
  final ChatCall? call;

  /// [ChatId] of this [WebStoredCall].
  final ChatId chatId;

  /// Stored [OngoingCall.creds].
  final ChatCallCredentials? creds;

  /// Stored [OngoingCall.deviceId].
  final ChatCallDeviceId? deviceId;

  /// Stored [OngoingCall.state].
  final OngoingCallState state;

  /// Constructs a [WebStoredCall] from the provided [data].
  factory WebStoredCall.fromJson(Map<dynamic, dynamic> data) {
    return WebStoredCall(
      chatId: ChatId(data['chatId']),
      call: data['call'] == null
          ? null
          : ChatCall(
              ChatItemId(data['call']['id']),
              ChatId(data['call']['chatId']),
              UserId(data['call']['authorId']),
              PreciseDateTime.parse(data['call']['at']),
              caller: data['call']['caller'] == null
                  ? null
                  : User(
                      UserId(data['call']['caller']['id']),
                      UserNum(data['call']['caller']['num']),
                    ),
              members: (data['call']['members'] as List<dynamic>)
                  .map((e) => ChatCallMember(
                        user: User(
                          UserId(e['user']['id']),
                          UserNum(e['user']['num']),
                        ),
                        handRaised: e['handRaised'],
                        joinedAt: PreciseDateTime.parse(e['joinedAt']),
                      ))
                  .toList(),
              withVideo: data['call']['withVideo'],
              answered: data['call']['answered'],
            ),
      creds: data['creds'] == null ? null : ChatCallCredentials(data['creds']),
      deviceId:
          data['deviceId'] == null ? null : ChatCallDeviceId(data['deviceId']),
      state: data['state'] == null
          ? OngoingCallState.local
          : OngoingCallState.values[data['state']],
    );
  }

  /// Returns a [Map] containing this [WebStoredCall] data.
  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId.val,
      'call': call == null
          ? null
          : {
              'id': call!.id.val,
              'chatId': call!.chatId.val,
              'authorId': call!.authorId.val,
              'at': call!.at.toString(),
              'caller': call!.caller == null
                  ? null
                  : {
                      'id': call!.caller?.id.val,
                      'num': call!.caller?.num.val,
                    },
              'members': call!.members
                  .map((e) => {
                        'user': {
                          'id': e.user.id.val,
                          'num': e.user.num.val,
                        },
                        'handRaised': e.handRaised,
                        'joinedAt': e.joinedAt.toString(),
                      })
                  .toList(),
              'withVideo': call!.withVideo,
              'answered': call!.answered,
            },
      'creds': creds?.val,
      'deviceId': deviceId?.val,
      'state': state.index,
    };
  }
}

/// Preferences of a popup call containing its [width], [height] and position.
class WebCallPreferences {
  WebCallPreferences({this.width, this.height, this.left, this.top});

  /// Width of the popup window these [WebCallPreferences] are about.
  final int? width;

  /// Height of the popup window these [WebCallPreferences] are about.
  final int? height;

  /// Left position of the popup window these [WebCallPreferences] are about.
  final int? left;

  /// Top position of the popup window these [WebCallPreferences] are about.
  final int? top;

  /// Constructs a [WebCallPreferences] from the provided [data].
  factory WebCallPreferences.fromJson(Map<dynamic, dynamic> data) {
    return WebCallPreferences(
      width: data['width'],
      height: data['height'],
      left: data['left'],
      top: data['top'],
    );
  }

  /// Returns a [Map] containing data of these [WebCallPreferences].
  Map<String, dynamic> toJson() {
    return {'width': width, 'height': height, 'left': left, 'top': top};
  }
}

/// Extension adding a conversion from an [OngoingCall] to a [WebStoredCall].
extension WebStoredOngoingCallConversion on OngoingCall {
  /// Constructs a [WebStoredCall] containing all necessary information of this
  /// [OngoingCall] to be stored in the browser's storage.
  WebStoredCall toStored() {
    return WebStoredCall(
      chatId: chatId.value,
      call: call.value,
      creds: creds,
      state: state.value,
      deviceId: deviceId,
    );
  }
}
