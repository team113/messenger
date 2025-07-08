// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '/domain/service/disposable_service.dart';
import '/routes.dart';
import '/ui/page/support/log/view.dart';
import '/ui/widget/text_field.dart';

/// Worker opening [LogView] modal.
class LogWorker extends DisposableService {
  LogWorker();

  @override
  void onInit() {
    HardwareKeyboard.instance.addHandler(_consoleListener);
    super.onInit();
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_consoleListener);
    super.onClose();
  }

  /// Opens the [LogView] modal on tilde key presses.
  bool _consoleListener(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.tilde) {
        if (TextFieldState.focuses.isEmpty) {
          if (router.obscuring.any((e) => e.settings.name == 'LogView')) {
            Navigator.of(router.context!).pop();
          } else {
            LogView.show(router.context!);
          }

          return true;
        }
      }
    }

    return false;
  }
}
