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

import '/api/backend/schema.graphql.dart';
import '/domain/model/session.dart';
import 'my_user.dart';

/// Extension adding models construction from a [RefreshTokenMixin].
extension RefreshTokenConversion on RefreshTokenMixin {
  /// Constructs a new [RefreshToken] from this [RefreshTokenMixin].
  RefreshToken toModel() => RefreshToken(secret, expiresAt);
}

/// Extension adding models construction from a [AccessTokenMixin].
extension AccessTokenConversion on AccessTokenMixin {
  /// Constructs a new [AccessToken] from this [AccessTokenMixin].
  AccessToken toModel() => AccessToken(secret, expiresAt);
}

/// Extension adding [Credentials] models construction from a
/// [SignUp$Mutation] response.
extension SignUpCredentials on SignUp$Mutation$CreateUser$CreateSessionOk {
  /// Constructs the new [Credentials] from this [SignUp$Mutation].
  Credentials toModel() {
    return Credentials(
      accessToken.toModel(),
      refreshToken.toModel(),
      session.toModel(),
      user.id,
    );
  }
}

/// Extension adding [Credentials] models construction from a
/// [SignIn$Mutation$CreateSession$CreateSessionOk] response.
extension SignInCredentials on SignIn$Mutation$CreateSession$CreateSessionOk {
  /// Constructs the new [Credentials] from this
  /// [SignIn$Mutation$CreateSession$CreateSessionOk].
  Credentials toModel() {
    return Credentials(
      accessToken.toModel(),
      refreshToken.toModel(),
      session.toModel(),
      user.id,
    );
  }
}

/// Extension adding [Credentials] models construction from a
/// [RefreshSession$Mutation$RefreshSession$CreateSessionOk] response.
extension RefreshSessionCredentials
    on RefreshSession$Mutation$RefreshSession$CreateSessionOk {
  /// Constructs the new [Credentials] from this
  /// [RefreshSession$Mutation$RefreshSession$CreateSessionOk].
  Credentials toModel() {
    return Credentials(
      accessToken.toModel(),
      refreshToken.toModel(),
      session.toModel(),
      user.id,
    );
  }
}
