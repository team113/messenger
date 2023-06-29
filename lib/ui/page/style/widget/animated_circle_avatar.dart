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
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';

import '../../../widget/progress_indicator.dart';
import '../../../widget/widget_button.dart';

/// TODO: Replace with AnimatedCircleAvatar after merge #427
class AnimatedCircleAvatar extends StatelessWidget {
  const AnimatedCircleAvatar({
    super.key,
    this.avatar,
    this.onPressed,
    this.onPressedAdditional,
    this.isLoading = false,
    this.isVisible = true,
  });

  /// Indicator whether this widget is currently loading.
  final bool isLoading;

  /// Indicator whether the additional label should be shown.
  final bool isVisible;

  /// [Widget] that is displayed within the circle.
  final Widget? avatar;

  /// Callback, called when label was pressed.
  final void Function()? onPressed;

  /// Callback, called when additional label was pressed.
  final void Function()? onPressedAdditional;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            if (avatar != null) avatar!,
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: 200.milliseconds,
                child: isLoading
                    ? Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: style.colors.onBackgroundOpacity13,
                        ),
                        child: const Center(child: CustomProgressIndicator()),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WidgetButton(
              key: const Key('UploadAvatar'),
              onPressed: onPressed,
              child: Text(
                'btn_upload'.l10n,
                style: fonts.labelSmall!.copyWith(color: style.colors.primary),
              ),
            ),
            if (isVisible) ...[
              Text(
                'space_or_space'.l10n,
                style: fonts.labelSmall!.copyWith(
                  color: style.colors.onBackground,
                ),
              ),
              WidgetButton(
                key: const Key('DeleteAvatar'),
                onPressed: onPressedAdditional,
                child: Text(
                  'btn_delete'.l10n.toLowerCase(),
                  style:
                      fonts.labelSmall!.copyWith(color: style.colors.primary),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
