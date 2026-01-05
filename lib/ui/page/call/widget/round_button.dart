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
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';

/// [FloatingActionButton] of some [icon] with an optional
/// [text] and [hint].
class RoundFloatingButton extends StatelessWidget {
  const RoundFloatingButton({
    super.key,
    required this.icon,
    this.offset,
    this.onPressed,
    this.text,
    this.showText = true,
    this.color,
    this.hint,
    this.minified = false,
    this.border,
  });

  /// Callback, called when the button is tapped or activated other way.
  ///
  /// If this is set to `null`, the button is disabled.
  final void Function()? onPressed;

  /// Text under the button.
  final String? text;

  /// Indicator whether the [text] should be showed.
  final bool showText;

  /// Text that will show above the button on a hover.
  final String? hint;

  /// [SvgData] to display.
  final SvgData icon;

  /// [Offset] to apply to the [icon].
  final Offset? offset;

  /// Background color of the button.
  final Color? color;

  /// Indicator whether the [text] provided should be smaller, or small
  /// otherwise.
  final bool minified;

  /// Optional [BoxBorder] of this [RoundFloatingButton].
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final button = _IconButton(
      icon: icon,
      color: color,
      onPressed: onPressed,
      offset: offset,
      border: border,
      hint: hint,
    );

    if (text == null) {
      return button;
    }

    return _LabeledButton(
      showText: showText,
      text: text!,
      minified: minified,
      child: button,
    );
  }
}

/// [FloatingActionButton] of some [icon].
class _ButtonCircle extends StatelessWidget {
  const _ButtonCircle({
    required this.color,
    required this.onPressed,
    required this.icon,
    this.offset,
  });

  /// Callback, called when the button is tapped or activated other way.
  ///
  /// If this is set to `null`, the button is disabled.
  final void Function()? onPressed;

  /// Background color of the button.
  final Color? color;

  /// [Offset] to apply to the [icon] or [asset].
  final Offset? offset;

  /// [SvgData] to display instead of [asset].
  final SvgData icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 60, maxHeight: 60),

      child: Material(
        elevation: 0,
        color: color,
        type: MaterialType.circle,
        child: InkWell(
          borderRadius: BorderRadius.circular(300),
          onTap: onPressed,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: SizedBox(
                  width: (constraints.maxWidth / 60) * (icon.width ?? 60),
                  height: (constraints.maxHeight / 60) * (icon.height ?? 60),
                  child: Transform.translate(
                    offset: offset ?? Offset.zero,
                    child: SvgIcon(icon),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// [_ButtonCircle] with optional [border] and [hint].
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    this.color,
    this.onPressed,
    this.offset,
    this.border,
    this.hint,
  });

  /// Callback, called when the button is tapped or activated other way.
  ///
  /// If this is set to `null`, the button is disabled.
  final void Function()? onPressed;

  /// [SvgData] to display instead of [asset].
  final SvgData icon;

  /// Text that will show above the button on a hover.
  final String? hint;

  /// [Offset] to apply to the [icon] or [asset].
  final Offset? offset;

  /// Background color of the button.
  final Color? color;

  /// Optional [BoxBorder] of this [RoundFloatingButton].
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    Widget button = _ButtonCircle(
      color: color,
      onPressed: onPressed,
      offset: offset,
      icon: icon,
    );

    if (border != null) {
      button = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(shape: BoxShape.circle, border: border),
        child: button,
      );
    }

    if (hint == null || PlatformUtils.isMobile) {
      return button;
    }

    return _TooltipButton(hint: hint!, child: button);
  }
}

/// [_ButtonCircle] with tooltip.
class _TooltipButton extends StatefulWidget {
  const _TooltipButton({required this.hint, required this.child});

  /// Text that will show above the button on a hover.
  final String hint;

  /// Button content
  final Widget child;

  @override
  State<_TooltipButton> createState() => _TooltipButtonState();
}

/// State of [_TooltipButton] used to keep the [_entry] and [_link].
class _TooltipButtonState extends State<_TooltipButton> {
  /// Link to the tooltip.
  final LayerLink _link = LayerLink();

  /// Tooltip entry.
  OverlayEntry? _entry;

  @override
  void dispose() {
    _hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _hide(),
        child: widget.child,
      ),
    );
  }

  /// Shows the tooltip.
  void _show() {
    if (_entry != null) return;

    final style = Theme.of(context).style;

    _entry = OverlayEntry(
      builder: (context) => IgnorePointer(
        child: CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.topCenter,
          followerAnchor: Alignment.topCenter,
          offset: Offset(0, -36),
          showWhenUnlinked: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(),
            child: Text(
              widget.hint,
              textAlign: TextAlign.center,
              style: style.fonts.small.regular.onPrimary.copyWith(
                shadows: [
                  Shadow(blurRadius: 6, color: style.colors.onBackground),
                  Shadow(blurRadius: 6, color: style.colors.onBackground),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  /// Hides the tooltip.
  void _hide() {
    _entry?.remove();
    _entry = null;
  }
}

/// [_IconButton] with label below it.
class _LabeledButton extends StatelessWidget {
  const _LabeledButton({
    this.showText = false,
    this.minified = false,
    required this.text,
    required this.child,
  });

  /// Text under the button.
  final String text;

  /// Indicator whether the [text] should be showed.
  final bool showText;

  /// Indicator whether the [text] provided should be smaller, or small
  /// otherwise.
  final bool minified;

  /// Circle [Icon] part of [RoundFloatingButton].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 5),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: showText ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: minified
                  ? style.fonts.smaller.regular.onPrimary
                  : style.fonts.small.regular.onPrimary,
              maxLines: 2,
            ),
          ),
        ),
      ],
    );
  }
}
