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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../common/cat.dart';
import '../widget/headlines.dart';
import '/routes.dart';
import '/ui/page/home/widget/avatar.dart';

/// [Routes.style] avatars section.
class AvatarsSection {
  /// Returns the [Widget]s of this [AvatarsSection].
  static List<Widget> build() {
    ({String headline, Widget widget}) avatars(
      String title,
      AvatarRadius radius,
    ) {
      return (
        headline:
            'AvatarWidget(radius: ${radius.toDouble().toStringAsFixed(0)})',
        widget: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AvatarWidget(title: title, radius: radius),
            AvatarWidget(
              radius: radius,
              child: Image.memory(CatImage.bytes, fit: BoxFit.cover),
            ),
          ],
        ),
      );
    }

    return [
      Headlines(
        children: AvatarRadius.values.reversed
            .mapIndexed((i, e) => avatars(i.toString().padLeft(2, '0'), e))
            .toList(),
      ),
    ];
  }
}
