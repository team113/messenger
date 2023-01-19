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

/// The `AnimatedSizeAndFade` widget does a fade and size transition between a.
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
