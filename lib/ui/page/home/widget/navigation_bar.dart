// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:badges/badges.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/call/widget/conditional_backdrop.dart';

/// Styled bottom navigation bar consisting of [items].
class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({
    Key? key,
    this.currentIndex = 0,
    this.items = const [],
    this.size,
    this.onTap,
    this.selectedColor = const Color(0xFF4193DC),
    this.unselectedColor = const Color(0xA6818181),
  }) : super(key: key);

  /// Currently selected index of an item in the [items] list.
  final int currentIndex;

  /// List of [CustomNavigationBarItem]s that this [CustomNavigationBar]
  /// consists of.
  final List<CustomNavigationBarItem> items;

  /// Callback, called when an item in [items] list is pressed.
  final Function(int)? onTap;

  /// Default size of [items] icons.
  final double? size;

  /// Selected item color.
  final Color selectedColor;

  /// Unselected item color.
  final Color unselectedColor;

  @override
  Widget build(BuildContext context) {
    Style style = Theme.of(context).extension<Style>()!;
    bool isMobile = false; //context.isMobile;

    return Padding(
      padding:
          isMobile ? EdgeInsets.zero : const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: const [
            CustomBoxShadow(
              blurRadius: 8,
              color: Color(0x22000000),
              blurStyle: BlurStyle.outer,
            ),
          ],
          borderRadius: style.cardRadius,
          border: style.cardBorder,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Container(
            //   width: double.infinity,
            //   color: const Color(0xFFE0E0E0),
            //   height: 0.5,
            // ),
            ConditionalBackdropFilter(
              condition: style.cardBlur > 0,
              borderRadius: style.cardRadius,
              filter: ImageFilter.blur(
                sigmaX: style.cardBlur,
                sigmaY: style.cardBlur,
              ),
              child: Container(
                decoration: BoxDecoration(
                  // color: Theme.of(context)
                  //     .appBarTheme
                  //     .backgroundColor
                  //     ?.withOpacity(0.8),
                  // color: const Color(0x301D6AAE),
                  color: style.cardColor,
                  borderRadius: isMobile ? BorderRadius.zero : style.cardRadius,
                ),
                height: 56,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: items
                        .mapIndexed(
                          (i, e) => Expanded(
                            key: e.key,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (e.icon != null || e.leading != null)
                                  Badge(
                                    badgeContent: e.badge == null
                                        ? null
                                        : Text(
                                            e.badge!,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                            ),
                                          ),
                                    showBadge: e.badge != null,
                                    child: InkResponse(
                                      hoverColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      splashColor: Colors.transparent,
                                      onTap: () => onTap?.call(i),
                                      child: DefaultTextStyle(
                                        style: TextStyle(
                                          color: currentIndex == i
                                              ? selectedColor
                                              : unselectedColor,
                                          fontSize: 11,
                                        ),
                                        child: e.leading ??
                                            FaIcon(
                                              e.icon,
                                              color: e.color ??
                                                  (currentIndex == i
                                                      ? selectedColor
                                                      : unselectedColor),
                                              size: e.size ?? size,
                                            ),
                                      ),
                                    ),
                                  ),
                                if (e.label != null) Text(e.label!),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single item of [CustomNavigationBar].
class CustomNavigationBarItem {
  const CustomNavigationBarItem({
    this.key,
    this.label,
    this.icon,
    this.size,
    this.color,
    this.badge,
    this.leading,
  });

  /// Unique [Key] of this [CustomNavigationBarItem].
  final Key? key;

  /// Label of this item.
  final String? label;

  /// Icon of this item.
  final IconData? icon;

  /// Size of an [icon].
  ///
  /// Overrides the [CustomNavigationBar.size] for this item.
  final double? size;

  /// Color of an [icon].
  final Color? color;

  /// Optional text to put into a [Badge] over this item.
  final String? badge;

  final Widget? leading;
}
