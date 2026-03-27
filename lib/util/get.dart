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

/// Extension adding ability to find non-strict dependencies from a
/// [GetInterface].
extension GetExtension on GetInterface {
  /// Returns the [S] dependency, if it [Inst.isRegistered].
  S? findOrNull<S>({String? tag}) {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }

    return null;
  }

  /// Puts the [dependency], if it isn't [Inst.isRegistered].
  S putOrGet<S>(
    S Function() dependency, {
    String? tag,
    bool permanent = false,
  }) {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }

    return put<S>(dependency(), tag: tag, permanent: permanent);
  }
}
