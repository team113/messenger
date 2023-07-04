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

// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/widget_button.dart';
import '/l10n/l10n.dart';
import '/themes.dart';

class AvatarView extends StatelessWidget {
  const AvatarView({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Column(
          children: [
            Tooltip(
              message: 'User avatars',
              child: SizedBox(
                height: 120,
                width: 250,
                child: GridView.count(
                  crossAxisCount: style.colors.userColors.length ~/ 2,
                  children: List.generate(
                    style.colors.userColors.length,
                    (i) => AvatarWidget(
                      title: 'John Doe',
                      color: i,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 150),
        const Column(
          children: [
            Tooltip(
              message: 'Changing the avatar',
              child: Padding(
                padding: EdgeInsets.only(bottom: 25),
                child: _AnimatedCircleAvatar(
                  avatar: AvatarWidget(
                    radius: 50,
                    title: 'John Doe',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// TODO: Replace with AnimatedCircleAvatar after merge #427
class _AnimatedCircleAvatar extends StatelessWidget {
  const _AnimatedCircleAvatar({
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
