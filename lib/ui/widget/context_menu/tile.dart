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
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'menu.dart';

/// [ContextMenuItem] building the [builder].
class ContextMenuBuilder extends StatelessWidget with ContextMenuItem {
  const ContextMenuBuilder(this.builder, {super.key});

  /// Builder, building a [Widget].
  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

/// [ContextMenuItem] representing a styled tile used in [ContextMenu].
class ContextMenuTile extends StatefulWidget with ContextMenuItem {
  const ContextMenuTile({
    super.key,
    required this.label,
    this.onPressed,
    this.asset = SvgIcons.videoMessage,
    this.pinned,
    this.trailing,
  });

  /// Label of this [ContextMenuTile].
  final String label;

  /// [SvgData] of an asset to display in [trailing].
  final SvgData asset;

  /// Callback, called when tile is pressed.
  final void Function(BuildContext context)? onPressed;

  /// Indicator whether the [ContextMenuTile] is considered pinned, meaning
  /// displaying an appropriate icon.
  ///
  /// If `null`, then no icon associated with pinning is displayed.
  final bool? pinned;

  /// Optional trailing [Widget].
  final Widget? trailing;

  @override
  State<ContextMenuTile> createState() => _ContextMenuTileState();
}

/// State of the [ContextMenuTile] used to implement hover effect.
class _ContextMenuTileState extends State<ContextMenuTile> {
  /// Indicator whether [ContextMenuTile] is hovered.
  bool _hovered = false;

  /// [GlobalKey] of the [AnimatedScale] to discard rebuilds.
  final GlobalKey _globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Widget suffix = SizedBox(
      width: 26,
      child: AnimatedScale(
        key: _globalKey,
        duration: const Duration(milliseconds: 100),
        scale: _hovered ? 1.05 : 1,
        child: widget.trailing ?? SvgIcon(widget.asset),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      opaque: false,
      child: WidgetButton(
        onPressed: widget.onPressed == null
            ? null
            : () => widget.onPressed?.call(context),
        child: Container(
          width: double.infinity,
          color: _hovered ? style.colors.onBackgroundOpacity2 : null,
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 16),
              suffix,
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(fontSize: 17, color: style.colors.primary),
              ),
              const Spacer(),
              const SizedBox(width: 16),
              if (widget.pinned != null)
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Center(
                    child: SafeAnimatedSwitcher(
                      duration: const Duration(milliseconds: 100),
                      child: widget.pinned!
                          ? const SvgIcon(SvgIcons.unpin, key: Key('Unpin'))
                          : Transform.translate(
                              offset: const Offset(0.5, 0),
                              child: const SvgIcon(
                                SvgIcons.pin,
                                key: Key('Pin'),
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
