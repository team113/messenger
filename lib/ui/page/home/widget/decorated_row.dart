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
import 'package:get/get.dart';

import '/routes.dart';
import '/util/platform_utils.dart';

/// Row with the [leading] and [trailing] widgets.
class DecoratedRow extends StatelessWidget {
  const DecoratedRow({super.key, this.leading, this.trailing});

  /// Optional leading [Widget].
  final Widget? leading;

  /// Optional trailing [Widget].
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        7,
        8,
        PlatformUtils.isMobile && !PlatformUtils.isWeb
            ? router.context!.mediaQuery.padding.bottom + 7
            : 12,
      ),
      child: Row(
        children: [
          if (leading != null) leading!,
          const SizedBox(width: 10),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
