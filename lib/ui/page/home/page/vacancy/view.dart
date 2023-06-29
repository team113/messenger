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
import 'package:messenger/domain/model/attachment.dart';
import 'package:messenger/domain/model/file.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/model/vacancy.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/data_attachment.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/copyable.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
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
          body: Center(
            child: ListView(
              shrinkWrap: !context.isNarrow,
              children: [
                const SizedBox(height: 4),
                Block(
                  title: 'Details',
                  children: [
                    _padding(Text(e.description)),
                    const SizedBox(height: 4),
                  ],
                ),
                Block(
                  title: 'Actions',
                  children: [
                    _padding(
                      FieldButton(
                        text: 'Связаться',
                        style: TextStyle(color: style.colors.primary),
                        onPressed: c.contact,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);
}
