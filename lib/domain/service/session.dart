// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import '/domain/repository/session.dart';
import 'disposable_service.dart';

/// Service responsible for [Session]s management.
class SessionService extends Dependency {
  SessionService(this._sessionRepository);

  /// Repository responsible for storing [Session]s.
  final AbstractSessionRepository _sessionRepository;

  /// Returns the reactive list of active [Session]s.
  RxList<RxSession> get sessions => _sessionRepository.sessions;

  /// Indicates whether the current device is connected to any network.
  RxBool get connected => _sessionRepository.connected;

  /// Sets the provided [language] as a preferred localization of
  /// [IpGeoLocation].
  void setLanguage(String? language) =>
      _sessionRepository.setLanguage(language);

  /// Fetches the [IpGeoLocation] of the provided [ip].
  ///
  /// Uses the current [IpAddress], if [ip] is not provided.
  Future<IpGeoLocation> fetch({IpAddress? ip}) =>
      _sessionRepository.fetch(ip: ip);
}
