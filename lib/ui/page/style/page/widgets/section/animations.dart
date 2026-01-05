// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '../widget/headline.dart';
import '../widget/headlines.dart';
import '/routes.dart';
import '/ui/page/call/widget/double_bounce_indicator.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/widget/progress_indicator.dart';

/// [Routes.style] animations section.
class AnimationsSection {
  /// Returns the [Widget]s of this [AnimationsSection].
  static List<Widget> build() {
    return [
      const Headline(
        headline: 'DoubleBounceLoadingIndicator',
        child: SizedBox(child: DoubleBounceLoadingIndicator()),
      ),
      const Headline(
        headline: 'AnimatedTyping',
        child: SizedBox(height: 32, child: Center(child: AnimatedTyping())),
      ),
      const Headlines(
        children: [
          (
            headline: 'CustomProgressIndicator',
            widget: SizedBox(child: Center(child: CustomProgressIndicator())),
          ),
          (
            headline: 'CustomProgressIndicator.small',
            widget: SizedBox(
              child: Center(child: CustomProgressIndicator.small()),
            ),
          ),
          (
            headline: 'CustomProgressIndicator.big',
            widget: SizedBox(
              child: Center(child: CustomProgressIndicator.big()),
            ),
          ),
          (
            headline: 'CustomProgressIndicator.primary',
            widget: SizedBox(
              child: Center(child: CustomProgressIndicator.primary()),
            ),
          ),
        ],
      ),
    ];
  }
}
