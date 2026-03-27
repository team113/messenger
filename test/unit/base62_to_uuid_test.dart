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
import 'package:messenger/ui/worker/call.dart';

void main() async {
  test('Base62ToUuid converts Base62 to UUID correctly', () async {
    expect(
      '7FdwVhQEjVMHIaeB2t4487'.base62ToUuid(),
      'ee49e501-ce4c-4940-92d2-602c8266ffd7',
    );

    expect(
      'bh3JQNDEHfRTrnIKic6c'.base62ToUuid(),
      '00527b68-cb58-4da8-ad13-2e8a245cba92',
    );
  });
}
