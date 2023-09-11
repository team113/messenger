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
import 'package:messenger/ui/page/home/widget/vacancy.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/page/work/widget/vacancy_button.dart';
import '/ui/widget/animated_button.dart';
import 'controller.dart';

/// View of the [HomeTab.work] tab.
class WorkTabView extends StatelessWidget {
  const WorkTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('MenuTab'),
      init: WorkTabController(),
      builder: (WorkTabController c) {
        final style = Theme.of(context).style;

        return Scaffold(
          appBar: CustomAppBar(
            leading: [
              AnimatedButton(
                decorator: (child) => Container(
                  margin: const EdgeInsets.only(left: 18),
                  height: double.infinity,
                  child: Center(child: child),
                ),
                onPressed: router.faq,
                child: Center(
                  child: Icon(
                    Icons.question_mark_rounded,
                    color: style.colors.primary,
                    size: 22,
                  ),
                ),
              ),
            ],
            title: Text('label_work_with_us'.l10n),
            actions: [
              AnimatedButton(
                decorator: (child) => Container(
                  padding: const EdgeInsets.only(right: 18),
                  height: double.infinity,
                  child: Center(child: child),
                ),
                onPressed: () {
                  // No-op.
                },
                child: Icon(Icons.more_vert, color: style.colors.primary),
              ),
            ],
          ),
          body: SafeScrollbar(
            controller: c.scrollController,
            child: ListView(
              controller: c.scrollController,
              children: [
                if (false)
                  VacancyWidget(
                    'Баланс: \$9999.99',
                    trailing: const [
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
                    subtitle: [
                      // const SizedBox(height: 4),
                      Text(
                        // '\$${c.balance.value / 100}',
                        'Вывести деньги',
                        style: style.fonts.bodySmallSecondary,
                      )
                    ],
                    onPressed: () async {
                      await launchUrl(
                        Uri.https('google.com', 'search', {'q': 'withdraw'}),
                      );
                    },
                  ),
                if (false)
                  VacancyWidget(
                    'Транзакции',
                    subtitle: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Новых транзакций: ',
                              style: style.fonts.bodySmall
                                  .copyWith(color: style.colors.secondary),
                            ),
                            TextSpan(
                              text: '4',
                              style: style.fonts.bodySmall
                                  .copyWith(color: style.colors.dangerColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                    trailing: const [
                      Column(
                        children: [
                          SvgImage.asset(
                            'assets/icons/external_link_blue.svg',
                            height: 16,
                            width: 16,
                          ),
                          SizedBox(height: 21),
                        ],
                      ),
                    ],
                    onPressed: () async {
                      await launchUrl(
                        Uri.https(
                          'google.com',
                          'search',
                          {'q': 'transactions'},
                        ),
                      );
                    },
                  ),
                if (false)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                    child: Center(child: Text('Работайте с нами')),
                  ),
                ...WorkTab.values.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: VacancyWorkButton(e),
                  );
                }),
              ],
            ),
          ),
          extendBodyBehindAppBar: true,
          extendBody: true,
        );
      },
    );
  }
}
