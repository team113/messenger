// Copyright © 2025 Ideas Networks Solutions S.A.,
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
import 'package:get/get.dart';

import '../../../../../domain/model/deposit.dart';
import '../../../../../routes.dart';
import '../../../../../util/platform_utils.dart';
import '../../../../widget/line_divider.dart';
import '../../../../widget/menu_button.dart';
import '../../../../widget/svg/svg.dart';
import '../../../../widget/widget_button.dart';
import '../chats/widget/unread_counter.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import 'controller.dart';
import 'widget/deposit_expandable.dart';

/// View of the `HomeTab.wallet` tab.
class WalletTabView extends StatelessWidget {
  const WalletTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('WalletTab'),
      init: WalletTabController(Get.find()),
      builder: (WalletTabController c) {
        final style = Theme.of(context).style;

        final transactions = Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: Obx(() {
            final bool enabled =
                router.routes.lastOrNull == Routes.walletTransactions;

            return MenuButton(
              title: 'btn_transactions'.l10n,
              onPressed: router.walletTransactions,
              leading: const SvgIcon(SvgIcons.menuTransactions),
              inverted: enabled,
              subtitle: 'label_wallet_history'.l10n,
              trailing: const Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 7, 0),
                child: UnreadCounter(1),
              ),
            );
          }),
        );

        return Scaffold(
          appBar: CustomAppBar(
            title: Row(
              children: [
                const SizedBox(width: 21),
                Flexible(
                  child: Text(
                    'label_wallet'.l10n,
                    textAlign: TextAlign.center,
                    style: style.fonts.large.regular.onBackground,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            actions: [
              Obx(() {
                return WidgetButton(
                  onPressed: router.walletTransactions,
                  child: Text(
                    'currency_amount'.l10nfmt({
                      'amount': c.balance.value.toDouble().withSpaces,
                    }),
                    style: style.fonts.big.regular.onBackground.copyWith(
                      color: style.colors.primary,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 16),
            ],
          ),
          body: Scrollbar(
            controller: c.scrollController,
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
              controller: c.scrollController,
              children: [
                if (context.isNarrow) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: LineDivider('btn_add_funds'.l10n),
                  ),
                  const SizedBox(height: 8),
                  ...DepositKind.values.map((e) {
                    return Obx(() {
                      final bool expanded = c.expanded.contains(e);

                      return DepositExpandable(
                        expanded: expanded,
                        onPressed: expanded
                            ? () => c.expanded.remove(e)
                            : () => c.expanded.add(e),
                        provider: e,
                        fields: c.fields.value,
                      );
                    });
                  }),
                ],
                if (context.isNarrow) ...[
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: LineDivider('label_wallet_history'.l10n),
                  ),
                  const SizedBox(height: 8),
                  transactions,
                ],

                if (!context.isNarrow)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1.5),
                    child: Obx(() {
                      final bool enabled =
                          router.routes.lastOrNull == Routes.deposit;

                      return MenuButton(
                        title: 'btn_add_funds'.l10n,
                        onPressed: router.deposit,
                        leading: const SvgIcon(SvgIcons.menuTopUp),
                        inverted: enabled,
                        subtitle: 'btn_add_funds_subtitle'.l10n,
                      );
                    }),
                  ),
                if (!context.isNarrow) transactions,
              ],
            ),
          ),
        );
      },
    );
  }
}
