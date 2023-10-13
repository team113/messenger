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

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/widget/animated_button.dart';
import '/util/platform_utils.dart';

/// Styled bottom navigation bar consisting of [items].
class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({
    super.key,
    this.currentIndex = 0,
    this.items = const [],
    this.onTap,
  });

  /// Currently selected index of an item in the [items] list.
  final int currentIndex;

  /// List of [CustomNavigationBarItem]s that this [CustomNavigationBar]
  /// consists of.
  final List<CustomNavigationBarItem> items;

  /// Callback, called when an item in [items] list is pressed.
  final Function(int)? onTap;

  /// Height of the [CustomNavigationBar].
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      decoration: BoxDecoration(
        boxShadow: [
          CustomBoxShadow(
            blurRadius: 8,
            color: style.colors.onBackgroundOpacity13,
            blurStyle: BlurStyle.outer,
          ),
        ],
        borderRadius: style.cardRadius,
        border: style.cardBorder,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConditionalBackdropFilter(
            condition: style.cardBlur > 0,
            borderRadius: style.cardRadius,
            filter: ImageFilter.blur(
              sigmaX: style.cardBlur,
              sigmaY: style.cardBlur,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: style.cardColor,
                borderRadius: style.cardRadius,
              ),
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: items.mapIndexed((i, b) {
                    return Expanded(
                      key: b.key,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (b.child != null)
                            _CustomNavigationBarButton(
                              selected: currentIndex == i,
                              onPressed: () => onTap?.call(i),
                              child: Container(
                                width: 80,
                                color: style.colors.transparent,
                                child: Center(
                                  child: Badge(
                                    largeSize: 15,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 4.4,
                                    ),
                                    offset: const Offset(2, -2),
                                    label: b.badge == null
                                        ? null
                                        : Transform.translate(
                                            offset: PlatformUtils.isWeb
                                                ? Offset(
                                                    0,
                                                    PlatformUtils.isIOS
                                                        ? 0
                                                        : 0.25,
                                                  )
                                                : PlatformUtils.isDesktop
                                                    ? const Offset(-0.1, -0.2)
                                                    : Offset.zero,
                                            child: Text(
                                              b.badge!,
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                    textStyle: style.fonts.bodyTinyOnPrimary,
                                    backgroundColor:
                                        b.badgeColor ?? style.colors.danger,
                                    isLabelVisible: b.badge != null,
                                    child: b.child!,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single item of [CustomNavigationBar].
class CustomNavigationBarItem {
  const CustomNavigationBarItem({
    this.key,
    this.badge,
    this.badgeColor,
    this.child,
  });

  /// Unique [Key] of this [CustomNavigationBarItem].
  final Key? key;

  /// Optional text to put into a [Badge] over this item.
  final String? badge;

  /// [Color] of the provided [badge], if any.
  final Color? badgeColor;

  /// [Widget] to display.
  final Widget? child;
}

/// [AnimatedButton] with [AnimatedScale] representing a single button of
/// [CustomNavigationBar].
class _CustomNavigationBarButton extends StatelessWidget {
  const _CustomNavigationBarButton({
    this.selected = false,
    this.onPressed,
    required this.child,
  });

  /// Widget of this [_CustomNavigationBarButton].
  final Widget child;

  /// Indicator whether this [_CustomNavigationBarButton] is selected.
  final bool selected;

  /// Callback, called when this [_CustomNavigationBarButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 150),
      curve: Curves.bounceInOut,
      scale: selected ? 1.1 : 1,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: selected ? 1 : 0.7,
        child: AnimatedButton(onPressed: onPressed, child: child),
      ),
    );
  }
}
