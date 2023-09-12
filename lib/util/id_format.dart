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

// idFormat is designed to format the id in the correct form
String? idFormat(String? userId) {
  if (userId == null) return null;

  String modifiedUserId = '';
  for (int i = 0; i < userId.length; i += 4) {
    modifiedUserId += userId.substring(i, i + 4);
    if (i + 4 < userId.length) {
      modifiedUserId += ' ';
    }
  }
  return modifiedUserId;
}
