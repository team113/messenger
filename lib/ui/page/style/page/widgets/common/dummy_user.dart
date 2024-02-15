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

import 'package:get/get.dart';

import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';

/// Dummy implementation of [RxUser].
///
/// Used to show [RxUser] related [Widget]s.
class DummyRxUser extends RxUser {
  @override
  Rx<RxChat?> get dialog => Rx(null);

  @override
  Rx<User> get user => Rx(
        User(
          const UserId('me'),
          UserNum('1234123412341234'),
          name: UserName('Participant'),
        ),
      );

  @override
  Rx<PreciseDateTime?> get lastSeen => Rx(PreciseDateTime.now());

  @override
  Stream<void> get updates => const Stream.empty();
}
