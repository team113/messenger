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

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/util/platform_utils.dart';
import 'page/chat/info/view.dart';
import 'page/chat/view.dart';
import 'page/contact/view.dart';
import 'page/my_profile/view.dart';
import 'page/user/view.dart';

/// [Routes.home] page [RouterDelegate] that builds the nested [Navigator].
///
/// [HomeRouterDelegate] doesn't parses any routes. Instead, it only uses the
/// [RouterState] passed to its constructor.
class HomeRouterDelegate extends RouterDelegate<RouteConfiguration>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteConfiguration> {
  HomeRouterDelegate(this._state) {
    _state.addListener(notifyListeners);
  }

  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Router's application state that reflects the navigation.
  final RouterState _state;

  /// [Navigator]'s pages generation based on the [_state].
  List<Page<dynamic>> get _pages {
    /// [_NestedHomeView] is always included.
    List<Page<dynamic>> pages = [const _CustomPage(child: SizedBox.shrink())];

    for (String route in _state.routes) {
      if(route.endsWith('/')) {
        route = route.substring(0, route.length - 1);
      }

      if (route == Routes.me) {
        pages.add(const _CustomPage(
          key: ValueKey('MyProfilePage'),
          name: Routes.me,
          child: MyProfileView(),
        ));
      } else if (route.startsWith('${Routes.chat}/') &&
          route.endsWith(Routes.chatInfo)) {
        String id = route
            .replaceFirst('${Routes.chat}/', '')
            .replaceAll(Routes.chatInfo, '');
        pages.add(_CustomPage(
          key: ValueKey('ChatInfoPage$id'),
          name: '${Routes.chat}/$id${Routes.chatInfo}',
          child: ChatInfoView(ChatId(id)),
        ));
      } else if (route.startsWith('${Routes.chat}/')) {
        String id = route
            .replaceFirst('${Routes.chat}/', '')
            .replaceAll(Routes.chatInfo, '');
        pages.add(_CustomPage(
          key: ValueKey('ChatPage$id'),
          name: '${Routes.chat}/$id',
          child: ChatView(
            ChatId(id),
            itemId: router.arguments?['itemId'] as ChatItemId?,
          ),
        ));
      } else if (route.startsWith('${Routes.contact}/')) {
        final id = route.replaceFirst('${Routes.contact}/', '');
        pages.add(_CustomPage(
          key: ValueKey('ContactPage$id'),
          name: '${Routes.contact}/$id',
          child: ContactView(ChatContactId(id)),
        ));
      } else if (route.startsWith('${Routes.user}/')) {
        final id = route.replaceFirst('${Routes.user}/', '');
        pages.add(_CustomPage(
          key: ValueKey('UserPage$id'),
          name: '${Routes.user}/$id',
          child: UserView(UserId(id)),
        ));
      }
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: _pages,
      onPopPage: (route, result) {
        _state.pop();
        notifyListeners();
        return route.didPop(result);
      },
    );
  }

  @override
  Future<void> setNewRoutePath(RouteConfiguration configuration) async {
    // This is not required for inner router delegate because it doesn't parse
    // routes.
    assert(false, 'unexpected setNewRoutePath() call');
  }
}

/// [Page] with the [_FadeCupertinoPageRoute] as its [Route].
class _CustomPage extends Page {
  const _CustomPage({super.key, super.name, required this.child});

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
