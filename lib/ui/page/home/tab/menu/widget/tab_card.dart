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

import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';

/// Tab card in a [ProfileTab] page
class TabCard extends StatelessWidget {
  const TabCard(
    this.tab, {
    super.key,
    required this.title,
    required this.subtitle,
    this.icon,
    this.onTap,
  });

  /// Current [ProfileTab].
  final ProfileTab tab;

  /// Title of this [TabCard].
  final String title;

  /// Subtitle of this [TabCard].
  final String subtitle;

  /// Icon of this [TabCard].
  final IconData? icon;

  /// Callback, called when this [TabCard] is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Obx(() {
      final bool inverted =
          tab == router.profileSection.value && router.route == Routes.me;

      return Padding(
        key: key,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: SizedBox(
          height: 73,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              border: style.cardBorder,
              color: style.colors.transparent,
            ),
            child: Material(
              type: MaterialType.card,
              borderRadius: style.cardRadius,
              color: inverted ? style.colors.primary : style.cardColor,
              child: InkWell(
                borderRadius: style.cardRadius,
                onTap: onTap ??
                    () {
                      if (router.profileSection.value == tab) {
                        router.profileSection.refresh();
                      } else {
                        router.profileSection.value = tab;
                      }
                      router.me();
                    },
                hoverColor: inverted
                    ? style.colors.primary
                    : style.cardColor.darken(0.03),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        icon,
                        color: inverted
                            ? style.colors.onPrimary
                            : style.colors.primary,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DefaultTextStyle(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall!
                                  .copyWith(
                                    color: inverted
                                        ? style.colors.onPrimary
                                        : null,
                                  ),
                              child: Text(title),
                            ),
                            const SizedBox(height: 6),
                            DefaultTextStyle.merge(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: inverted ? style.colors.onPrimary : null,
                              ),
                              child: Text(subtitle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
