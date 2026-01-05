// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:sentry_flutter/sentry_flutter.dart';

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/contact.dart';
import '/domain/model/user.dart';
import '/routes.dart';
import '/ui/page/chat_direct_link/view.dart';
import '/ui/page/erase/view.dart';
import '/ui/widget/custom_page.dart';
import 'page/affiliate/view.dart';
import 'page/chat/info/view.dart';
import 'page/chat/view.dart';
import 'page/contact/view.dart';
import 'page/deposit/view.dart';
import 'page/my_profile/view.dart';
import 'page/partner_transactions/view.dart';
import 'page/prices/view.dart';
import 'page/promotion/view.dart';
import 'page/statistics/view.dart';
import 'page/user/view.dart';
import 'page/wallet_transactions/view.dart';
import 'page/withdraw/view.dart';

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
        pages.add(
          const CustomPage(
            key: ValueKey('MyProfilePage'),
            name: Routes.me,
            child: MyProfileView(),
          ),
        );
      } else if (route.startsWith('${Routes.chats}/') &&
          route.endsWith(Routes.chatInfo)) {
        String id = route
            .replaceFirst('${Routes.chats}/', '')
            .replaceAll(Routes.chatInfo, '');
        pages.add(
          CustomPage(
            key: ValueKey('ChatInfoPage$id'),
            name: '${Routes.chats}/$id${Routes.chatInfo}',
            child: ChatInfoView(ChatId(id)),
          ),
        );
      } else if (route.startsWith('${Routes.chats}/')) {
        String id = route
            .replaceFirst('${Routes.chats}/', '')
            .replaceAll(Routes.chatInfo, '');
        pages.add(
          CustomPage(
            key: ValueKey('ChatPage$id'),
            name: '${Routes.chats}/$id',
            child: ChatView(
              ChatId(id),
              itemId: router.arguments?['itemId'] as ChatItemId?,
            ),
          ),
        );
      } else if (route.startsWith('${Routes.contacts}/')) {
        final id = route.replaceFirst('${Routes.contacts}/', '');
        pages.add(
          CustomPage(
            key: ValueKey('ContactPage$id'),
            name: '${Routes.contacts}/$id',
            child: ContactView(ChatContactId(id)),
          ),
        );
      } else if (route.startsWith('${Routes.user}/')) {
        final id = route.replaceFirst('${Routes.user}/', '');
        pages.add(
          CustomPage(
            key: ValueKey('UserPage$id'),
            name: '${Routes.user}/$id',
            child: UserView(UserId(id)),
          ),
        );
      } else if (route.startsWith(Routes.erase)) {
        pages.add(
          const CustomPage(
            key: ValueKey('ErasePage'),
            name: Routes.erase,
            child: EraseView(),
          ),
        );
      } else if (route.startsWith(Routes.chatDirectLink)) {
        final String slug = _state.route.replaceFirst(
          Routes.chatDirectLink,
          '',
        );
        pages.add(
          CustomPage(
            key: ValueKey('ChatDirectLinkPage$slug'),
            name: '${Routes.chatDirectLink}$slug',
            child: ChatDirectLinkView(slug),
          ),
        );
      } else if (route.startsWith(Routes.affiliate)) {
        pages.add(
          const CustomPage(
            key: ValueKey('AffiliatePage'),
            name: Routes.affiliate,
            child: AffiliateView(),
          ),
        );
      } else if (route.startsWith(Routes.partnerTransactions)) {
        pages.add(
          const CustomPage(
            key: ValueKey('PartnerTransactionsPage'),
            name: Routes.partnerTransactions,
            child: PartnerTransactionsView(),
          ),
        );
      } else if (route.startsWith(Routes.prices)) {
        pages.add(
          const CustomPage(
            key: ValueKey('PricesPage'),
            name: Routes.prices,
            child: PricesView(),
          ),
        );
      } else if (route.startsWith(Routes.promotion)) {
        pages.add(
          const CustomPage(
            key: ValueKey('PromotionPage'),
            name: Routes.promotion,
            child: PromotionView(),
          ),
        );
      } else if (route.startsWith(Routes.statistics)) {
        pages.add(
          const CustomPage(
            key: ValueKey('StatisticsPage'),
            name: Routes.statistics,
            child: StatisticsView(),
          ),
        );
      } else if (route.startsWith(Routes.withdraw)) {
        pages.add(
          const CustomPage(
            key: ValueKey('WithdrawPage'),
            name: Routes.withdraw,
            child: WithdrawView(),
          ),
        );
      } else if (route.startsWith(Routes.deposit)) {
        pages.add(
          const CustomPage(
            key: ValueKey('DepositPage'),
            name: Routes.deposit,
            child: DepositView(),
          ),
        );
      } else if (route.startsWith(Routes.walletTransactions)) {
        pages.add(
          const CustomPage(
            key: ValueKey('WalletTransactionsPage'),
            name: Routes.walletTransactions,
            child: WalletTransactionsView(),
          ),
        );
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
      onDidRemovePage: (page) => _state.pop(page.name),
    );
  }

  @override
  Future<void> setNewRoutePath(RouteConfiguration configuration) async {
    // This is not required for inner router delegate because it doesn't parse
    // routes.
    assert(false, 'unexpected setNewRoutePath() call');
  }
}
