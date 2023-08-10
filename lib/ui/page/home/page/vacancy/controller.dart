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

import 'package:get/get.dart';
import 'package:messenger/domain/model/vacancy.dart';

class VacancyController extends GetxController {
  VacancyController(this.id);

  final String id;

  final Rx<Vacancy?> vacancy = Rx(null);

  @override
  void onInit() {
    vacancy.value = Vacancies.all.firstWhereOrNull((e) => e.id == id);
    super.onInit();
  }

  Future<void> contact() async {
    // final user = await _userService
    //     .get(const UserId('7d65c931-940e-4d2a-b208-b0795537944f'));

    // RxChat? chat = user?.dialog.value;
    // chat ??= await _chatService.get(
    //   ChatId.local(const UserId('7d65c931-940e-4d2a-b208-b0795537944f')),
    // );

    // if (chat != null) {
    //   router.chat(chat.id, push: true);
    //   await _chatService.sendChatMessage(
    //     chat.id,
    //     text: ChatMessageText(
    //       'Transaction ID: ${transaction.id}.\nPayer\'s name: ${name.text}',
    //     ),
    //   );
    // }
  }
}
