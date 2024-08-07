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
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/routes.dart';
import '/ui/widget/custom_page.dart';
import 'page/vacancy/view.dart';

/// [Routes.work] page [RouterDelegate] that builds the nested [Navigator].
///
/// [WorkRouterDelegate] doesn't parses any routes. Instead, it only uses the
/// [RouterState] passed to its constructor.
class WorkRouterDelegate extends RouterDelegate<RouteConfiguration>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<RouteConfiguration> {
  WorkRouterDelegate(this._state) {
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

      if (route.startsWith('${Routes.work}/')) {
        final String? last = route.split('/').lastOrNull;
        final WorkTab? work =
            WorkTab.values.firstWhereOrNull((e) => e.name == last);

        if (work != null) {
          pages.add(CustomPage(
            key: ValueKey('${work.name.capitalizeFirst}WorkPage'),
            name: Routes.me,
            child: VacancyWorkView(work),
          ));
        }
      }
    }

    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      observers: [SentryNavigatorObserver(), ModalNavigatorObserver()],
      pages: _pages,
      onDidRemovePage: (Page<Object?> page) {
        _state.pop();
        notifyListeners();
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
