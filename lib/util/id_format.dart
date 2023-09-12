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

/// The correct format for the UserId
extension StringIdFormatting on String {
  String? idFormat() {
    if (isEmpty) return null;

    String modifiedUserId = '';
    for (int i = 0; i < length; i += 4) {
      modifiedUserId += substring(i, i + 4);
      if (i + 4 < length) {
        modifiedUserId += ' ';
      }
    }
    return modifiedUserId;
  }
}
