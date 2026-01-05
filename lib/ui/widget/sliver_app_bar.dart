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

import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';

/// Custom stylized and decorated [SliverAppBar].
class CustomSliverAppBar extends StatelessWidget {
  const CustomSliverAppBar({
    super.key,
    this.title,
    this.subtitle = const [],
    this.leading = const [],
    this.actions = const [],
    this.flexible,
    this.hasFlexible = true,
    this.height = 60,
    this.extended = 110,
  });

  /// Primary centered [Widget] of this [CustomAppBar].
  final Widget? title;

  final List<Widget> subtitle;

  /// [Widget]s displayed in a row before the [title].
  final List<Widget> leading;

  /// [Widget]s displayed in a row after the [title].
  final List<Widget> actions;

  /// Height of the [title] and [subtitle] in non-expanded form.
  final double height;

  /// Height of the whole app bar ([title], [subtitle] and [flexible]) in
  /// expanded form.
  final double extended;

  /// [Widget] to display in a [FlexibleSpaceBar] or under the [title].
  final Widget? flexible;

  /// Indicator whether [flexible] should be [FlexibleSpaceBar].
  ///
  /// If `false`, then [flexible] is still displayed, but as a [subtitle].
  final bool hasFlexible;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return SliverAppBar(
      elevation: 8,
      forceElevated: true,
      shadowColor: style.colors.onBackgroundOpacity40,
      surfaceTintColor: style.colors.transparent,
      backgroundColor: style.colors.onPrimary,
      pinned: true,
      floating: false,
      titleSpacing: 0,
      expandedHeight: hasFlexible ? extended : height,
      toolbarHeight: hasFlexible ? height : extended,
      shape: BoxBorder.fromLTRB(right: style.cardBorder.right),
      flexibleSpace: flexible != null && hasFlexible
          ? FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: flexible,
              expandedTitleScale: 1,
            )
          : null,
      title: Container(
        decoration: BoxDecoration(color: style.cardColor),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: CustomAppBar.rawHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Spacer(),
                  SizedBox(
                    height: 59,
                    child: NavigationToolbar(
                      centerMiddle: true,
                      middleSpacing: 0,
                      middle: DefaultTextStyle.merge(
                        style: style.fonts.large.regular.onBackground,
                        child: title ?? const SizedBox.shrink(),
                      ),
                      leading: leading.isEmpty
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: leading,
                            ),
                      trailing: actions.isEmpty
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: actions,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            if (!hasFlexible) ?flexible,
          ],
        ),
      ),
    );
  }
}
