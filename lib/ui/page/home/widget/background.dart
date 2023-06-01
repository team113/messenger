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

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// [Widget] which builds the [HomeController.background] visual
/// representation.
class HomeBackground extends StatelessWidget {
  const HomeBackground(this.background, this.sideBarWidth, {super.key});

  /// Background as a [Uint8List].
  final Uint8List? background;

  /// Width of the side bar.
  final double sideBarWidth;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final Widget image;

    final double width = sideBarWidth;

    if (background != null) {
      image = Image.memory(
        background!,
        key: Key('Background_${background!.lengthInBytes}'),
        fit: BoxFit.cover,
      );
    } else {
      image = const SizedBox();
    }
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: SvgImage.asset(
                'assets/images/background_light.svg',
                key: const Key('DefaultBackground'),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: 250.milliseconds,
                layoutBuilder: (child, previous) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [...previous, if (child != null) child]
                        .map((e) => Positioned.fill(child: e))
                        .toList(),
                  );
                },
                child: image,
              ),
            ),
            Positioned.fill(
              child: ColoredBox(color: style.colors.onBackgroundOpacity7),
            ),
            if (!context.isNarrow) ...[
              Row(
                children: [
                  ConditionalBackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: context.isNarrow ? 0 : width,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                  Expanded(
                      child: ColoredBox(
                    color: style.colors.onBackgroundOpacity2,
                  )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
