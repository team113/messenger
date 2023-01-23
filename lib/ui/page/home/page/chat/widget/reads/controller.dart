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
import 'package:get/get.dart';
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/domain/repository/user.dart';

import '/ui/widget/text_field.dart';

class ChatItemReadsController extends GetxController {
  ChatItemReadsController({this.reads = const [], this.getUser});

  /// [LastChatRead]s themselves.
  final Iterable<LastChatRead> reads;

  /// Callback, called when a [RxUser] identified by the provided [UserId] is
  /// required.
  final Future<RxUser?> Function(UserId userId)? getUser;

  final TextFieldState search = TextFieldState();

  final RxnString query = RxnString(null);
  final RxList<RxUser> users = RxList();

  @override
  void onInit() {
    init();

    super.onInit();
  }

  Future<void> init() async {
    // for (var v in reads) {
    //   RxUser? user = await getUser?.call(v.memberId);
    //   print('user $user');
    //   if (user != null) {
    //     users.add(user);
    //   }
    // }

    List<Future> futures = reads
        .map((e) => getUser?.call(e.memberId)?..then((v) => users.add(v!)))
        .whereNotNull()
        .toList();

    await Future.wait(futures);
  }
}
