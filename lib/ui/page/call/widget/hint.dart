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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';

/// Styled popup window with a [text] used to serve as a hint.
class HintWidget extends StatelessWidget {
  const HintWidget({
    super.key,
    required this.text,
    this.onTap,
    this.isError = false,
  });

  /// Text of a hint.
  final String text;

  /// Callback, called when this hint is pressed.
  final GestureTapCallback? onTap;

  /// Indicator whether this [HintWidget] represents an error.
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Card(
      elevation: 8,
      shadowColor: style.colors.onBackgroundOpacity27,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      color: style.colors.backgroundAuxiliaryLightest,
      margin: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 35,
            decoration: BoxDecoration(
              color: style.colors.backgroundAuxiliaryLighter,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                const SizedBox(width: 14),
                SvgImage.asset('assets/icons/face.svg', height: 13),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isError
                        ? 'label_error'.l10n
                        : 'label_hint_from_gapopa'.l10n,
                    style: fonts.bodySmall!.copyWith(
                      color: style.colors.secondaryOpacity87,
                    ),
                  ),
                ),
                Center(
                  child: InkResponse(
                    onTap: onTap,
                    radius: 11,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: style.colors.secondaryOpacity87,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
            child: Center(
              child: Text(
                text,
                style: fonts.bodySmall!.copyWith(
                  color: style.colors.secondaryOpacity87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
