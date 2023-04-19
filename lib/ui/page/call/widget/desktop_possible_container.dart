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

import '../controller.dart';
import '../widget/conditional_backdrop.dart';

/// [_SecondaryView] possible alignment.
class PossibleContainerWidget extends StatelessWidget {
  const PossibleContainerWidget(
    this.c, {
    super.key,
  });

  /// Controller of an [OngoingCall] overlay.
  final CallController c;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Alignment? alignment = c.possibleSecondaryAlignment.value;
      if (alignment == null) {
        return Container();
      }

      double width = 10;
      double height = 10;

      if (alignment == Alignment.topCenter ||
          alignment == Alignment.bottomCenter) {
        width = double.infinity;
      } else {
        height = double.infinity;
      }

      return Align(
        alignment: alignment,
        child: ConditionalBackdropFilter(
          child: Container(
            height: height,
            width: width,
            color: const Color(0x4D165084),
          ),
        ),
      );
    });
  }
}
