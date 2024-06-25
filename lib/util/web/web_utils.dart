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


export 'non_web.dart' if (dart.library.js_interop) 'web.dart';

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
