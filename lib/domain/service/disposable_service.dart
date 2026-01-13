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

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';

/// Base class for services with a scoped lifetime.
abstract class Dependency extends DisposableInterface {}

/// Mixin receiving [onIdentityChanged] every time [UserId] identity of the
/// business logic changes.
mixin IdentityAware {
  /// Recommended [order] of the provider layer dependencies.
  static const int providerOrder = -100;

  /// Recommended [order] of the business logic layer dependencies.
  static const int businessOrder = 0;

  /// Recommended [order] of the interface layer dependencies.
  static const int interfaceOrder = 100;

  /// Returns the order in which the [onIdentityChanged] should be invoked.
  int get order => 0;

  /// Handles identity changes to the provided [UserId].
  void onIdentityChanged(UserId me) {
    // No-op.
  }
}

/// [Dependency] with [IdentityAware] mixin built in as a [me] getter.
class IdentityDependency extends Dependency with IdentityAware {
  IdentityDependency({required UserId me}) : _me = me;

  /// Currently authenticated [MyUser]'s ID this [Dependency] works for.
  UserId? _me;

  /// Returns the current [UserId] of [MyUser] this [Dependency] works for.
  UserId get me => _me!;

  @override
  void onInit() {
    super.onInit();
    onIdentityChanged(me);
  }

  @override
  @mustCallSuper
  void onIdentityChanged(UserId me) {
    _me = me;
  }
}
