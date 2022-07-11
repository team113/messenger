// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

/// Controller of [Selector] popup.
class SelectorController extends GetxController {
  SelectorController(int initialIndex, this.onSelect)
      : selected = RxInt(initialIndex);

  /// Index of selected item.
  final RxInt selected;

  /// Callback which is called on selection complete.
  final Function(int)? onSelect;

  /// Prevents instant call of [onSelect] after the user has set
  ///  [selected] item.
  late final Worker _debounce;

  @override
  void onInit() {
    _debounce = debounce(
      selected,
      (int i) {
        if (onSelect != null) {
          onSelect?.call(i);
        }
      },
      time: 500.milliseconds,
    );

    super.onInit();
  }

  @override
  void onClose() {
    _debounce.dispose();
    super.onClose();
  }
}
