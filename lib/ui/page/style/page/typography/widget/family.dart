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

import '/config.dart';
import '/themes.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// [Column] describing visually a font family of the provided [weight].
class FontFamily extends StatelessWidget {
  const FontFamily({
    super.key,
    required this.weight,
    required this.name,
    required this.asset,
  });

  /// [FontWeight] of the family to describe.
  final FontWeight weight;

  /// Name of this [FontFamily].
  final String name;

  /// Asset name of this [FontFamily].
  final String asset;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'G, The quick brown fox jumps over the lazy dog${', the quick brown fox jumps over the lazy dog' * 10}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style.fonts.largest.regular.onBackground.copyWith(
            fontWeight: weight,
          ),
        ),
        const SizedBox(height: 4),
        WidgetButton(
          onPressed: () async {
            await PlatformUtils.saveTo(
              '${Config.origin}/assets/assets/fonts/$asset',
            );

            MessagePopup.success('$asset downloaded');
          },
          child: Text(name, style: style.fonts.smaller.regular.primary),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
