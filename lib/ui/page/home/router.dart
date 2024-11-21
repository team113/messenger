// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/ui/page/chat_direct_link/view.dart';
import '/ui/page/erase/view.dart';
import '/ui/page/support/view.dart';
import '/ui/page/work/page/vacancy/view.dart';
import '/ui/widget/custom_page.dart';
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
    List<Page<dynamic>> pages = [const CustomPage(child: SizedBox.shrink())];

    for (String route in _state.routes) {
      if (route.endsWith('/')) {
        route = route.substring(0, route.length - 1);
      }

      if (route == Routes.me) {
        pages.add(const CustomPage(
          key: ValueKey('MyProfilePage'),
          name: Routes.me,
          child: MyProfileView(),
        ));
      } else if (route.startsWith('${Routes.chats}/') &&
          route.endsWith(Routes.chatInfo)) {
        String id = route
            .replaceFirst('${Routes.chats}/', '')
            .replaceAll(Routes.chatInfo, '');
        pages.add(CustomPage(
          key: ValueKey('ChatInfoPage$id'),
          name: '${Routes.chats}/$id${Routes.chatInfo}',
          child: ChatInfoView(ChatId(id)),
        ));
      } else if (route.startsWith('${Routes.chats}/')) {
        String id = route
            .replaceFirst('${Routes.chats}/', '')
            .replaceAll(Routes.chatInfo, '');
        pages.add(CustomPage(
          key: ValueKey('ChatPage$id'),
          name: '${Routes.chats}/$id',
          child: ChatView(
            ChatId(id),
            itemId: router.arguments?['itemId'] as ChatItemId?,
            welcome: router.arguments?['welcome'] as ChatMessageText?,
          ),
        ));
      } else if (route.startsWith('${Routes.contacts}/')) {
        final id = route.replaceFirst('${Routes.contacts}/', '');
        pages.add(CustomPage(
          key: ValueKey('ContactPage$id'),
          name: '${Routes.contacts}/$id',
          child: ContactView(ChatContactId(id)),
        ));
      } else if (route.startsWith('${Routes.user}/')) {
        final id = route.replaceFirst('${Routes.user}/', '');
        pages.add(CustomPage(
          key: ValueKey('UserPage$id'),
          name: '${Routes.user}/$id',
          child: UserView(UserId(id)),
        ));
      } else if (route.startsWith('${Routes.work}/')) {
        final String? last = route.split('/').lastOrNull;
        final WorkTab? work =
            WorkTab.values.firstWhereOrNull((e) => e.name == last);

        if (work != null) {
          pages.add(CustomPage(
            key: ValueKey('${work.name}WorkPage'),
            name: Routes.me,
            child: VacancyWorkView(work),
          ));
        }
      } else if (route.startsWith(Routes.erase)) {
        pages.add(const CustomPage(
          key: ValueKey('ErasePage'),
          name: Routes.erase,
          child: EraseView(),
        ));
      } else if (route.startsWith(Routes.support)) {
        pages.add(const CustomPage(
          key: ValueKey('SupportPage'),
          name: Routes.support,
          child: SupportView(),
        ));
      } else if (route.startsWith('${Routes.chatDirectLink}/')) {
        final String slug =
            _state.route.replaceFirst('${Routes.chatDirectLink}/', '');
        pages.add(CustomPage(
          key: ValueKey('ChatDirectLinkPage$slug'),
          name: Routes.chatDirectLink,
          child: ChatDirectLinkView(slug),
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
      observers: [SentryNavigatorObserver(), ModalNavigatorObserver()],
      onDidRemovePage: (page) {
        print('===== [home] onDidRemovePage -> $page');
        _state.pop(page.name);
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
