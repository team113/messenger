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

import 'package:flutter/material.dart';

/// Extension adding an ability to pop current route if it is active.
extension PopExtensionOnNavigator on NavigatorState {
  /// Pops current route if it is active.
  void popIfActive(BuildContext context, [Object? result]) {
    if (context.mounted && ModalRoute.of(context)?.isActive == true) {
      if (ModalRoute.of(context)!.isCurrent == true) {
        pop(result);
      } else if (result != null) {
        popUntil((_) => ModalRoute.of(context)!.isCurrent == true);
        pop(result);
      } else {
        removeRoute(ModalRoute.of(context)!);
      }
    }
  }
}
