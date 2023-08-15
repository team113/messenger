// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';

import '/util/obs/obs.dart';

/// Extension adding an ability to get [ListChangeNotification]s from [Stream].
extension ChangesExtension<T> on Stream<List<T>> {
  /// Gets [ListChangeNotification]s from [Stream].
  Stream<ListChangeNotification<T>> changes(dynamic Function(T) getId) {
    List<T> last = [];

    return asyncExpand((e) async* {
      for (int i = 0; i < e.length; ++i) {
        final item = last.firstWhereOrNull((m) => getId(m) == getId(e[i]));
        if (item == null) {
          yield ListChangeNotification.added(e[i], i);
        } else {
          if (e[i] != item) {
            yield ListChangeNotification.updated(e[i], i);
          }
        }
      }

      for (int i = 0; i < last.length; ++i) {
        final item = e.firstWhereOrNull((m) => getId(m) == getId(last[i]));
        if (item == null) {
          yield ListChangeNotification.removed(last[i], i);
        }
      }

      last = e;
    });
  }
}
