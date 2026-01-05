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

import 'package:get/get.dart';

import '/domain/model/session.dart';

/// Active [Session]s of the currently authenticated [MyUser] provider.
abstract class AbstractSessionRepository {
  /// Returns the reactive list of active [Session]s.
  RxList<RxSession> get sessions;

  /// Indicates whether the current device is connected to any network.
  RxBool get connected;

  /// Fetches the [IpGeoLocation] of the provided [ip].
  ///
  /// Uses the current [IpAddress], if [ip] is not provided.
  Future<IpGeoLocation> fetch({IpAddress? ip});

  /// Sets the provided [language] as a preferred localization of
  /// [IpGeoLocation].
  void setLanguage(String? language);
}

/// Reactive [Session] entity alongside its [IpGeoLocation] data.
abstract class RxSession implements Comparable<RxSession> {
  /// Returns the [Session] itself.
  Rx<Session> get session;

  /// Returns the [IpGeoLocation] of the [session].
  Rx<IpGeoLocation?> get geo;

  /// Returns the unique ID of this [Session].
  SessionId get id => session.value.id;

  @override
  int compareTo(RxSession other) =>
      session.value.compareTo(other.session.value);
}
