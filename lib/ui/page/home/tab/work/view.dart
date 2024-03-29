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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/ui/widget/svg/svg.dart';
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
      init: WorkTabController(Get.find()),
      builder: (WorkTabController c) {
        final style = Theme.of(context).style;

        return Scaffold(
          appBar: CustomAppBar(
            title: Row(
              children: [
                const SizedBox(width: 16),
                AnimatedButton(
                  enabled: false,
                  onPressed: () {},
                  decorator: (child) => Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
                    child: child,
                  ),
                  child: const SvgIcon(SvgIcons.partner),
                ),
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, snapshot) {
                      final double occupies =
                          'label_work_with_us'.l10n.length * 9.35;

                      if (occupies >= snapshot.maxWidth) {
                        return Text(
                          'label_work_with_us_two'.l10n,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: style.fonts.small.regular.onBackground,
                        );
                      }

                      return Text(
                        'label_work_with_us'.l10n,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // AnimatedButton(
                //   onPressed: () {},
                //   decorator: (child) => Padding(
                //     padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
                //     child: child,
                //   ),
                //   child: const SvgIcon(SvgIcons.transactions),
                // ),
              ],
            ),
            actions: [
              Obx(() {
                return WidgetButton(
                  onPressed: () {},
                  child: Text(
                    '¤ ${c.balance.value.toInt().withSpaces()}',
                    style: style.fonts.big.regular.onBackground.copyWith(
                      color: style.colors.primary,
                    ),
                  ),
                );
              }),
              const SizedBox(width: 16),
            ],
          ),
          // appBar: CustomAppBar(
          //   leading: [
          //     AnimatedButton(
          //       decorator: (child) => Container(
          //         margin: const EdgeInsets.only(left: 18),
          //         height: double.infinity,
          //         child: Center(child: child),
          //       ),
          //       onPressed: router.faq,
          //       child: Center(
          //         child: Icon(
          //           Icons.question_mark_rounded,
          //           color: style.colors.primary,
          //           size: 22,
          //         ),
          //       ),
          //     ),
          //   ],
          //   title: Text('label_work_with_us'.l10n),
          //   actions: [
          //     AnimatedButton(
          //       decorator: (child) => Container(
          //         padding: const EdgeInsets.only(right: 18),
          //         height: double.infinity,
          //         child: Center(child: child),
          //       ),
          //       onPressed: () {
          //         // No-op.
          //       },
          //       child: Icon(Icons.more_vert, color: style.colors.primary),
          //     ),
          //   ],
          // ),
          body: SafeScrollbar(
            controller: c.scrollController,
            child: ListView.builder(
              controller: c.scrollController,
              itemCount: WorkTab.values.length,
              itemBuilder: (_, i) {
                final WorkTab e = WorkTab.values[i];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: VacancyWorkButton(e),
                );
              },
            ),
          ),
          extendBodyBehindAppBar: true,
          extendBody: true,
        );
      },
    );
  }
}

extension on int {
  String withSpaces() {
    return NumberFormat('#,##0').format(this);
  }
}
