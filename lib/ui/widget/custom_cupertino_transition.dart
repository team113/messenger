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

/// Custom [CupertinoPageTransitionsBuilder] to define a horizontal
/// [MaterialPageRoute] page transition animation.
class CustomCupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomCupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _CustomCupertinoPageTransitionsBuilder(
      primaryAnimation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

/// Custom iOS-style page transition.
class _CustomCupertinoPageTransitionsBuilder extends StatelessWidget {
  _CustomCupertinoPageTransitionsBuilder({
    required Animation<double> primaryAnimation,
    required Animation<double> secondaryAnimation,
    required this.child,
  })  : _primaryAnimation = CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.linearToEaseOut,
          reverseCurve: Curves.linearToEaseOut.flipped,
        ).drive(_rightTween),
        _secondaryAnimation = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.linearToEaseOut,
          reverseCurve: Curves.easeInToLinear,
        ).drive(_leftTween);

  /// [Widget] to show.
  final Widget child;

  /// Animation for next page.
  final Animation<Offset> _primaryAnimation;

  /// Animation for previous page.
  final Animation<Offset> _secondaryAnimation;

  /// Animatable [Offset] for [_primaryAnimation].
  static final Animatable<Offset> _rightTween = Tween<Offset>(
    begin: const Offset(1.0, 0.0),
    end: Offset.zero,
  );

  /// Animatable [Offset] for [_secondaryAnimation].
  static final Animatable<Offset> _leftTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(-1.0, 0.0),
  );

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _secondaryAnimation,
      child: SlideTransition(
        position: _primaryAnimation,
        child: child,
      ),
    );
  }
}
