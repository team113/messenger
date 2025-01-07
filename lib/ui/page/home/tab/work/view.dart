// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/page/work/widget/vacancy_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// View of the `HomeTab.work` tab.
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
            title: Row(
              children: [
                const SizedBox(width: 21),
                Flexible(
                  child: LayoutBuilder(
                    builder: (context, snapshot) {
                      final double occupies =
                          'label_work_with_us'.l10n.length * 11;

                      if (occupies >= snapshot.maxWidth) {
                        return Text(
                          'label_work_with_us_desc'.l10n,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: style.fonts.medium.regular.onBackground
                              .copyWith(height: 1),
                        );
                      }

                      return Text(
                        'label_work_with_us'.l10n,
                        textAlign: TextAlign.left,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: style.fonts.large.regular.onBackground,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            actions: [
              AnimatedButton(
                onPressed: router.support,
                decorator: (child) => Padding(
                  padding: const EdgeInsets.fromLTRB(0, 4, 21, 4),
                  child: child,
                ),
                child: const SvgIcon(SvgIcons.info),
              )
            ],
          ),
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
