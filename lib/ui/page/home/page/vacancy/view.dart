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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/page/vacancy/body/view.dart';
import 'package:messenger/ui/page/vacancy/widget/vacancy_description.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

class VacancyView extends StatelessWidget {
  const VacancyView(this.id, {super.key});

  final String id;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      tag: id,
      init: VacancyController(id),
      builder: (VacancyController c) {
        if (c.vacancy.value == null) {
          return const Scaffold(
            appBar: CustomAppBar(leading: [StyledBackButton()]),
            body: Center(child: CustomProgressIndicator()),
          );
        }

        final Vacancy e = c.vacancy.value!;

        return Scaffold(
          appBar: CustomAppBar(
            title: Text(e.title),
            leading: const [StyledBackButton()],
          ),
          body: VacancyBodyView(e),
          // Center(
          //   child: ListView(
          //     shrinkWrap: !context.isNarrow,
          //     children: [
          //       const SizedBox(height: 4),
          //       ...e.blocks.map((e) {
          //         return Block(
          //           title: e.title,
          //           children: [
          //             VacancyDescription(e.description),
          //             // Paddings.dense(VacancyDescription(e.description)),
          //             const SizedBox(height: 4),
          //           ],
          //         );
          //       }),
          //       Block(
          //         title: 'Actions',
          //         children: [
          //           Paddings.basic(
          //             FieldButton(
          //               text: 'Связаться',
          //               style: TextStyle(color: style.colors.primary),
          //               onPressed: c.contact,
          //             ),
          //           ),
          //         ],
          //       ),
          //       const SizedBox(height: 4),
          //     ],
          //   ),
          // ),
        );
      },
    );
  }
}
