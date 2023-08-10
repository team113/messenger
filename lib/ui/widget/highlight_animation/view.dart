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

import '/themes.dart';
import '/ui/widget/highlight_animation/controller.dart';

/// Animation of highlighting the [child].
class HighlightAnimation extends StatelessWidget {
  const HighlightAnimation({super.key, required this.child, this.index});

  /// [Widget] to animate to.
  final Widget child;

  /// Index of an item that should be highlighted.
  final int? index;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;
    HighlightController h = Get.put(HighlightController());

    return Obx(() {
      return AnimatedContainer(
        duration: 400.milliseconds,
        curve: Curves.ease,
        color: h.highlightIndex.value == index
            ? style.colors.primaryOpacity20
            : style.colors.primaryOpacity20.withOpacity(0),
        child: child,
      );
    });
  }
}
