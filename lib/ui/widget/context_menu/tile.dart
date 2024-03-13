import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import 'menu.dart';

/// [ContextMenuItem] building the [builder].
class ContextMenuBuilder extends StatelessWidget with ContextMenuItem {
  const ContextMenuBuilder(this.builder, {super.key});

  /// Builder, building a [Widget].
  final Widget Function(BuildContext) builder;

  @override
  Widget build(BuildContext context) => builder(context);
}

/// [ContextMenuItem] representing a styled button used in [ContextMenu].
class ContextMenuTile extends StatefulWidget with ContextMenuItem {
  const ContextMenuTile({
    super.key,
    required this.label,
    this.onPressed,
    this.onPinned,
    this.offset = Offset.zero,
    this.asset = SvgIcons.videoMessage,
    this.icon,
    this.pinnable = true,
    this.pinned = false,
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

  final void Function()? onPinned;

  final Offset offset;
  final Widget? icon;
  final bool pinnable;

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
        child: widget.trailing ??
            Transform.translate(
              offset: widget.offset,
              child: SvgIcon(widget.asset),
            ),
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
              if (widget.pinnable)
                WidgetButton(
                  onPressed: widget.onPinned ?? () {},
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: Center(
                      child: AnimatedButton(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 100),
                          child: widget.pinned ?? false
                              ? const SvgIcon(SvgIcons.unpin, key: Key('Unpin'))
                              : Transform.translate(
                                  offset: const Offset(0.5, 0),
                                  child: SvgIcon(
                                    widget.onPinned != null
                                        ? SvgIcons.pin
                                        : SvgIcons.pinDisabled,
                                    key: const Key('Pin'),
                                  ),
                                ),
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
