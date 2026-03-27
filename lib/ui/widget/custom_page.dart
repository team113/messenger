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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '/themes.dart';
import '/util/platform_utils.dart';

/// [Page] with the [_CupertinoPageRoute] as its [Route].
class CustomPage extends Page {
  const CustomPage({super.key, super.name, required this.child});

  /// [Widget] page.
  final Widget child;

  @override
  Route createRoute(BuildContext context) {
    return _CupertinoPageRoute(
      settings: this,
      pageBuilder: (_, _, _) => child,
      instant: !context.isNarrow,
    );
  }
}

/// [PageRoute] custom iOS styled page transition animation.
///
/// Uses a [FadeUpwardsPageTransitionsBuilder] on Android.
class _CupertinoPageRoute<T> extends PageRoute<T> {
  _CupertinoPageRoute({
    super.settings,
    required this.pageBuilder,
    bool instant = false,
  }) : transitionDuration = instant
           ? Duration.zero
           : const Duration(milliseconds: 400),
       matchingBuilder = PlatformUtils.isAndroid
           ? const FadeUpwardsPageTransitionsBuilder()
           : const CustomCupertinoPageTransitionsBuilder();

  /// [PageTransitionsBuilder] transition animation.
  final PageTransitionsBuilder matchingBuilder;

  /// Builder building the [Page] itself.
  final RoutePageBuilder pageBuilder;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  final Duration transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => pageBuilder(context, animation, secondaryAnimation);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final style = Theme.of(context).style;

    return ColoredBox(
      color: style.colors.transparent,
      child: matchingBuilder.buildTransitions(
        this,
        context,
        animation,
        secondaryAnimation,
        child,
      ),
    );
  }
}

/// [PageTransitionsBuilder] using [CupertinoRouteTransitionMixin] for custom
/// [MaterialPageRoute]s changing animation.
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
    final Widget widget = CupertinoRouteTransitionMixin.buildPageTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );

    if (widget is CupertinoPageTransition) {
      return SlideTransition(
        position: Tween(begin: Offset.zero, end: const Offset(-1.0, 0.0))
            .animate(
              route.popGestureInProgress
                  ? animation
                  : CurvedAnimation(
                      parent: animation,
                      curve: Curves.linearToEaseOut,
                      reverseCurve: Curves.linearToEaseOut.flipped,
                    ),
            ),
        child: SlideTransition(
          position: Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
              .animate(
                route.popGestureInProgress
                    ? secondaryAnimation
                    : CurvedAnimation(
                        parent: secondaryAnimation,
                        curve: Curves.linearToEaseOut,
                        reverseCurve: Curves.easeInToLinear,
                      ),
              ),
          child: widget.child,
        ),
      );
    } else {
      return widget;
    }
  }
}
