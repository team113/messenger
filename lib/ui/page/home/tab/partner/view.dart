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
import 'package:get/get.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/balance_provider.dart';
import 'package:messenger/ui/page/home/widget/safe_scrollbar.dart';
import 'package:messenger/ui/page/home/widget/transaction.dart';
import 'package:messenger/ui/page/home/widget/vacancy.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:url_launcher/url_launcher.dart';

import 'controller.dart';

class PartnerTabView extends StatelessWidget {
  const PartnerTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: PartnerTabController(Get.find()),
      builder: (PartnerTabController c) {
        return Scaffold(
          // extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Text('Balance: \$${c.balance.value / 100}'),
            // leading: [
            //   Obx(() {
            //     final Widget child;

            //     if (c.withdrawing.value) {
            //       child = SvgImage.asset(
            //         'assets/icons/info.svg',
            //         width: 20,
            //         height: 20,
            //       );
            //     } else {
            //       child = SvgImage.asset(
            //         key: const Key('Search'),
            //         'assets/icons/search.svg',
            //         width: 17.77,
            //       );
            //     }

            //     return WidgetButton(
            //       onPressed: c.hintDismissed.toggle,
            //       child: Container(
            //         padding: const EdgeInsets.only(left: 20, right: 12),
            //         height: double.infinity,
            //         child: child,
            //       ),
            //     );
            //   }),
            // ],
            // actions: [
            //   Obx(() {
            //     final Widget child;

            //     if (c.withdrawing.value) {
            //       child = SvgImage.asset(
            //         key: const Key('CloseSearch'),
            //         'assets/icons/transactions.svg',
            //         width: 19,
            //         height: 19.42,
            //       );
            //     } else {
            //       child = Stack(
            //         alignment: Alignment.topRight,
            //         children: [
            //           Transform.translate(
            //             offset: const Offset(0, 0),
            //             child: SvgImage.asset(
            //               'assets/icons/partner16.svg',
            //               width: 36,
            //               height: 28,
            //             ),
            //           ),
            //           Transform.translate(
            //             offset: Offset(1, 2),
            //             child: Container(
            //               decoration: BoxDecoration(
            //                 shape: BoxShape.circle,
            //                 color: style.colors.dangerColor,
            //               ),
            //               width: 8,
            //               height: 8,
            //             ),
            //           ),
            //         ],

            //         // child: Icon(
            //         //   Icons.account_balance_wallet_outlined,
            //         //   color: style.colors.primary,
            //         // ),
            //         // child: SvgImage.asset(
            //         //   'assets/icons/transactions.svg',
            //         //   width: 19,
            //         //   height: 19.42,
            //         // ),
            //       );
            //     }

            //     return WidgetButton(
            //       onPressed: () async {
            //         await launchUrl(
            //           Uri.https('google.com', 'search', {'q': 'withdraw'}),
            //         );
            //       },
            //       child: Container(
            //         padding: const EdgeInsets.only(left: 12, right: 20),
            //         height: double.infinity,
            //         child: SizedBox(width: 24, child: Center(child: child)),
            //       ),
            //     );
            //   }),
            // ],
          ),
          body: Obx(() {
            if (c.withdrawing.value) {
              Widget button({required String title, required IconData icon}) {
                return BalanceProviderWidget(
                  title: title,
                  leading: [Icon(icon)],
                  onTap: () {},
                );
              }

              return SafeScrollbar(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    button(title: 'SWIFT', icon: Icons.account_balance),
                    button(title: 'SEPA', icon: Icons.account_balance),
                    button(title: 'PayPal', icon: Icons.paypal),
                  ],
                ),
              );
            }

            return SafeScrollbar(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  VacancyWidget(
                    'Вывести деньги',
                    trailing: [
                      Column(
                        children: [
                          SvgImage.asset(
                            'assets/icons/external_link_blue.svg',
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(height: 21),
                        ],
                      ),
                    ],
                    onPressed: () async {
                      await launchUrl(
                        Uri.https('google.com', 'search', {'q': 'withdraw'}),
                      );
                    },
                  ),
                  VacancyWidget(
                    'Транзакции',
                    subtitle: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Новых транзакций: ',
                              style: style.fonts.bodySmall
                                  ?.copyWith(color: style.colors.secondary),
                            ),
                            TextSpan(
                              text: '4',
                              style: style.fonts.bodySmall
                                  ?.copyWith(color: style.colors.dangerColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                    trailing: [
                      Column(
                        children: [
                          SvgImage.asset(
                            'assets/icons/external_link_blue.svg',
                            height: 16,
                            width: 16,
                          ),
                          const SizedBox(height: 21),
                        ],
                      ),
                    ],
                    onPressed: () async {
                      await launchUrl(
                        Uri.https(
                            'google.com', 'search', {'q': 'transactions'}),
                      );
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Center(child: Text('Работайте с нами')),
                  ),
                  ...[Vacancies.all.first].map((e) {
                    return Obx(() {
                      final bool selected = router.routes.firstWhereOrNull(
                              (m) => m == '${Routes.vacancy}/${e.id}') !=
                          null;

                      return VacancyWidget(
                        e.title,
                        selected: selected,
                        onPressed: () => router.vacancy(e.id),
                      );
                    });
                  }),
                ],
              ),
            );

            return SafeScrollbar(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  ...c.transactions.map((e) {
                    return TransactionWidget(e);
                  }).toList(),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
