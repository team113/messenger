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

  @override
  State<RoundFloatingButton> createState() => _RoundFloatingButtonState();
}

/// State of [RoundFloatingButton] used to keep the [showHint].
class _RoundFloatingButtonState extends State<RoundFloatingButton> {
  /// Indicator whether a hint should be displayed or not.
  ///
  /// Toggles on [InkWell] hover.
  bool showHint = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ConditionalBackdropFilter(
              condition: !WebUtils.isSafari && widget.withBlur,
              borderRadius: BorderRadius.circular(30),
              child: Material(
                elevation: 0,
                color: widget.color,
                type: MaterialType.circle,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onHover: (b) => Future.delayed(
                    Duration.zero,
                    () => mounted ? setState(() => showHint = b) : null,
                  ),
                  onTap: widget.onPressed,
                  child: SizedBox(
                    width: 60 * widget.scale,
                    height: 60 * widget.scale,
                    child: Stack(
                      alignment: AlignmentDirectional.center,
                      children: widget.children,
                    ),
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
        ),
        if (widget.hint != null && showHint)
          SizedBox(
            width: 60 * widget.scale,
            height: 60 * widget.scale,
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -47),
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
          ),
      ],
    );
  }
}
