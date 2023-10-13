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

import '/util/platform_utils.dart';

/// [Page] with the [_FadeCupertinoPageRoute] as its [Route].
class CustomPage extends Page {
  const CustomPage({super.key, super.name, required this.child});

  /// [Widget] page.
  final Widget child;

  @override
  Route createRoute(BuildContext context) {
    return _FadeCupertinoPageRoute(
      settings: this,
      pageBuilder: (_, __, ___) => child,
    );
  }
}

/// [PageRoute] with fading iOS styled page transition animation.
///
/// Uses a [FadeUpwardsPageTransitionsBuilder] on Android.
class _FadeCupertinoPageRoute<T> extends PageRoute<T> {
  _FadeCupertinoPageRoute({super.settings, required this.pageBuilder})
      : matchingBuilder = PlatformUtils.isAndroid
            ? const FadeUpwardsPageTransitionsBuilder()
            : const CupertinoPageTransitionsBuilder();

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
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      pageBuilder(context, animation, secondaryAnimation);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return ClipRect(
      child: FadeTransition(
        opacity: animation,
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(secondaryAnimation),
          child: matchingBuilder.buildTransitions(
            this,
            context,
            animation,
            secondaryAnimation,
            child,
          ),
        ),
      ),
    );
  }
}
