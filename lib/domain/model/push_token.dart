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

import '/util/new_type.dart';

/// Possible identifiers of [MyUser]'s push device token.
class DeviceToken {
  const DeviceToken({this.apns, this.voip, this.fcm});

  /// Apple Push Notification service device token.
  final ApnsDeviceToken? apns;

  /// Apple Push Notification service VoIP device token.
  final ApnsVoipDeviceToken? voip;

  /// Firebase Cloud Messaging registration token.
  final FcmRegistrationToken? fcm;

  @override
  String toString() => 'DeviceToken(apns: $apns, voip: $voip, fcm: $fcm)';
}

/// [Apple Push Notification][1] service device token.
///
/// [1]: https://developer.apple.com/documentation/usernotifications
class ApnsDeviceToken extends NewType<String> {
  const ApnsDeviceToken(super.val);
}

/// [Apple Push Notification VoIP][1] service device token.
///
/// [1]: https://developer.apple.com/documentation/usernotifications
class ApnsVoipDeviceToken extends NewType<String> {
  const ApnsVoipDeviceToken(super.val);
}

/// [Firebase Cloud Messaging][1] registration token.
///
/// [1]: https://firebase.google.com/docs/cloud-messaging
class FcmRegistrationToken extends NewType<String> {
  const FcmRegistrationToken(super.val);
}
