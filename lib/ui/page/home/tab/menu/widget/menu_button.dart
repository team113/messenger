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

import '/themes.dart';
import '/ui/page/home/widget/avatar.dart';

/// Rounded button with an [icon], [title] and [subtitle] intended to be used in
/// a menu list.
class MenuButton extends StatefulWidget {
  const MenuButton({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.onPressed,
    this.inverted = false,
    this.children = const [],
    this.trailing = const [],
  });

  /// Optional title of this [MenuButton].
  final String? title;

  /// Optional subtitle of this [MenuButton].
  final String? subtitle;
  final List<Widget> children;

  /// Optional icon of this [MenuButton].
  final Widget? icon;

  /// Callback, called when this [MenuButton] is tapped.
  final void Function()? onPressed;

  /// Indicator whether this [MenuButton] should have its contents inverted.
  final bool inverted;

  final List<Widget> trailing;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _hovered = false;

  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 73,
        child: MouseRegion(
          opaque: false,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              border: style.cardBorder,
              color: style.colors.transparent,
            ),
            child: Material(
              type: MaterialType.card,
              borderRadius: style.cardRadius,
              color: widget.inverted ? style.activeColor : style.cardColor,
              child: InkWell(
                borderRadius: style.cardRadius,
                onTap: widget.onPressed,
                hoverColor: widget.inverted
                    ? style.activeColor
                    : style.cardColor.darken(0.03),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        constraints: const BoxConstraints(minWidth: 56),
                        child: Center(
                          child: AnimatedScale(
                            key: _key,
                            duration: const Duration(milliseconds: 100),
                            scale: _hovered ? 1.05 : 1,
                            child: widget.icon,
                          ),
                        ),
                      ),
                      // const SizedBox(width: 12),
                      // AnimatedScale(
                      //   key: _key,
                      //   duration: const Duration(milliseconds: 100),
                      //   scale: _hovered ? 1.05 : 1,
                      //   child: widget.icon,
                      // ),
                      // const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.title != null)
                              DefaultTextStyle(
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: style.fonts.headlineLarge.copyWith(
                                  color: widget.inverted
                                      ? style.colors.onPrimary
                                      : style.colors.onBackground,
                                ),
                                child: Text(widget.title!),
                              ),
                            if (widget.title != null &&
                                (widget.subtitle != null ||
                                    widget.children.isNotEmpty))
                              const SizedBox(height: 6),
                            if (widget.subtitle != null)
                              DefaultTextStyle.merge(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style.fonts.labelMedium.copyWith(
                                  color: widget.inverted
                                      ? style.colors.onPrimary
                                      : style.colors.onBackground,
                                ),
                                child: Text(widget.subtitle!),
                              ),
                            if (widget.children.isNotEmpty)
                              DefaultTextStyle.merge(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: style.fonts.labelMedium.copyWith(
                                  color: widget.inverted
                                      ? style.colors.onPrimary
                                      : style.colors.onBackground,
                                ),
                                child: Column(children: widget.children),
                              ),
                          ],
                        ),
                      ),
                      ...widget.trailing,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
