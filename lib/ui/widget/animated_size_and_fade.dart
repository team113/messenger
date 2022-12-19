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

/// The `AnimatedSizeAndFade` widget does a fade and size transition between a
/// "new" widget and an "old" widget/ previously set as a child. The "old" and
/// the "new" children must have the same width, but can have different heights,
/// and you **don't need to know** their sizes in advance. You can also define a
/// duration and curve for both the fade and the size, separately.
///
/// **Important:** If the "new" child is the same widget type as the "old"
/// child, but with different parameters, then [AnimatedSizeAndFade] will
/// **NOT** do a transition between them, since as far as the framework is
/// concerned, they are the same widget, and the existing widget can be updated
/// with the new parameters. To force the transition to occur, set a [Key]
/// (typically a [ValueKey] taking any widget data that would change the visual
/// appearance of the widget) on each child widget that you wish to be
/// considered unique.
///
/// Example:
/// ```
///  bool toggle=true;
///  Widget widget1 = ...;
///  Widget widget2 = ...;
///  AnimatedSizeAndFade(
///     child: toggle ? widget1 : widget2
///  );
/// ```
///
/// ### Show and Hide
///
/// The `AnimatedSizeAndFade.showHide` constructor may be used
/// to show/hide a widget, by resizing it vertically while fading.
///
/// Example:
/// ```
///  bool toggle=true;
///  Widget widget = ...;
///  AnimatedSizeAndFade.showHide(
///     show: toggle,
///     child: widget,
///  );
///
/// ## How does AnimatedSizeAndFade compare to other similar widgets?
///
/// - With AnimatedCrossFade you must keep both the firstChild and secondChild,
/// which is not necessary with AnimatedSizeAndFade.
///
/// - With AnimatedSwitcher you may simply change its child, but then it only
/// animates the fade, not the size.
///
/// - AnimatedContainer also doesn't work unless you know the size of the
/// children in advance.
class AnimatedSizeAndFade extends StatelessWidget {
  const AnimatedSizeAndFade({
    Key? key,
    this.child,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.sizeDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeInOut,
    this.fadeOutCurve = Curves.easeInOut,
    this.sizeCurve = Curves.easeInOut,
    this.alignment = Alignment.center,
  })  : show = true,
        super(key: key);

  /// Use this constructor when you want to show/hide the child, by doing a
  /// vertical size/fade. To that end, instead of changing the child,
  /// simply change [show]. Note this widget will try to have its width as
  /// big as possible, so put it in a parent with limited width constraints.
  const AnimatedSizeAndFade.showHide({
    Key? key,
    this.child,
    required this.show,
    this.fadeDuration = const Duration(milliseconds: 500),
    this.sizeDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeInOut,
    this.fadeOutCurve = Curves.easeInOut,
    this.sizeCurve = Curves.easeInOut,
    this.alignment = Alignment.center,
  }) : super(key: key);

  /// [UniqueKey] used by this [AnimatedSizeAndFade].
  static final _key = UniqueKey();

  /// [Widget] to animate.
  final Widget? child;

  /// [Duration] of the fade animation.
  final Duration fadeDuration;

  /// [Duration] of the size animation.
  final Duration sizeDuration;

  /// [Curve] of the fade in animation.
  final Curve fadeInCurve;

  /// [Curve] of the fade out animation.
  final Curve fadeOutCurve;

  /// [Curve] of the size animation.
  final Curve sizeCurve;

  /// [Alignment] of the [child].
  final Alignment alignment;

  /// Indicator whether [child] should be showed.
  final bool show;

  @override
  Widget build(BuildContext context) {
    var animatedSize = AnimatedSize(
      duration: sizeDuration,
      curve: sizeCurve,
      child: AnimatedSwitcher(
        duration: fadeDuration,
        switchInCurve: fadeInCurve,
        switchOutCurve: fadeOutCurve,
        layoutBuilder: _layoutBuilder,
        child: show
            ? child
            : SizedBox(
                key: AnimatedSizeAndFade._key,
                width: double.infinity,
                height: 0,
              ),
      ),
    );

    return ClipRect(child: animatedSize);
  }

  /// Layout builder of the [AnimatedSwitcher].
  Widget _layoutBuilder(Widget? currentChild, List<Widget> previousChildren) {
    List<Widget> children = previousChildren;

    if (currentChild != null) {
      if (previousChildren.isEmpty) {
        children = [currentChild];
      } else {
        children = [
          Positioned(
            left: 0.0,
            right: 0.0,
            child: Container(child: previousChildren[0]),
          ),
          currentChild,
        ];
      }
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: alignment,
      children: children,
    );
  }
}
