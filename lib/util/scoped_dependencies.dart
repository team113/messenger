// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

/// Helper for managing [Get] dependencies with a scoped lifetime.
class ScopedDependencies {
  /// List of dependencies disposing functions.
  final List<void Function()> _cleanup = [];

  /// Puts the given [dependency] in this scope.
  T put<T>(T dependency, {String? tag}) {
    _cleanup.add(() => Get.delete<T>());
    return Get.put<T>(dependency, tag: tag);
  }

  /// Disposes all the scoped dependencies.
  void dispose() {
    for (var e in _cleanup) {
      e.call();
    }
    _cleanup.clear();
  }
}
