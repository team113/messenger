// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/widget/allow_overflow.dart';
import '/ui/widget/svg/svg.dart';
import '/util/web/web_utils.dart';
import 'conditional_backdrop.dart';

/// [FloatingActionButton] of some [asset] or [child] content with an optional
/// [text] and [hint].
class RoundFloatingButton extends StatefulWidget {
  const RoundFloatingButton({
    super.key,
    this.icon,
    this.offset,
    this.asset,
    this.assetWidth = 60,
    this.onPressed,
    this.text,
    this.showText = true,
    this.color,
    this.hint,
    this.withBlur = false,
    this.minified = false,
    this.border,
    this.child,
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

  /// [SvgData] to display instead of [asset].
  final SvgData? icon;

  /// [Offset] to apply to the [icon] or [asset].
  final Offset? offset;

  /// Name of the asset to place into the [SvgImage.asset].
  final String? asset;

  /// Width of the [asset].
  final double assetWidth;

  /// Optional [Widget] to replace the default [SvgImage.asset].
  final Widget? child;

  /// Background color of the button.
  final Color? color;

  /// Indicator whether the button should have a blur under it or not.
  final bool withBlur;

  /// Indicator whether the [text] provided should be smaller, or small
  /// otherwise.
  final bool minified;

  /// Optional [BoxBorder] of this [RoundFloatingButton].
  final BoxBorder? border;

  @override
  State<RoundFloatingButton> createState() => _RoundFloatingButtonState();
}

/// State of [RoundFloatingButton] used to keep the [_hintEntry].
class _RoundFloatingButtonState extends State<RoundFloatingButton> {
  /// [GlobalKey] of this [RoundFloatingButton] to place its [_hintEntry]
  /// correctly.
  final GlobalKey _key = GlobalKey();

  /// [OverlayEntry] of the hint of this [RoundFloatingButton].
  OverlayEntry? _hintEntry;

  @override
  void didUpdateWidget(covariant RoundFloatingButton oldWidget) {
    if (widget.hint != oldWidget.hint || widget.hint == null) {
      _hintEntry?.remove();
      _hintEntry = null;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _hintEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    Widget? child = widget.child;

    if (child == null) {
      if (widget.icon == null) {
        child = Center(
          child: SizedBox(
            width: min(widget.assetWidth, 60),
            height: min(widget.assetWidth, 60),
            child: SvgImage.asset(
              'assets/icons/${widget.asset}.svg',
              width: widget.assetWidth,
            ),
          ),
        );
      } else {
        child = LayoutBuilder(builder: (context, constraints) {
          return Center(
            child: SizedBox(
              width: (constraints.maxWidth / 60) * (widget.icon?.width ?? 60),
              height:
                  (constraints.maxHeight / 60) * (widget.icon?.height ?? 60),
              child: Transform.translate(
                offset: widget.offset ?? Offset.zero,
                child: SvgIcon(widget.icon!),
              ),
            ),
          );
        });
      }
    }

    Widget button = Container(
      constraints: const BoxConstraints(maxWidth: 60, maxHeight: 60),
      // Use [Palette.almostTransparent] instead of [Palette.transparent] to
      // allow [ConditionalBackdropFilter] animate transparency correctly.
      color: style.colors.almostTransparent,
      child: ConditionalBackdropFilter(
        condition: !WebUtils.isSafari && widget.withBlur,
        borderRadius: BorderRadius.circular(300),
        child: Material(
          key: _key,
          elevation: 0,
          color: widget.color,
          type: MaterialType.circle,
          child: InkWell(
            borderRadius: BorderRadius.circular(300),
            onHover: widget.hint != null
                ? (b) {
                    if (b) {
                      _populateOverlay();
                    } else {
                      _hintEntry?.remove();
                      _hintEntry = null;
                    }
                  }
                : null,
            onTap: widget.onPressed,
            child: child,
          ),
        ),
      ),
    );

    if (widget.border != null) {
      button = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration:
            BoxDecoration(border: widget.border, shape: BoxShape.circle),
        child: button,
      );
    }

    final List<Shadow> shadows = [
      Shadow(blurRadius: 6, color: style.colors.onBackground),
      Shadow(blurRadius: 6, color: style.colors.onBackground),
    ];

    return widget.text == null
        ? button
        : Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              button,
              const SizedBox(height: 5),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: widget.showText ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    widget.text!,
                    textAlign: TextAlign.center,
                    style: widget.minified
                        ? style.fonts.smaller.regular.onPrimary
                        : style.fonts.small.regular.onPrimary.copyWith(
                            shadows: widget.withBlur ? shadows : null,
                          ),
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          );
  }

  /// Populates the [_hintEntry].
  void _populateOverlay() {
    if (!mounted || _hintEntry != null) return;

    Offset offset = Offset.zero;
    Size size = Size.zero;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      offset = box.localToGlobal(Offset.zero);
      size = box.size;
    }

    // Discard the first [LayoutBuilder] frame since no widget is drawn yet.
    bool firstLayout = true;

    // Add a rebuild to take possible animations into the account.
    Future.delayed(300.milliseconds, _hintEntry?.markNeedsBuild);

    _hintEntry = OverlayEntry(builder: (ctx) {
      if (!firstLayout) {
        final box = _key.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          offset = box.localToGlobal(Offset.zero);
          size = box.size;
        }
      } else {
        firstLayout = false;
      }

      final style = Theme.of(context).style;

      return IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: offset.dx,
              top: offset.dy,
              width: size.width,
              height: size.height,
              child: Transform.translate(
                offset: Offset(0, -size.height - 2),
                child: AllowOverflow(
                  child: UnconstrainedBox(
                    child: Text(
                      widget.hint!,
                      textAlign: TextAlign.center,
                      style: style.fonts.small.regular.onPrimary.copyWith(
                        shadows: [
                          Shadow(
                            blurRadius: 6,
                            color: style.colors.onBackground,
                          ),
                          Shadow(
                            blurRadius: 6,
                            color: style.colors.onBackground,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    Overlay.of(context, rootOverlay: true).insert(_hintEntry!);
  }
}
