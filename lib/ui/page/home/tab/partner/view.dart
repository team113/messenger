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
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/tab/chats/widget/unread_counter.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/menu_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

/// View of the `HomeTab.partner` tab.
class PartnerTabView extends StatelessWidget {
  const PartnerTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('PartnerTab'),
      init: PartnerTabController(),
      builder: (PartnerTabController c) {
        final style = Theme.of(context).style;

        return Scaffold(
          appBar: CustomAppBar(
            title: Row(
              children: [
                const SizedBox(width: 21),
                Flexible(
                  child: Text(
                    'btn_monetization'.l10n,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: style.fonts.large.regular.onBackground,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            actions: [
              Obx(() {
                return WidgetButton(
                  onPressed: router.partnerTransactions,
                  child: Text(
                    'currency_amount'.l10nfmt({
                      'amount': (c.balance.value + c.hold.value)
                          .toDouble()
                          .withSpaces,
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
              controller: c.scrollController,
              padding: EdgeInsets.fromLTRB(0, 4, 0, 4),
              children: [
                SizedBox(height: 8),
                LineDivider('label_payouts_and_information'.l10n),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Obx(() {
                    final bool enabled =
                        router.routes.lastOrNull == Routes.withdraw;

                    return MenuButton(
                      title: 'label_order_payment'.l10n,
                      onPressed: router.withdraw,
                      leading: const SvgIcon(SvgIcons.menuOrderMoney),
                      inverted: enabled,
                      subtitle: 'label_available_balance_amount'.l10nfmt({
                        'amount': c.balance.value.toStringAsFixed(2),
                      }),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Obx(() {
                    final bool enabled =
                        router.routes.lastOrNull == Routes.partnerTransactions;

                    return MenuButton(
                      title: 'btn_transactions'.l10n,
                      onPressed: router.partnerTransactions,
                      leading: const SvgIcon(SvgIcons.menuTransactions),
                      inverted: enabled,
                      subtitle: 'label_monetization_history'.l10n,
                      trailing: const UnreadCounter(1),
                    );
                  }),
                ),
                SizedBox(height: 8),
                LineDivider('label_for_authors'.l10n),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Obx(() {
                    final bool enabled =
                        router.routes.lastOrNull == Routes.prices;
                    return MenuButton(
                      title: 'btn_set_your_prices'.l10n,
                      onPressed: router.prices,
                      leading: const SvgIcon(SvgIcons.menuMonetization),
                      inverted: enabled,
                      subtitle: 'btn_set_your_prices_subtitle'.l10n,
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Obx(() {
                    final bool enabled =
                        router.routes.lastOrNull == Routes.promotion;

                    return MenuButton(
                      title: 'btn_promote_yourself'.l10n,
                      onPressed: router.promotion,
                      leading: const SvgIcon(SvgIcons.menuAuthor),
                      inverted: enabled,
                      subtitle: 'btn_promote_yourself_subtitle'.l10n,
                    );
                  }),
                ),
                SizedBox(height: 8),
                LineDivider('label_for_promoters'.l10n),
                SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Obx(() {
                    final bool enabled =
                        router.routes.lastOrNull == Routes.affiliate;

                    return MenuButton(
                      title: 'btn_partner_programs'.l10n,
                      onPressed: router.affiliate,
                      leading: const SvgIcon(SvgIcons.menuPromoter),
                      inverted: enabled,
                      subtitle: 'btn_partner_programs_subtitle'.l10n,
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
