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
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';

void main() {
  group('getDelay returns correct results', () {
    test('returns a delay when online', () {
      final User user = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        online: true,
      );
      expect(user.getDelay(), const Duration(seconds: 0));
    });

    test('returns a delay when offline', () {
      final User user = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        online: false,
      );
      expect(user.getDelay(), const Duration(seconds: 0));
    });

    test('returns a delay when presence is away and offline', () {
      final User user1 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        online: false,
        presenceIndex: 0,
      );
      expect(
        user1.getDelay(),
        const Duration(seconds: 59),
      );

      final User user2 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(
            const Duration(minutes: 1, seconds: 1),
          ),
        ),
        online: false,
        presenceIndex: 0,
      );
      expect(user2.getDelay(), const Duration(seconds: 59));

      final User user3 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(
            const Duration(hours: 1, seconds: 1),
          ),
        ),
        online: false,
        presenceIndex: 0,
      );
      expect(
        user3.getDelay(),
        const Duration(minutes: 59, seconds: 59),
      );

      final User user4 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(
            const Duration(days: 1, seconds: 1),
          ),
        ),
        online: false,
        presenceIndex: 0,
      );
      expect(
        user4.getDelay(),
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );

      final User user5 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(seconds: 60)),
        ),
        online: false,
        presenceIndex: 0,
      );
      expect(user5.getDelay(), const Duration(seconds: 0));

      final User user6 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(minutes: 60)),
        ),
        online: false,
        presenceIndex: 0,
      );
      expect(user6.getDelay(), const Duration(seconds: 0));

      final User user7 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(hours: 24)),
        ),
        online: false,
        presenceIndex: 0,
      );
      expect(user7.getDelay(), const Duration(seconds: 0));
    });

    test('returns a delay when presence is present and offline', () {
      final User user1 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        online: false,
        presenceIndex: 1,
      );
      expect(user1.getDelay(), const Duration(seconds: 59));

      final User user2 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(
            const Duration(minutes: 1, seconds: 1),
          ),
        ),
        online: false,
        presenceIndex: 1,
      );
      expect(user2.getDelay(), const Duration(seconds: 59));

      final User user3 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(
            const Duration(hours: 1, seconds: 1),
          ),
        ),
        online: false,
        presenceIndex: 1,
      );
      expect(
        user3.getDelay(),
        const Duration(minutes: 59, seconds: 59),
      );

      final User user4 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(
            const Duration(days: 1, seconds: 1),
          ),
        ),
        online: false,
        presenceIndex: 1,
      );
      expect(
        user4.getDelay(),
        const Duration(hours: 23, minutes: 59, seconds: 59),
      );

      final User user5 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(seconds: 60)),
        ),
        online: false,
        presenceIndex: 1,
      );
      expect(user5.getDelay(), const Duration(seconds: 0));

      final User user6 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(minutes: 60)),
        ),
        online: false,
        presenceIndex: 1,
      );
      expect(user6.getDelay(), const Duration(seconds: 0));

      final User user7 = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(hours: 24)),
        ),
        online: false,
        presenceIndex: 1,
      );
      expect(user7.getDelay(), const Duration(seconds: 0));
    });

    test('returns a delay when presence is artemisUnknown and offline', () {
      final User user = User(
        const UserId('12345'),
        UserNum('1234567890123456'),
        lastSeenAt: PreciseDateTime(
          DateTime.now().subtract(const Duration(seconds: 1)),
        ),
        online: false,
        presenceIndex: 2,
      );
      expect(user.getDelay(), const Duration(seconds: 0));
    });
  });
}
