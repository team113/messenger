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

import '/ui/widget/widget_button.dart';
import '/ui/page/home/widget/operation.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View of the [Routes.walletTransactions] page.
class WalletTransactionsView extends StatelessWidget {
  const WalletTransactionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: WalletTransactionsController(Get.find()),
      builder: (WalletTransactionsController c) {
        return Scaffold(
          appBar: CustomAppBar(
            leading: const [SizedBox(width: 4), StyledBackButton()],
            title: Text('label_your_transactions'.l10n),
            actions: [
              AnimatedButton(
                onPressed: () {
                  c.expanded.toggle();
                  c.ids.clear();
                },
                decorator: (child) => Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 0, 4),
                  child: Obx(() {
                    return SvgIcon(
                      c.expanded.value ? SvgIcons.viewFull : SvgIcons.viewShort,
                    );
                  }),
                ),
              ),
            ],
          ),
          body: Builder(
            builder: (_) {
              return Obx(() {
                final List<Widget> children = [
                  ...c.operations.values.map((e) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 400),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
                          child: WidgetButton(
                            onPressed: () {
                              if (c.ids.contains(e.id)) {
                                c.ids.remove(e.id);
                              } else {
                                c.ids.add(e.id);
                              }
                            },
                            child: Obx(() {
                              final bool expanded = c.expanded.value;

                              return OperationWidget(
                                e,
                                expanded:
                                    (expanded && !c.ids.contains(e.id)) ||
                                    (!expanded && c.ids.contains(e.id)),
                              );
                            }),
                          ),
                        ),
                      ),
                    );
                  }),
                ];

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        reverse: true,
                        children: [
                          const SizedBox(height: 8),
                          ...children,
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    _search(context, c),
                  ],
                );
              });
            },
          ),
        );
      },
    );
  }

  /// Returns the search field for transactions filtering.
  Widget _search(BuildContext context, WalletTransactionsController c) {
    final style = Theme.of(context).style;

    return Container(
      decoration: BoxDecoration(
        color: style.cardColor,
        boxShadow: [
          CustomBoxShadow(
            blurRadius: 8,
            color: style.colors.onBackgroundOpacity13,
          ),
        ],
      ),
      constraints: const BoxConstraints(minHeight: 57),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const SvgIcon(SvgIcons.search),
          Expanded(
            child: Theme(
              data: MessageFieldView.theme(context),
              child: ReactiveTextField(
                dense: true,
                state: c.search,
                hint: 'label_search_dots'.l10n,
                style: style.fonts.medium.regular.onBackground,
                onChanged: () {
                  c.query.value = c.search.text.isEmpty ? null : c.search.text;
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
