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

import 'package:flutter/material.dart';

import '../widget/headlines.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/widget/progress_indicator.dart';

/// [Routes.style] fields section.
class LoadersSection {
  /// Returns the [Widget]s of this [LoadersSection].
  static List<Widget> build(BuildContext context) {
    final style = Theme.of(context).style;

    return [
      Headlines(
        children: [
          (
            headline: 'CustomProgressIndicator.big()',
            widget: CustomProgressIndicator.big(),
          ),

          (
            headline: 'CustomProgressIndicator.primary()',
            widget: CustomProgressIndicator.primary(),
          ),
          (
            headline: 'CustomProgressIndicator.small()',
            widget: CustomProgressIndicator.small(),
          ),
        ],
      ),

      Headlines(
        color: style.colors.onBackground,
        children: [
          (
            headline: 'CustomProgressIndicator.bold()',
            widget: CustomProgressIndicator.bold(),
          ),
        ],
      ),
    ];
  }
}
