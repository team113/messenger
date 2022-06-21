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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'conditional_backdrop.dart';
import '/util/web/web_utils.dart';

/// [FloatingActionButton] of [children] content with an optional [text] and
/// [hint].
class RoundFloatingButton extends StatefulWidget {
  const RoundFloatingButton({
    Key? key,
    this.onPressed,
    this.text,
    this.children = const [],
    this.color = const Color(0x7F818181),
    this.hint,
    this.scale = 1,
    this.withBlur = false,
    this.withText = true,
  }) : super(key: key);

  /// Callback, called when the button is tapped or activated other way.
  ///
  /// If this is set to `null`, the button is disabled.
  final void Function()? onPressed;

  /// Text under the button.
  final String? text;

  /// Text that will show above the button on a hover.
  final String? hint;

  /// Widgets to draw inside the button.
  final List<Widget> children;

  /// Controls the scale of the button.
  final double scale;

  /// Background color of the button.
  final Color? color;

  /// Indicator whether the button should have a blur under it or not.
  final bool withBlur;

  /// Indicator whether the button should be displayed with text or not.
  final bool withText;

  @override
  State<RoundFloatingButton> createState() => _RoundFloatingButtonState();
}

/// State of [RoundFloatingButton] used to keep the [showHint].
class _RoundFloatingButtonState extends State<RoundFloatingButton> {
  /// Indicator whether a hint should be displayed or not.
  ///
  /// Toggles on [InkWell] hover.
  bool showHint = false;

  final GlobalKey _key = GlobalKey();

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
  Widget build(BuildContext context) {
    return (!widget.withText)
        ? ConditionalBackdropFilter(
            condition: !WebUtils.isSafari && widget.withBlur,
            borderRadius: BorderRadius.circular(30),
            child: Material(
              key: _key,
              elevation: 0,
              color: widget.color,
              type: MaterialType.circle,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
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
                child: widget.children.first,
              ),
            ),
          )
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ConditionalBackdropFilter(
                condition: !WebUtils.isSafari && widget.withBlur,
                borderRadius: BorderRadius.circular(30),
                child: Material(
                  key: _key,
                  elevation: 0,
                  color: widget.color,
                  type: MaterialType.circle,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
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
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: widget.children,
                    ),
                  ),
                ),
              ),
              if (widget.text != null) const SizedBox(height: 5),
              if (widget.text != null)
                Text(
                  widget.text!,
                  textAlign: TextAlign.center,
                  style: context.textTheme.caption?.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  maxLines: 2,
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
                child: UnconstrainedBox(
                  child: Text(
                    widget.hint!,
                    textAlign: TextAlign.center,
                    style: context.theme.outlinedButtonTheme.style!.textStyle!
                        .resolve({MaterialState.disabled})!.copyWith(
                      fontSize: 13,
                      color: Colors.white,
                      shadows: const [
                        Shadow(blurRadius: 6, color: Color(0xFF000000)),
                        Shadow(blurRadius: 6, color: Color(0xFF000000)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });

    Overlay.of(context, rootOverlay: true)!.insert(_hintEntry!);
  }
}
