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

import 'package:flutter_test/flutter_test.dart';
import 'package:messenger/util/fixed_timer.dart';

void main() {
  test('FixedTimer.periodic() is invoked correctly', () async {
    DateTime invokedAt1 = DateTime.now();
    DateTime invokedAt2 = DateTime.now();

    FixedTimer.periodic(
      const Duration(milliseconds: 200),
      () => invokedAt1 = DateTime.now(),
    );

    await Future.delayed(const Duration(milliseconds: 100));

    FixedTimer.periodic(
      const Duration(milliseconds: 200),
      () => invokedAt2 = DateTime.now(),
    );

    await Future.delayed(const Duration(milliseconds: 200));

    expect(invokedAt1.difference(invokedAt2).inMilliseconds.abs() < 10, true);
  });

  test('FixedTimer can be canceled', () async {
    int invoked = 0;

    final FixedTimer timer = FixedTimer.periodic(
      const Duration(milliseconds: 200),
      () => invoked++,
    );

    timer.cancel();

    await Future.delayed(const Duration(milliseconds: 300));

    expect(invoked, 0);
  });
}
