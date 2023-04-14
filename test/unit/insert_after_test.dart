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

import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/store/chat_rx.dart';

void main() {
  test('ListInsertAfter.insertAfter correctly inserts elements', () async {
    final List list = [];

    expect(list..insertAfter(0, (p) => p < 0), [0]);
    expect(list..insertAfter(1, (p) => p < 1), [0, 1]);
    expect(list..insertAfter(2, (p) => p < 2), [0, 1, 2]);
    expect(list..insertAfter(3, (p) => p < 3), [0, 1, 2, 3]);
    expect(list..insertAfter(-1, (p) => p < -1), [-1, 0, 1, 2, 3]);
    expect(list..insertAfter(10, (p) => p < 10), [-1, 0, 1, 2, 3, 10]);
    expect(list..insertAfter(5, (p) => p < 5), [-1, 0, 1, 2, 3, 5, 10]);
  });
}
