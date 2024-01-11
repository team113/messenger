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

import '/api/backend/schema.graphql.dart';
import '/domain/model/session.dart';

/// Extension adding [Credentials] models construction from a
/// [SignUp$Mutation] response.
extension SignUpCredentials on SignUp$Mutation {
  /// Constructs the new [Credentials] from this [SignUp$Mutation].
  Credentials toModel() {
    return Credentials(
      Session(createUser.session.token, createUser.session.expireAt),
      RememberedSession(
          createUser.remembered!.token, createUser.remembered!.expireAt),
      createUser.user.id,
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
      Session(session.token, session.expireAt),
      RememberedSession(remembered!.token, remembered!.expireAt),
      user.id,
    );
  }
}

/// Extension adding [Credentials] models construction from a
/// [RenewSession$Mutation$RenewSession$RenewSessionOk] response.
extension RenewSessionCredentials
    on RenewSession$Mutation$RenewSession$RenewSessionOk {
  /// Constructs the new [Credentials] from this
  /// [RenewSession$Mutation$RenewSession$RenewSessionOk].
  Credentials toModel() {
    return Credentials(
      Session(session.token, session.expireAt),
      RememberedSession(remembered.token, remembered.expireAt),
      user.id,
    );
  }
}
