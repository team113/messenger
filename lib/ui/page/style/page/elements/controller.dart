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

import '/ui/widget/text_field.dart';

class ElementsController extends GetxController {
  /// [MyUser.name]'s field state.
  late final TextFieldState name;

  /// [MyUser.name]'s field state.
  late final TextFieldState typing;

  /// [MyUser.name]'s field state.
  late final TextFieldState loading;

  /// [MyUser.name]'s field state.
  late final TextFieldState success;

  /// [MyUser.name]'s field state.
  late final TextFieldState error;

  @override
  void onInit() {
    loading = TextFieldState(
      text: 'Benedict Cumberbatch',
      editable: false,
      status: RxStatus.loading(),
    );

    typing = TextFieldState(text: 'Benedict Cumberba');

    success = TextFieldState(
      text: 'Benedict Cumberbatch',
      status: RxStatus.success(),
    );

    error = TextFieldState(
      text: 'Benedict C@c@mber',
      status: RxStatus.error(),
      onChanged: (s) => s.error.value = 'Incorrect input',
      onSubmitted: (s) => s.error.value = 'Incorrect input',
    );

    name = TextFieldState(
      text: 'Benedict Cumberbatch',
      approvable: true,
      onChanged: (s) async {
        s.error.value = null;
      },
      onSubmitted: (s) async {
        s.error.value = null;

        if (s.error.value == null) {
          s.editable.value = false;
          s.status.value = RxStatus.loading();
          try {
            s.status.value = RxStatus.empty();
          } catch (e) {
            s.status.value = RxStatus.empty();
            rethrow;
          } finally {
            s.editable.value = true;
          }
        }
      },
    );
    super.onInit();
  }
}
